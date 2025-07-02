// GameEngine.swift
// ONE self-contained file: deterministic worker-ant loop + very light
// upgrade hooks.  No extra helpers, no protocols — keep it dumb & obvious.

import Foundation
import Combine
import CoreGraphics

// ─────────────────────────────────────────────────────────────
// PUBLIC READ MODEL (MatchView listens to this only)
// ─────────────────────────────────────────────────────────────
struct MatchSnapshot: Identifiable {
    let id = UUID()
    let ants: [WorkerAnt]        // positions in logical −1…1 space
    let foodP1, foodP2: Int
}

// ─────────────────────────────────────────────────────────────
// INTERNAL WRITE MODELS
// ─────────────────────────────────────────────────────────────
struct WorkerAnt: Identifiable, Equatable {
    enum Phase: Equatable { case outbound, gathering(TimeInterval), inbound }
    let id = UUID()
    var playerID: Int            // 1 or 2
    var speciesID: String        // "FIRE" / "LEAF"
    var pos: CGPoint
    var dir: CGVector            // unit vector
    var phase: Phase
}

struct ColonyUpgrades {          // one per player
    private(set) var level: [UpgradeID:Int] = [:]
    mutating func inc(_ id: UpgradeID) { level[id, default:0] += 1 }
    func lvl(_ id: UpgradeID) -> Int { level[id, default:0] }
}

final class MatchState {
    var ants: [WorkerAnt] = []
    var food = (p1: 0, p2: 0)
    var lastSpawn = (p1: 0.0, p2: 0.0)
    var upgrades = (p1: ColonyUpgrades(), p2: ColonyUpgrades())
}

// ─────────────────────────────────────────────────────────────
// ENGINE
// ─────────────────────────────────────────────────────────────
final class SimulationEngine: ObservableObject {
    @Published var state = MatchState()
    private let settings: MatchSettings      // passed from MatchView
    private var timer: AnyCancellable?
    let snapshotSubject = PassthroughSubject<MatchSnapshot,Never>()

    // MARK: init / start / stop
    init(settings: MatchSettings) { self.settings = settings }

    func start() {
        guard timer == nil else { return }
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] t in
                self?.tick(dt: 1/60, now: t.timeIntervalSinceReferenceDate)
            }
    }
    func stop()  { timer?.cancel(); timer = nil }

    // MARK: main loop
    private func tick(dt: TimeInterval, now: TimeInterval) {
        spawnIfNeeded(player: 1, now: now)
        spawnIfNeeded(player: 2, now: now)

        for i in state.ants.indices { advance(&state.ants[i], dt: dt) }

        // deliver food + cull returned ants
        state.ants.removeAll { ant in
            let arrived = ant.phase == .inbound
                       && abs(ant.pos.x) < 0.03
                       && abs(ant.pos.y) < 0.03
            if arrived {
                ant.playerID == 1 ? (state.food.p1 += 1) : (state.food.p2 += 1)
            }
            return arrived
        }

        snapshotSubject.send(.init(ants: state.ants,
                                   foodP1: state.food.p1,
                                   foodP2: state.food.p2))
    }

    // MARK: spawning
    private func spawnIfNeeded(player: Int, now: Double) {
        let sel = settings.speciesSelections[player-1]
        guard let bal = BalanceTable.workers.first(where: { $0.speciesID == sel.species.id }) else { return }

        // passive infirmary upgrade: each level multiplies spawnRate by 0.9
        let level = (player==1 ? state.upgrades.p1 : state.upgrades.p2).lvl(.infirmary)
        let effSpawn = bal.spawnRate * pow(0.9, Double(level))

        let last = player == 1 ? state.lastSpawn.p1 : state.lastSpawn.p2
        guard now - last >= effSpawn else { return }

        state.ants.append(
            WorkerAnt(playerID: player,
                      speciesID: sel.species.id,
                      pos: .zero,
                      dir: randUnit(),
                      phase: .outbound)
        )
        player == 1 ? (state.lastSpawn.p1 = now) : (state.lastSpawn.p2 = now)
    }

    // MARK: movement + gather/death
    private func advance(_ a: inout WorkerAnt, dt: TimeInterval) {
        let speed: CGFloat = 0.25
        switch a.phase {

        case .outbound:
            a.pos.x += a.dir.dx * speed * dt
            a.pos.y += a.dir.dy * speed * dt
            if abs(a.pos.x) > 1 || abs(a.pos.y) > 1 {
                // deathRoll before gathering
                let bal = BalanceTable.workers.first { $0.speciesID == a.speciesID }!
                if Double.random(in: 0...1) < bal.deathRate {
                    a.phase = .inbound ; a.pos = CGPoint(x: 999, y: 999) // disappear
                } else {
                    // pheromone upgrade shortens gather
                    let lvl = (a.playerID==1 ? state.upgrades.p1 : state.upgrades.p2)
                                .lvl(.pheromone)
                    let g = bal.gatherRate * pow(0.9, Double(lvl))
                    a.phase = .gathering(g)
                }
            }

        case .gathering(let t):
            a.phase = (t-dt <= 0) ? .inbound : .gathering(t-dt)
            if case .inbound = a.phase { a.dir = CGVector(dx:-a.dir.dx, dy:-a.dir.dy) }

        case .inbound:
            a.pos.x += a.dir.dx * speed * dt
            a.pos.y += a.dir.dy * speed * dt
        }
    }

    // MARK: util
    private func randUnit() -> CGVector {
        let a = Double.random(in: 0 ..< 2*Double.pi)
        return CGVector(dx: cos(a), dy: sin(a))
    }
}

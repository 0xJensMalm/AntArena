// GameEngine.swift – deterministic loop with prototype workers
// ------------------------------------------------------------

import Foundation
import Combine
import CoreGraphics

// MARK: public read-model ------------------------------------

struct MatchSnapshot: Identifiable {
    let id = UUID()
    let ants: [WorkerAnt]
    let foodP1, foodP2: Int
}

// MARK: internal models --------------------------------------

struct WorkerAnt: Identifiable, Equatable {
    enum Phase: Equatable { case outbound, gathering(TimeInterval), inbound }
    let id = UUID()
    var playerID: Int              // 1 | 2
    var speciesID: String          // "FIRE" / "LEAF"
    var pos: CGPoint               // logical coords (−1…1)
    var dir: CGVector              // unit vector
    var phase: Phase
}

final class MatchState {
    var ants: [WorkerAnt] = []
    var food = (p1: 0, p2: 0)
    var lastSpawn = (p1: 0.0, p2: 0.0)
}

// MARK: engine ------------------------------------------------

final class SimulationEngine: ObservableObject {

    private(set) var state = MatchState()
    private let settings: MatchSettings
    private var timer: AnyCancellable?
    let snapshotSubject = PassthroughSubject<MatchSnapshot,Never>()

    init(settings: MatchSettings) { self.settings = settings }

    func start() {
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] t in
                self?.tick(dt: 1/60, now: t.timeIntervalSinceReferenceDate)
            }
    }
    func stop() { timer?.cancel() }

    // MARK: tick
    private func tick(dt: TimeInterval, now: TimeInterval) {
        spawnIfNeeded(player: 1, now: now)
        spawnIfNeeded(player: 2, now: now)

        for i in state.ants.indices { advance(&state.ants[i], dt: dt) }

        state.ants.removeAll { ant in
            let delivered = ant.phase == .inbound && abs(ant.pos.x) < 0.03 && abs(ant.pos.y) < 0.03
            if delivered {
                ant.playerID == 1 ? (state.food.p1 += 1) : (state.food.p2 += 1)
            }
            return delivered
        }

        snapshotSubject.send(.init(ants: state.ants,
                                   foodP1: state.food.p1,
                                   foodP2: state.food.p2))
    }

    // MARK: spawning
    private func spawnIfNeeded(player: Int, now: Double) {
        let sel = settings.speciesSelections[player-1]
        guard let bal = BalanceTable.workers.first(where: { $0.speciesID == sel.species.id }) else { return }
        let last = player == 1 ? state.lastSpawn.p1 : state.lastSpawn.p2
        guard now - last >= bal.spawnRate else { return }

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
        let v: CGFloat = 0.25
        switch a.phase {

        case .outbound:
            a.pos.x += a.dir.dx * v * dt
            a.pos.y += a.dir.dy * v * dt
            if abs(a.pos.x) > 1 || abs(a.pos.y) > 1 {
                let bal = BalanceTable.workers.first { $0.speciesID == a.speciesID }!
                if Double.random(in: 0...1) < bal.deathRate {
                    a.phase = .inbound ; a.pos = CGPoint(x: 999, y: 999) // die off-screen
                } else {
                    a.phase = .gathering(bal.gatherRate)
                }
            }

        case .gathering(let t):
            a.phase = (t - dt <= 0) ? .inbound : .gathering(t - dt)
            if case .inbound = a.phase { a.dir = CGVector(dx: -a.dir.dx, dy: -a.dir.dy) }

        case .inbound:
            a.pos.x += a.dir.dx * v * dt
            a.pos.y += a.dir.dy * v * dt
        }
    }

    // helpers
    private func randUnit() -> CGVector {
        let a = Double.random(in: 0..<2*Double.pi)
        return CGVector(dx: cos(a), dy: sin(a))
    }
}

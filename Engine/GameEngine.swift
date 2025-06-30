// GameEngine.swift – deterministic loop + worker prototype
// --------------------------------------------------------

import Foundation
import Combine
import CoreGraphics
import CoreFoundation

// MARK: public read-model ----------------------------------

struct MatchSnapshot: Identifiable {
    let id = UUID()
    let ants: [WorkerAnt]
    let foodP1, foodP2: Int
}

// MARK: internal models ------------------------------------

struct WorkerAnt: Identifiable, Equatable {
    enum Phase: Equatable { case outbound, gathering(TimeInterval), inbound }
    let id = UUID()
    var playerID: Int          // 1 | 2
    var speciesID: String      // "FIRE" | "LEAF"
    var position: CGPoint      // logical (–1…1)
    var dir: CGVector          // unit
    var phase: Phase
}

final class MatchState {
    var ants: [WorkerAnt] = []
    var food = (p1: 0, p2: 0)
    var lastSpawn = (p1: 0.0, p2: 0.0)
}

// MARK: engine ---------------------------------------------

final class SimulationEngine: ObservableObject {

    private(set) var state = MatchState()
    private let settings: MatchSettings
    private var timer: AnyCancellable?
    let snapshotSubject = PassthroughSubject<MatchSnapshot,Never>()

    init(settings: MatchSettings) { self.settings = settings }

    // lifecycle
    func start() {
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tick(dt: 1/60, now: now.timeIntervalSinceReferenceDate)
            }
    }
    func stop() { timer?.cancel() }

    // tick
    private func tick(dt: TimeInterval, now: TimeInterval) {

        spawnIfNeeded(player: 1, now: now)
        spawnIfNeeded(player: 2, now: now)

        for i in state.ants.indices { step(&state.ants[i], dt: dt) }

        state.ants.removeAll { ant in
            let reached = (ant.phase == .inbound) && reachedColony(ant)
            if reached {
                if ant.playerID == 1 { state.food.p1 += 1 }
                else                 { state.food.p2 += 1 }
            }
            return reached
        }

        snapshotSubject.send(
            MatchSnapshot(ants: state.ants,
                          foodP1: state.food.p1,
                          foodP2: state.food.p2)
        )
    }

    // spawning
    private func spawnIfNeeded(player: Int, now: Double) {
        let sel = settings.speciesSelections[player-1]
        guard let bal = BalanceTable.workers.first(where: {$0.speciesID==sel.species.id}) else { return }
        let last = (player==1) ? state.lastSpawn.p1 : state.lastSpawn.p2
        guard now-last >= bal.spawnRate else { return }

        let dir = randUnit()
        state.ants.append(
            WorkerAnt(playerID: player,
                      speciesID: sel.species.id,
                      position: .zero,
                      dir: dir,
                      phase: .outbound)
        )
        if player==1 { state.lastSpawn.p1 = now } else { state.lastSpawn.p2 = now }
    }

    // movement + gather / death
    private func step(_ ant: inout WorkerAnt, dt: TimeInterval) {
        let speed: CGFloat = 0.25
        switch ant.phase {

        case .outbound:
            ant.position.x += ant.dir.dx*speed*dt
            ant.position.y += ant.dir.dy*speed*dt
            if abs(ant.position.x)>1 || abs(ant.position.y)>1 {
                // decide death
                let bal = BalanceTable.workers.first{$0.speciesID==ant.speciesID}!
                if Double.random(in: 0...1) < bal.deathRate {
                    ant.phase = .inbound        // mark for removal on next pass
                    ant.position = CGPoint(x: 999,y:999) // put off-screen
                } else {
                    ant.phase = .gathering(bal.gatherRate)
                }
            }

        case .gathering(let t):
            ant.phase = (t-dt<=0) ? .inbound : .gathering(t-dt)
            if case .inbound = ant.phase {
                ant.dir.dx *= -1 ; ant.dir.dy *= -1
            }

        case .inbound:
            ant.position.x += ant.dir.dx*speed*dt
            ant.position.y += ant.dir.dy*speed*dt
        }
    }

    // helpers
    private func reachedColony(_ a: WorkerAnt) -> Bool {
        abs(a.position.x) < 0.03 && abs(a.position.y) < 0.03
    }
    private func randUnit() -> CGVector {
        let a = Double.random(in: 0..<2*Double.pi)
        return CGVector(dx: cos(a), dy: sin(a))
    }
}

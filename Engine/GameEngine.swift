// GameEngine.swift
// Deterministic simulation loop (no UIKit / SwiftUI).

import Foundation
import Combine

// MARK: - Snapshot & State
struct MatchSnapshot: Identifiable {
    let id = UUID()
    // TODO: add ant positions, food totals, colony HP, etc.
}

final class MatchState {
    // TODO: ants, colonies, timers, upgrades, RNG seed …
}

// MARK: - Engine
final class SimulationEngine: ObservableObject {
    private(set) var state = MatchState()

    private var timer: AnyCancellable?
    let snapshotSubject = PassthroughSubject<MatchSnapshot, Never>()

    func start() {
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(dt: 1.0 / 30.0)
            }
    }

    func stop() { timer?.cancel() }

    private func tick(dt: Double) {
        // TODO: advance ants, spawn food, resolve combat.
        snapshotSubject.send(MatchSnapshot())   // placeholder frame
    }
}

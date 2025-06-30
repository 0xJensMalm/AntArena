// AntBalance.swift
// Tweak worker behaviour per species in one place.

import Foundation

struct AntBalance: Decodable {
    let speciesID: String            // "FIRE", "LEAF", …
    var spawnRate:  TimeInterval     // sec between workers
    var gatherRate: TimeInterval     // sec spent off-screen
    var deathRate:  Double           // 0.0…1.0 chance to die while gathering
}

enum BalanceTable {
    /// Order should mirror `GameConstants.species`
    static var workers: [AntBalance] = [
        .init(speciesID: "FIRE", spawnRate: 1.2, gatherRate: 2.0, deathRate: 0.20),
        .init(speciesID: "LEAF", spawnRate: 1.5, gatherRate: 1.6, deathRate: 0.20)
    ]
}

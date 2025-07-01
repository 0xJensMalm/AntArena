// AntBalance.swift  – tweakable worker parameters
import Foundation

struct AntBalance: Decodable {
    let speciesID: String            // "FIRE", "LEAF", …
    var spawnRate:  TimeInterval     // sec between workers
    var gatherRate: TimeInterval     // sec off-screen
    var deathRate:  Double           // chance to die while gathering
}

enum BalanceTable {
    static var workers: [AntBalance] = [
        .init(speciesID: "FIRE", spawnRate: 1.2, gatherRate: 2.0, deathRate: 0.20),
        .init(speciesID: "LEAF", spawnRate: 1.5, gatherRate: 1.6, deathRate: 0.20)
    ]
}

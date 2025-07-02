// AntBalance.swift
// Central place for *all* balance knobs: workers + upgrades
import Foundation

// ── Worker tuning ───────────────────────────────────────────
struct AntBalance: Decodable {
    let speciesID: String
    var spawnRate : TimeInterval     // seconds between workers  (base)
    var gatherRate: TimeInterval     // seconds off-screen       (base)
    var deathRate : Double           // 0…1 chance to die
}

enum BalanceTable {
    static var workers: [AntBalance] = [
        .init(speciesID: "FIRE", spawnRate: 1.2, gatherRate: 2.0, deathRate: 0.20),
        .init(speciesID: "LEAF", spawnRate: 1.5, gatherRate: 1.6, deathRate: 0.20)
    ]
}

// ── Upgrade catalogue (edit numbers here) ───────────────────
enum UpgradeID: String, Codable { case infirmary, pheromone, hatchery }

// AntBalance.swift   ← replace the whole UpgradeMeta definition
struct UpgradeMeta: Identifiable, Codable {
    let id: UpgradeID
    let title:   String
    let blurb:   String
    let icon:    String           // SF Symbol or asset name
    let maxLevel:Int
    let costs:   [Int]            // one entry per level
    let effect:  UpgradeEffect
    let rowOrder:Int              // for sorting in UI

    var isActive: Bool { effect.isActive }
}

enum UpgradeEffect: Codable {
    case spawn(mult: Double)            // passive
    case gather(mult: Double)           // passive
    case unlockWarrior                  // active
    
    var isActive: Bool {
        if case .unlockWarrior = self { return true }
        return false
    }
}

let UpgradeCatalog: [UpgradeMeta] = [
    .init(id: .infirmary,
          title: "Infirmary",
          blurb: "Accelerates larval recovery time.",
          icon: "cross.case.fill",
          maxLevel: 3,
          costs: [10,20,40],
          effect: .spawn(mult: 0.9),
          rowOrder: 0),
    .init(id: .pheromone,
          title: "Pheromone Trail",
          blurb: "Enhances forager orientation speed.",
          icon: "wind",
          maxLevel: 3,
          costs: [15,30,60],
          effect: .gather(mult: 0.9),
          rowOrder: 1),
    .init(id: .hatchery,
          title: "Warrior Hatchery",
          blurb: "Breeds offensive castes.",
          icon: "shield.lefthalf.fill",
          maxLevel: 1,
          costs: [50],
          effect: .unlockWarrior,
          rowOrder: 0)
]

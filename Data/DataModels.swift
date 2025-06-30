// DataModels.swift
// Pure value types and static constants.  No UI or Combine.

import Foundation

// MARK: - Meta & Balance Tables
struct SpeciesMeta: Identifiable, Decodable {
    let id: String
    let name: String
    let portraitName: String    // SFSymbol or asset name
    let tagline: String
    let buffs: [String]         // Human-readable positives
    let debuffs: [String]       // Human-readable negatives
}

struct GameConstants {
    static let species: [SpeciesMeta] = [
        .init(id: "FIRE",
              name: "Fire Ant",
              portraitName: "FireAntImage",        // <- your asset name here
              tagline: "Known for their synchronized assaults, injecting alkaloid venom with rapid-fire stings. Open-soil mounds heated by the sun fuel explosive colony growth and territory defense.",
              buffs: ["+15 % attack"],
              debuffs: ["-10 % gather"]),

        .init(id: "LEAF",
              name: "Leafcutter",
              portraitName: "LeafCutterImage",     // <- asset name
              tagline: "Vibrating serrated mandibles shear foliage for relay along pheromone highways. The harvest sustains a subterranean farm of Leucoagaricus fungus that feeds the entire colony.",
              buffs: ["+20 % food"],
              debuffs: ["-10 % HP"]),

        // Add placeholders or real data for the other four slots
        .init(id: "BULL",
              name: "Bulldog",
              portraitName: "shield.lefthalf.fill",
              tagline: "Tanky terrors.",
              buffs: ["+25 % HP"],
              debuffs: ["-8 % speed"]),

        .init(id: "PHAR",
              name: "Pharaoh",
              portraitName: "bolt.fill",
              tagline: "Lightning-fast scouts.",
              buffs: ["+12 % speed"],
              debuffs: ["-10 % colony HP"]),

        .init(id: "SPEC5",
              name: "???",
              portraitName: "ant.fill",
              tagline: "Coming soon.",
              buffs: [],
              debuffs: []),

        .init(id: "SPEC6",
              name: "???",
              portraitName: "hare.fill",
              tagline: "Coming soon.",
              buffs: [],
              debuffs: [])
    ]
}

// MARK: - Cross-layer DTOs
struct SpeciesSelection {
    let playerId: Int           // 1 or 2
    let species: SpeciesMeta
}

struct MatchSettings {
    let speciesSelections: [SpeciesSelection]
}

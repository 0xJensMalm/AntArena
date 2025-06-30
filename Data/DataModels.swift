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

/// Designer-facing tables (hard-coded for MVP – swap to JSON later).
struct GameConstants {
    static let species: [SpeciesMeta] = [
        .init(id: "FIRE",
              name: "Fire Ant",
              portraitName: "flame.fill",
              tagline: "Born to burn.",
              buffs:   ["+15 % attack"],
              debuffs: ["-10 % gather"]),
        .init(id: "LEAF",
              name: "Leafcutter",
              portraitName: "leaf.fill",
              tagline: "Nature’s farmers.",
              buffs:   ["+20 % food"],
              debuffs: ["-10 % HP"])
        // TODO: Bulldog, Pharaoh, etc.
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

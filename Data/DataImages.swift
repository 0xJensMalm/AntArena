// DataImages.swift
// Single source of truth for all image / texture names.

import Foundation

enum ImageAssets {
    // 6 icons mapped 1-to-1 with the 6 grid spots in AntSelectView.
    static let antSpeciesIcons: [String] = [
        "flame.fill",        // Fire Ant
        "leaf.fill",         // Leafcutter
        "shield.lefthalf.fill", // Bulldog (placeholder)
        "bolt.fill",         // Pharaoh (placeholder)
        "ant.fill",          // Species #5 placeholder
        "hare.fill"          // Species #6 placeholder
    ]

    /// Name of the background texture used in MatchView.
    /// Provide an image called **“MapTexture”** in the asset catalog.
    static let mapTexture = "MapTexture"
}

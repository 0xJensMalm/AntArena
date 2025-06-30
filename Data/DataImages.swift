// DataImages.swift
// Centralized names for all image and icon assets.

enum ImageAssets {
    /// 6 icons for grid selection (small thumbnails).
    /// Use SF Symbols as fallback placeholders.
    static let antGridIcons: [String] = [
        "flame.fill",           // Fire Ant placeholder icon
        "leaf.fill",            // Leafcutter placeholder icon
        "shield.lefthalf.fill", // SF Symbol fallback
        "bolt.fill",            // SF Symbol fallback
        "ant.fill",             // placeholder
        "hare.fill"             // placeholder
    ]

    /// 6 portraits for info cards (larger visuals).
    /// Same order as `GameConstants.species`
    static let antPortraits: [String] = [
        "FireAntImage",
        "LeafCutterImage",
        "BulldogImage",
        "PharaohImage",
        "ant.fill",         // placeholder
        "hare.fill"         // placeholder
    ]

    /// Background image for MatchView arena.
    static let mapTexture = "MapTexture"
}

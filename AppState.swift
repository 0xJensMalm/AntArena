// AppState.swift
import SwiftUI                       // needs Combine only if you add more later

/// The single global ObservableObject that drives top-level navigation.
final class AppState: ObservableObject {

    enum Screen {
        case speciesSelect           // shown on launch
        case match(settings: MatchSettings)
    }

    @Published var screen: Screen = .speciesSelect
}

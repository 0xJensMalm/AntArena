// ContentView.swift
import SwiftUI

/// One-stop entry for the whole flow (species-select → match → back).
struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {                               // light wrapper so we can attach the env-obj
            switch appState.screen {
            case .speciesSelect:
                AntSelectView()               // first screen
            case .match(let settings):
                MatchView(settings: settings) // split-screen match
            }
        }
        .environmentObject(appState)          // inject global state downward
    }
}

#Preview {
    ContentView()                             // SwiftUI canvas preview
}

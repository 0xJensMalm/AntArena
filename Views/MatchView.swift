// MatchView.swift
import SwiftUI
import Combine

struct MatchView: View {
    let settings: MatchSettings
    @EnvironmentObject private var appState: AppState

    // ONE shared engine
    @StateObject private var engine = SimulationEngine()
    @StateObject private var vm: MatchViewModel

    // upgrade-sheet toggles
    @State private var showUpgradeP1 = false
    @State private var showUpgradeP2 = false

    init(settings: MatchSettings) {
        self.settings = settings
        let sharedEngine = SimulationEngine()
        _engine = StateObject(wrappedValue: sharedEngine)
        _vm     = StateObject(wrappedValue: MatchViewModel(engine: sharedEngine))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                arenaBackground.ignoresSafeArea()

                // Split arenas
                VStack(spacing: 0) {

                    // Opponent (top) – rotated so they see upright
                    HalfArenaView(
                        isTopHalf: true,
                        colonyColor: .brown,
                        showSheet: $showUpgradeP2)
                        .rotationEffect(.degrees(180))
                        .frame(height: geo.size.height / 2)

                    Divider()

                    // Local player (bottom)
                    HalfArenaView(
                        isTopHalf: false,
                        colonyColor: .black,
                        showSheet: $showUpgradeP1)
                        .frame(height: geo.size.height / 2)
                }

                // Centred Exit
                Button("Exit") {
                    engine.stop()
                    appState.screen = .speciesSelect
                }
                .buttonStyle(.borderedProminent)
            }
            // half-height sheets
            .sheet(isPresented: $showUpgradeP1) {
                UpgradeSheet(title: "Player 1 Upgrades")
                    .presentationDetents([.fraction(0.5)])
            }
            .sheet(isPresented: $showUpgradeP2) {
                UpgradeSheet(title: "Player 2 Upgrades")
                    .presentationDetents([.fraction(0.5)])
            }
            .onAppear { engine.start() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: background helper
    private var arenaBackground: some View {
        Group {
            if UIImage(named: ImageAssets.mapTexture) != nil {
                Image(ImageAssets.mapTexture)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.brown
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Half-arena (one player’s viewport)
// ──────────────────────────────────────────────────────────────────────────
private struct HalfArenaView: View {
    let isTopHalf: Bool            // still needed only for rotation parent
    let colonyColor: Color
    @Binding var showSheet: Bool

    var body: some View {
        ZStack {
            // colony block in the middle
            Rectangle()
                .fill(colonyColor)
                .frame(width: 80, height: 80)
                .onTapGesture { showSheet = true }

            // HUD glued to the player edge
            VStack {
                Spacer()            // push HUD to container bottom
                HUDStrip()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}
// ──────────────────────────────────────────────────────────────────────────
// HUD  (placeholder numbers)
// ──────────────────────────────────────────────────────────────────────────
private struct HUDStrip: View {
    var body: some View {
        HStack(spacing: 16) {
            Label("Food 0", systemImage: "takeoutbag.and.cup.and.straw")
            Label("Ants 0", systemImage: "ant.fill")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Simple upgrade sheet placeholder
// ──────────────────────────────────────────────────────────────────────────
private struct UpgradeSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(title).font(.title2.bold())
            Text("Upgrade menu coming soon…")
            Button("Close") { dismiss() }
        }
        .padding()
    }
}

// ──────────────────────────────────────────────────────────────────────────
// ViewModel (unchanged stub)
// ──────────────────────────────────────────────────────────────────────────
final class MatchViewModel: ObservableObject {
    @Published private(set) var snapshot = MatchSnapshot()

    private let engine: SimulationEngine
    private var bag = Set<AnyCancellable>()

    init(engine: SimulationEngine) {
        self.engine = engine
        engine.snapshotSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$snapshot)
    }

    func start() { engine.start() }
    func stop()  { engine.stop()  }
}

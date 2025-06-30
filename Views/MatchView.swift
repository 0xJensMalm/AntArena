import SwiftUI
import Combine

// ──────────────────────────────────────────────────────────────────────────
// MATCH VIEW  – full-screen background, edge-anchored HUDs, mirrored panels
// ──────────────────────────────────────────────────────────────────────────
struct MatchView: View {
    let settings: MatchSettings
    @EnvironmentObject private var appState: AppState

    // shared engine
    @StateObject private var engine = SimulationEngine()
    @StateObject private var vm: MatchViewModel

    // panel flags
    @State private var showTopPanel    = false   // Player-2
    @State private var showBottomSheet = false   // Player-1

    init(settings: MatchSettings) {
        self.settings = settings
        let shared = SimulationEngine()
        _engine = StateObject(wrappedValue: shared)
        _vm     = StateObject(wrappedValue: MatchViewModel(engine: shared))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Split arenas ───────────────────────────────────────
                VStack(spacing: 0) {
                    HalfArena(isTop: true,
                              colonyColor: .brown,
                              showPanel: $showTopPanel)
                        .rotationEffect(.degrees(180))
                        .frame(height: geo.size.height / 2)

                    Divider()

                    HalfArena(isTop: false,
                              colonyColor: .black,
                              showPanel: $showBottomSheet)
                        .frame(height: geo.size.height / 2)
                }

                // Exit
                Button("Exit") {
                    // close any open panels first
                    showTopPanel = false
                    showBottomSheet = false
                    engine.stop()
                    appState.screen = .speciesSelect
                }
                .buttonStyle(.borderedProminent)

                // Top slide-down panel
                overlayTopPanel
            }
            // Bottom player native sheet
            .sheet(isPresented: $showBottomSheet) {
                BottomSheet { showBottomSheet = false }
                    .presentationDetents([.fraction(0.5)])
            }
        }
        .background(fullBackground)   // fills every pixel
        .ignoresSafeArea()
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    // MARK: Background
    private var fullBackground: some View {
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

    // MARK: Overlay builder
    @ViewBuilder private var overlayTopPanel: some View {
        GeometryReader { g in
            if showTopPanel {
                TopPanel(height: g.size.height * 0.5) {
                    withAnimation { showTopPanel = false }
                }
                .transition(.move(edge: .top))
                .zIndex(10)
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────
// HALF-ARENA  – colony block + HUD
// ──────────────────────────────────────────────────────────────────────────
private struct HalfArena: View {
    let isTop: Bool
    let colonyColor: Color
    @Binding var showPanel: Bool

    var body: some View {
        ZStack {
            // colony
            Rectangle()
                .fill(colonyColor)
                .frame(width: 80, height: 80)
                .onTapGesture { withAnimation { showPanel = true } }

            // HUD anchored bottom pre-rotation
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HUDStrip()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────
// HUD Strip – rotates 180º to cancel parent rotation (upright text)
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
        .rotationEffect(.degrees(180))
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Bottom sheet (Player-1) – slides up
// ──────────────────────────────────────────────────────────────────────────
private struct BottomSheet: View {
    var close: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("Player 1 Upgrades").font(.title2.bold())
            Text("Upgrade menu coming soon…")
            Button("Close", action: close)
        }
        .padding()
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Top panel (Player-2) – slides down, stops at 50 % height
// ──────────────────────────────────────────────────────────────────────────
private struct TopPanel: View {
    let height: CGFloat
    var close: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Player 2 Upgrades").font(.title2.bold())
            Text("Upgrade menu coming soon…")
            Button("Close", action: close)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)            // exactly half the screen
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 6)
        .rotationEffect(.degrees(180))     // upright for opponent
    }
}

// ──────────────────────────────────────────────────────────────────────────
// VIEW MODEL stub
// ──────────────────────────────────────────────────────────────────────────
final class MatchViewModel: ObservableObject {
    @Published private(set) var snapshot = MatchSnapshot()
    private let engine: SimulationEngine
    init(engine: SimulationEngine) { self.engine = engine }
    func start() { engine.start() }
    func stop()  { engine.stop() }
}

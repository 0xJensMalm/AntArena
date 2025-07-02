import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────
// MATCH VIEW – ants, live counters, centred HUD + Pause / Exit
// ─────────────────────────────────────────────────────────────
struct MatchView: View {
    let settings: MatchSettings
    @EnvironmentObject private var appState: AppState

    @StateObject private var engine: SimulationEngine
    @StateObject private var vm:       MatchViewModel

    @State private var showTopSheet    = false
    @State private var showBottomSheet = false
    @State private var isPaused        = false

    private let hudWidth: CGFloat = 170   // shared width for HUD & action bar

    init(settings: MatchSettings) {
        self.settings = settings
        let eng = SimulationEngine(settings: settings)
        _engine = StateObject(wrappedValue: eng)
        _vm     = StateObject(wrappedValue: MatchViewModel(engine: eng))
    }

    // ---------------------------------------------------------------------
    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ① Ant dots ----------------------------------------------
                Canvas { ctx, size in
                    for ant in vm.snapshot.ants {
                        let col: Color = (ant.speciesID == "FIRE") ? .red : .black
                        draw(ant, in: size, ctx: &ctx, color: col)
                    }
                }
                .ignoresSafeArea()

                // ② Split arenas -----------------------------------------
                VStack(spacing: 0) {
                    HalfArena(isTop: true,
                              colonyColor: .brown,
                              showPanel: $showTopSheet)
                        .rotationEffect(.degrees(180))
                        .frame(height: geo.size.height / 2)

                    Divider()

                    HalfArena(isTop: false,
                              colonyColor: .black,
                              showPanel: $showBottomSheet)
                        .frame(height: geo.size.height / 2)
                }

                // ③ HUD + Pause / Exit -----------------------------------
                VStack(spacing: 6) {
                    HUDStrip(food: vm.snapshot.foodP2,
                             ants: vm.topAnts,
                             width: hudWidth)
                        .rotationEffect(.degrees(180))

                    HStack(spacing: 0) {
                        Button(isPaused ? "Resume" : "Pause") {
                            isPaused ? engine.start() : engine.stop()
                            isPaused.toggle()
                        }
                        .frame(maxWidth: .infinity)

                        Button("Exit") {
                            showTopSheet = false
                            showBottomSheet = false
                            engine.stop()
                            appState.screen = .speciesSelect
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                    .frame(width: hudWidth)
                    .background(.thinMaterial)
                    .clipShape(Capsule())

                    HUDStrip(food: vm.snapshot.foodP1,
                             ants: vm.bottomAnts,
                             width: hudWidth)
                }

                // ④ Player-2 upgrade panel (top) is now handled as a sheet
            }

            // ⑤ Player sheets (both top and bottom) -------------------------
            .sheet(isPresented: $showBottomSheet) {
                BottomSheet(
                    upgrades: $engine.state.upgrades.p1,
                    food: Binding(
                        get: { engine.state.food.p1 },
                        set: { engine.state.food.p1 = $0 }),
                    close: { showBottomSheet = false }
                )
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
            }
            
            // ④ Player-2 upgrade panel (top) -------------------------
            .overlay(alignment: .top) {
                if showTopSheet {
                    TopPanel(
                        upgrades: $engine.state.upgrades.p2,
                        food: Binding(
                            get: { engine.state.food.p2 },
                            set: { engine.state.food.p2 = $0 }),
                        close: { withAnimation { showTopSheet = false } }
                    )
                    .transition(.move(edge: .top))
                    .zIndex(10)
                }
            }
        }
        .background(background).ignoresSafeArea()
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    // MARK: helper: draw one ant
    private func draw(_ ant: WorkerAnt,
                      in size: CGSize,
                      ctx: inout GraphicsContext,
                      color: Color)
    {
        let halfW  = size.width  / 2
        let halfH  = size.height / 2
        let centreY = ant.playerID == 1 ? halfH * 1.5 : halfH * 0.5
        let x = halfW + CGFloat(ant.pos.x) * halfW
        let y = centreY + CGFloat(ant.pos.y) * halfH
        ctx.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                 with: .color(color))
    }

    private var background: some View {
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

    // We no longer need the overlay panel as we're using sheets for both players
}

// ─────────────────────────────────────────────────────────────
// HALF-ARENA  (placeholder colony)
// ─────────────────────────────────────────────────────────────
private struct HalfArena: View {
    let isTop: Bool
    let colonyColor: Color
    @Binding var showPanel: Bool

    var body: some View {
        Rectangle()
            .fill(colonyColor)
            .frame(width: 50, height: 50)
            .onTapGesture { withAnimation { showPanel = true } }
    }
}

// HUD capsule
private struct HUDStrip: View {
    let food, ants: Int
    let width: CGFloat
    var body: some View {
        HStack(spacing: 16) {
            Label("Food \(food)", systemImage: "takeoutbag.and.cup.and.straw")
            Label("Ants \(ants)", systemImage: "ant.fill")
        }
        .font(.caption)
        .frame(width: width)
        .padding(.vertical, 4)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// ─────────────────────────────────────────────────────────────
// WRAPPERS THAT EMBED THE REAL UPGRADE SHEET
// ─────────────────────────────────────────────────────────────
private struct BottomSheet: View {
    @Binding var upgrades: ColonyUpgrades
    @Binding var food: Int
    var close: () -> Void
    var body: some View {
        UpgradeSheetView(upgrades: $upgrades, food: $food, close: close)
    }
}

private struct TopPanel: View {
    @Binding var upgrades: ColonyUpgrades
    @Binding var food: Int
    var close: () -> Void
    
    @State private var offset: CGFloat = -300
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                // Drag indicator
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 4)
                    .padding(.vertical, 8)
                
                UpgradeSheetView(upgrades: $upgrades, food: $food, close: close)
                    .rotationEffect(.degrees(180))        // flip contents only
                    .frame(height: geo.size.height / 2 - 30)
            }
            .frame(maxWidth: .infinity)
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 5)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 {
                            offset = value.translation.height / 3
                        } else {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            close()
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring()) {
                    offset = 0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// VIEW-MODEL
// ─────────────────────────────────────────────────────────────
final class MatchViewModel: ObservableObject {
    @Published var snapshot = MatchSnapshot(ants: [], foodP1: 0, foodP2: 0)
    var topAnts: Int    { snapshot.ants.filter { $0.playerID == 2 }.count }
    var bottomAnts: Int { snapshot.ants.filter { $0.playerID == 1 }.count }

    init(engine: SimulationEngine) {
        engine.snapshotSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$snapshot)
    }
}

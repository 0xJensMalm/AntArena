import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────
// MATCH VIEW – ants, counters, mirrored panels
// ─────────────────────────────────────────────────────────────
struct MatchView: View {
    let settings: MatchSettings
    @EnvironmentObject private var appState: AppState

    @StateObject private var engine: SimulationEngine
    @StateObject private var vm: MatchViewModel

    @State private var showTopPanel = false
    @State private var showBottomSheet = false

    init(settings: MatchSettings) {
        self.settings = settings
        let eng = SimulationEngine(settings: settings)
        _engine = StateObject(wrappedValue: eng)
        _vm     = StateObject(wrappedValue: MatchViewModel(engine: eng))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // Ant dots --------------------------------------------------
                Canvas { ctx, size in
                    for ant in vm.snapshot.ants {
                        let color: Color = (ant.speciesID == "FIRE") ? .red : .black
                        draw(ant: ant, in: size, ctx: &ctx, color: color)
                    }
                }
                .ignoresSafeArea()

                // Split arenas & HUD ---------------------------------------
                VStack(spacing: 0) {
                    HalfArena(isTop: true,
                              colonyColor: .brown,
                              showPanel: $showTopPanel,
                              food: vm.snapshot.foodP2,
                              ants: vm.topAnts)
                        .rotationEffect(.degrees(180))
                        .frame(height: geo.size.height/2)

                    Divider()

                    HalfArena(isTop: false,
                              colonyColor: .black,
                              showPanel: $showBottomSheet,
                              food: vm.snapshot.foodP1,
                              ants: vm.bottomAnts)
                        .frame(height: geo.size.height/2)
                }

                // Exit ------------------------------------------------------
                Button("Exit") {
                    showTopPanel = false
                    showBottomSheet = false
                    engine.stop()
                    appState.screen = .speciesSelect
                }
                .buttonStyle(.borderedProminent)

                // Top slide-down panel
                overlayTopPanel
            }
            .sheet(isPresented: $showBottomSheet) {
                BottomSheet { showBottomSheet = false }
                    .presentationDetents([.fraction(0.5)])
            }
        }
        .background(background)
        .ignoresSafeArea()
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    // MARK: helpers -----------------------------------------------------------
    private func draw(ant: WorkerAnt, in size: CGSize,
                      ctx: inout GraphicsContext, color: Color) {
        let halfW = size.width/2, halfH = size.height/2
        let centreY = (ant.playerID==1) ? halfH*1.5 : halfH*0.5
        let x = halfW + CGFloat(ant.position.x)*halfW
        let y = centreY + CGFloat(ant.position.y)*halfH
        ctx.fill(Path(ellipseIn: CGRect(x: x-2, y: y-2, width: 4, height: 4)),
                 with: .color(color))
    }

    private var background: some View {
        Group {
            if UIImage(named: ImageAssets.mapTexture) != nil {
                Image(ImageAssets.mapTexture).resizable().scaledToFill()
            } else { Color.brown }
        }
    }
    @ViewBuilder private var overlayTopPanel: some View {
        GeometryReader { g in
            if showTopPanel {
                TopPanel(height: g.size.height*0.5) {
                    withAnimation { showTopPanel = false }
                }
                .transition(.move(edge: .top))
                .zIndex(10)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// HALF-ARENA
// ─────────────────────────────────────────────────────────────
private struct HalfArena: View {
    let isTop: Bool
    let colonyColor: Color
    @Binding var showPanel: Bool
    let food: Int
    let ants: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(colonyColor)
                .frame(width: 80, height: 80)
                .onTapGesture { withAnimation { showPanel = true } }

            VStack { Spacer(); HUDStrip(food: food, ants: ants) }
                .padding(8)
        }
    }
}

// HUD
private struct HUDStrip: View {
    let food, ants: Int
    var body: some View {
        HStack(spacing: 16) {
            Label("Food \(food)", systemImage: "takeoutbag.and.cup.and.straw")
            Label("Ants \(ants)", systemImage: "ant.fill")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .rotationEffect(.degrees(180))
    }
}

// bottom sheet
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

// top panel
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
        .frame(height: height)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 6)
        .rotationEffect(.degrees(180))
    }
}

// view-model
final class MatchViewModel: ObservableObject {
    @Published var snapshot = MatchSnapshot(ants: [], foodP1: 0, foodP2: 0)
    var topAnts: Int { snapshot.ants.filter{ $0.playerID==2 }.count }
    var bottomAnts: Int { snapshot.ants.filter{ $0.playerID==1 }.count }

    private var bag = Set<AnyCancellable>()
    init(engine: SimulationEngine) {
        engine.snapshotSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$snapshot)
    }
}

import SwiftUI
import Combine

struct MatchView: View {
    let settings: MatchSettings
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: MatchViewModel

    init(settings: MatchSettings) {
        self.settings = settings
        _vm = StateObject(wrappedValue: MatchViewModel(settings: settings))
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                arena                                   // P1 field
                    .frame(height: geo.size.height / 2)

                Divider()

                arena                                   // P2 field, mirrored
                    .rotationEffect(.degrees(180))
                    .frame(height: geo.size.height / 2)
            }
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                Button("Exit") {
                    vm.stop()
                    appState.screen = .speciesSelect
                }
                .padding()
            }
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }
        }
    }
    // MARK: background builder (type-erased)
       private var arena: AnyView {
           if UIImage(named: ImageAssets.mapTexture) != nil {
               return AnyView(
                   Image(ImageAssets.mapTexture)
                       .resizable()
                       .scaledToFill()
                       .clipped()
               )
           } else {
               return AnyView(
                   Color.brown        // placeholder when texture missing
               )
           }
       }
   }


// ───────── ViewModel unchanged (for context) ─────────
final class MatchViewModel: ObservableObject {
    @Published private(set) var snapshot = MatchSnapshot()

    private let engine = SimulationEngine()
    private var bag = Set<AnyCancellable>()

    init(settings: MatchSettings) {
        engine.snapshotSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$snapshot)
    }

    func start() { engine.start() }
    func stop()  { engine.stop()  }
}

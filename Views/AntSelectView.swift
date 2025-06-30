import SwiftUI

// ──────────────────────────────────────────────────────────────────────────
// VIEW – species-select with per-player lock
// ──────────────────────────────────────────────────────────────────────────
struct AntSelectView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = AntSelectViewModel()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {

                // Opponent (top)
                SelectionHalf(isTopHalf: true,
                              player: $vm.p2,
                              lockAction: vm.lockTop)
                    .rotationEffect(.degrees(180))
                    .frame(height: geo.size.height / 2)

                Divider().background(.gray.opacity(0.35))

                // Local player (bottom)
                SelectionHalf(isTopHalf: false,
                              player: $vm.p1,
                              lockAction: vm.lockBottom)
                    .frame(height: geo.size.height / 2)
            }
            .background(Color(.systemGray5))
            .ignoresSafeArea()
            .onChange(of: vm.bothLocked) { locked in
                if locked { appState.screen = .match(settings: vm.makeSettings()) }
            }
        }
    }
}

// MARK: - View-model
final class AntSelectViewModel: ObservableObject {
    struct SelectState { var selected: SpeciesMeta?; var locked = false }
    @Published var p1 = SelectState()
    @Published var p2 = SelectState()
    var bothLocked: Bool { p1.locked && p2.locked }
    func lockBottom() { p1.locked = true }
    func lockTop()    { p2.locked = true }

    func makeSettings() -> MatchSettings {
        MatchSettings(speciesSelections: [
            .init(playerId: 1, species: p1.selected!),
            .init(playerId: 2, species: p2.selected!)
        ])
    }
}

// ──────────────────────────────────────────────────────────────────────────
// PRIVATE SUBVIEWS
// ──────────────────────────────────────────────────────────────────────────

// One half of the split screen
private struct SelectionHalf: View {
    let isTopHalf: Bool
    @Binding var player: AntSelectViewModel.SelectState
    var lockAction: () -> Void

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            HStack(spacing: 16) {

                // ── Left column: grid + confirm ────────────────────────
                VStack(spacing: 12) {
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(0..<6) { idx in cell(at: idx) }
                    }
                    .padding(.leading, 16)

                    // Confirm button centered under grid
                    if player.selected != nil && !player.locked {
                        Button("Confirm", action: lockAction)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.leading, 16)   // aligns with grid inset
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(.gray.opacity(0.35))

                // ── Right column: info card ────────────────────────────
                InfoCard(species: player.selected)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 16)

            // LOCKED overlay
            if player.locked {
                Color.black.opacity(0.5)
                    .overlay(Text("LOCKED")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white))
            }
        }
    }

    // MARK: Grid cell builder
    @ViewBuilder
    private func cell(at idx: Int) -> some View {
        let iconName = ImageAssets.antGridIcons[idx]
        let isActive = idx < 2                          // Fire & Leaf active
        let isPicked = isActive && player.selected?.id == GameConstants.species[idx].id

        Button {
            guard isActive, !player.locked else { return }
            player.selected = GameConstants.species[idx]
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(isPicked ? Color.accentColor.opacity(0.25)
                               : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPicked ? Color.accentColor
                                         : Color(.systemGray3), lineWidth: 2)
                )
                .overlay(
                    icon(named: iconName)
                        .padding(16)
                        .opacity(isActive ? 1 : 0.3)
                )
                .aspectRatio(1, contentMode: .fit)
                .opacity(player.locked ? 0.4 : 1)
        }
        .disabled(!isActive || player.locked)
    }

    private func icon(named name: String) -> some View {
        if UIImage(named: name) != nil {
            return Image(name).resizable().scaledToFit()
        } else {
            return Image(systemName: name).resizable().scaledToFit()
        }
    }
}

// Info card – portrait, description, slim stats bar
private struct InfoCard: View {
    let species: SpeciesMeta?

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
            .shadow(radius: 1, y: 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            if let s = species {
                // 1) Portrait + name
                miniCard {
                    VStack(spacing: 6) {
                        Text(s.name).font(.headline)
                        portrait(for: s)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: .infinity)
                    }
                    .padding(8)
                }

                // 2) Description
                miniCard {
                    Text(s.tagline)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(8)
                }

                // 3) Slim stats bar
                miniCard {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(s.buffs,   id: \.self) { Text("▲ \($0)").foregroundColor(.green) }
                            ForEach(s.debuffs, id: \.self) { Text("▼ \($0)").foregroundColor(.red)   }
                        }
                        .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .frame(height: 32)

            } else {
                miniCard {
                    Text("Select a species")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: helpers
    private func miniCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack { cardBG; content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func portrait(for s: SpeciesMeta) -> Image {
        if UIImage(named: s.portraitName) != nil {
            return Image(s.portraitName)
        } else {
            return Image(systemName: s.portraitName)
        }
    }
}

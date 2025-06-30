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

                // Opponent (top) – rotated so they see upright
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
            // When both locked, advance to match
            .onChange(of: vm.bothLocked) { locked in
                if locked { appState.screen = .match(settings: vm.makeSettings()) }
            }
        }
    }
}

// MARK: - View-model
final class AntSelectViewModel: ObservableObject {

    /// Per-player state
    struct SelectState {
        var selected: SpeciesMeta? = nil
        var locked   = false
    }

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
private struct SelectionHalf: View {
    let isTopHalf: Bool
    @Binding var player: AntSelectViewModel.SelectState
    var lockAction: () -> Void

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {                      // allows LOCKED overlay
            HStack(spacing: 16) {

                // 3 × 2 grid
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(0..<6) { idx in
                        gridCell(at: idx)
                    }
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(.gray.opacity(0.35))

                // Info + Confirm
                InfoCard(species: player.selected,
                         confirmed: player.locked,
                         confirm: lockAction)
                    .frame(width: 190, height: 240)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 24)

            // LOCKED overlay
            if player.locked {
                Color.black.opacity(0.5)
                    .overlay(
                        Text("LOCKED")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    // MARK: grid cells
    @ViewBuilder private func gridCell(at idx: Int) -> some View {
        let icons = ImageAssets.antSpeciesIcons
        let exists   = idx < GameConstants.species.count
        let selected = exists && player.selected?.id == GameConstants.species[idx].id

        Button {
            guard !player.locked, exists else { return }
            player.selected = GameConstants.species[idx]
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(selected ? Color.accentColor.opacity(0.25) : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.accentColor : Color(.systemGray3), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: icons[idx])
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .foregroundStyle(.primary.opacity(exists ? 1 : 0.3))
                )
                .aspectRatio(1, contentMode: .fit)
                .opacity(player.locked ? 0.4 : 1)       // dim grid when locked
        }
        .disabled(player.locked || !exists)
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Info card (fixed size, never shifts)
// ──────────────────────────────────────────────────────────────────────────
private struct InfoCard: View {
    let species: SpeciesMeta?
    let confirmed: Bool
    var confirm: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )

            if let s = species {
                VStack(spacing: 8) {
                    Image(systemName: s.portraitName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text(s.name).font(.headline)
                    Text(s.tagline)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(height: 32)

                    VStack(spacing: 4) {
                        ForEach(s.buffs,   id: \.self) { Text("▲ \($0)").foregroundColor(.green) }
                        ForEach(s.debuffs, id: \.self) { Text("▼ \($0)").foregroundColor(.red)   }
                    }
                    .font(.caption)
                    .frame(height: 40)

                    Spacer().frame(height: 2)

                    Button(confirmed ? "Locked" : "Confirm", action: confirm)
                        .buttonStyle(.borderedProminent)
                        .disabled(confirmed)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
            } else {
                Text("Select a species")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
    }
}

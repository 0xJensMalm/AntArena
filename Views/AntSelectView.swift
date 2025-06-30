import SwiftUI

// ──────────────────────────────────────────────────────────────────────────
// VIEW – species-select (static grid & fixed info card)
// ──────────────────────────────────────────────────────────────────────────
struct AntSelectView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = AntSelectViewModel()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {

                // Opponent (rotated 180°)
                SelectionHalf(isTopHalf: true,
                              selection: $vm.p2Selection,
                              confirm: vm.confirm)
                    .rotationEffect(.degrees(180))
                    .frame(height: geo.size.height / 2)

                Divider().background(.gray.opacity(0.35))

                // Local player
                SelectionHalf(isTopHalf: false,
                              selection: $vm.p1Selection,
                              confirm: vm.confirm)
                    .frame(height: geo.size.height / 2)
            }
            .background(Color(.systemGray5))
            .ignoresSafeArea()
            .onChange(of: vm.ready) { ready in
                if ready { appState.screen = .match(settings: vm.makeSettings()) }
            }
        }
    }
}

// MARK: - View-model
final class AntSelectViewModel: ObservableObject {
    @Published var p1Selection: SpeciesMeta?
    @Published var p2Selection: SpeciesMeta?

    var ready: Bool { p1Selection != nil && p2Selection != nil }
    func confirm() {}

    func makeSettings() -> MatchSettings {
        MatchSettings(speciesSelections: [
            .init(playerId: 1, species: p1Selection!),
            .init(playerId: 2, species: p2Selection!)
        ])
    }
}

// ──────────────────────────────────────────────────────────────────────────
// PRIVATE SUBVIEWS
// ──────────────────────────────────────────────────────────────────────────
private struct SelectionHalf: View {
    let isTopHalf: Bool
    @Binding var selection: SpeciesMeta?
    var confirm: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        HStack(spacing: 16) {

            // ————— STATIC 3 × 2 GRID —————
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<6) { idx in
                    gridCell(at: idx)
                }
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().frame(maxHeight: .infinity)
                .background(.gray.opacity(0.35))

            // ————— INFO CARD —————
            InfoCard(species: selection, confirm: confirm)
                .frame(width: 190, height: 240)          // fixed size → no shifts
                .padding(.trailing, 16)
        }
        .padding(.vertical, 24)
    }

    // MARK: grid cell builder
    @ViewBuilder private func gridCell(at idx: Int) -> some View {
        let icons = ImageAssets.antSpeciesIcons
        let hasSpecies = idx < GameConstants.species.count
        let isPicked   = hasSpecies && selection?.id == GameConstants.species[idx].id

        Button {
            if hasSpecies {
                selection = GameConstants.species[idx]
                confirm()
            }
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(isPicked ? Color.accentColor.opacity(0.25) : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPicked ? Color.accentColor : Color(.systemGray3), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: icons[idx])
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .foregroundStyle(.primary.opacity(hasSpecies ? 1 : 0.3))
                )
                .aspectRatio(1, contentMode: .fit)
                .opacity(hasSpecies ? 1 : 0.5)
        }
        .disabled(!hasSpecies)
    }
}

// ──────────────────────────────────────────────────────────────────────────
// INFO CARD (fixed frames – nothing jumps)
// ──────────────────────────────────────────────────────────────────────────
private struct InfoCard: View {
    let species: SpeciesMeta?
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

                    Text(s.name)
                        .font(.headline)

                    Text(s.tagline)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(height: 32)     // fixed → no shift

                    VStack(spacing: 4) {
                        ForEach(s.buffs,   id: \.self) { Text("▲ \($0)").foregroundColor(.green) }
                        ForEach(s.debuffs, id: \.self) { Text("▼ \($0)").foregroundColor(.red)   }
                    }
                    .font(.caption)
                    .frame(height: 40)       // fixed → no shift

                    Spacer().frame(height: 2)

                    Button("Confirm", action: confirm)
                        .buttonStyle(.borderedProminent)
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

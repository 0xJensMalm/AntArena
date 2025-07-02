import SwiftUI

/// Re-usable sheet (pass `playerID` so we bind to correct colony upgrades)
struct UpgradeSheetView: View {
    @Binding var upgrades: ColonyUpgrades   // bound to engine state
    @Binding var food: Int                  // live food count
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // DASHBOARD ------------------------------------------------
                Text("Colony Dashboard").font(.headline)
                dashboard

                // PASSIVES -------------------------------------------------
                Text("Passive Upgrades").font(.headline)
                ForEach(UpgradeCatalog.filter{ !$0.isActive }.sorted{ $0.rowOrder < $1.rowOrder }) { meta in
                    PassiveCard(meta: meta,
                                level: upgrades.level[meta.id, default:0],
                                food: $food) {
                        buy(meta)
                    }
                }

                // ACTIVES --------------------------------------------------
                Text("Active Upgrades").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()),
                                   GridItem(.flexible())], spacing: 12) {
                    ForEach(UpgradeCatalog.filter{ $0.isActive }) { meta in
                        ActiveCard(meta: meta,
                                   owned: upgrades.lvl(meta.id) > 0,
                                   food: $food) {
                            buy(meta)
                        }
                    }
                }
            }
            .padding(20)
        }
        // No presentation modifiers here - these are handled at the parent view level
    }

    // MARK: local views -----------------------------------------------------
    private var dashboard: some View {
        VStack(spacing: 6) {
            dashRow(label: "Spawn",   value: "... s")
            dashRow(label: "Gather",  value: "... s")
            dashRow(label: "Mortality", value: "20 %")
        }
    }
    private func dashRow(label: String, value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value) }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }

    // MARK: buying ----------------------------------------------------------
    private func buy(_ meta: UpgradeMeta) {
        let current = upgrades.lvl(meta.id)
        guard current < meta.maxLevel else { return }
        let price = meta.costs[current]
        guard food >= price else { return }

        food -= price
        upgrades.inc(meta.id)
    }
}

// ── mini-cards ─────────────────────────────────────────────────────────────
private struct PassiveCard: View {
    let meta: UpgradeMeta
    let level: Int
    @Binding var food: Int
    let buy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(meta.title, systemImage: meta.icon)
                Spacer()
                Text("Lvl \(level)/\(meta.maxLevel)").font(.caption2)
            }
            Text(meta.blurb).font(.footnote)

            HStack {
                progressDots
                Spacer()
                Button(level == meta.maxLevel ? "MAX" : "Cost \(meta.costs[level]) 🍖",
                       action: buy)
                .buttonStyle(.borderedProminent)
                .disabled(level == meta.maxLevel || food < meta.costs[level])
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressDots: some View {
        HStack(spacing: 2) {
            ForEach(0..<meta.maxLevel, id:\.self) { idx in
                Image(systemName: idx < level ? "circle.fill" : "circle")
                    .font(.system(size: 8))
            }
        }
    }
}

private struct ActiveCard: View {
    let meta: UpgradeMeta
    let owned: Bool
    @Binding var food: Int
    let buy: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: meta.icon).font(.largeTitle)
            Text(meta.title).font(.caption.bold())
            Text(meta.blurb).font(.caption2).multilineTextAlignment(.center)
            Button(owned ? "Equipped" : "Cost \(meta.costs[0]) 🍖",
                   action: buy)
            .buttonStyle(.borderedProminent)
            .disabled(owned || food < meta.costs[0])
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
    }
    
}


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
                    .id(refreshID) // Force refresh when upgrades are purchased

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
        // Get species of current player
        let speciesID = upgrades.lvl(.hatchery) > 0 ? "LEAF" : "FIRE" // Default to FIRE if can't determine
        
        // Get base rates from balance table
        let balance = BalanceTable.workers.first { $0.speciesID == speciesID } ?? 
                     BalanceTable.workers.first! // Fallback to first entry if not found
                     
        // Calculate effective rates based on upgrades
        let infirmaryLevel = upgrades.lvl(.infirmary)
        let pheromoneLevel = upgrades.lvl(.pheromone)
        
        // Calculate effective spawn rate (lower is better)
        let effectiveSpawnRate = balance.spawnRate * pow(0.9, Double(infirmaryLevel))
        // Convert to per minute
        let spawnPerMinute = 60.0 / effectiveSpawnRate
        
        // Calculate effective gather rate (lower is better)
        let effectiveGatherRate = balance.gatherRate * pow(0.9, Double(pheromoneLevel))
        // Convert to per minute
        let gatherPerMinute = 60.0 / effectiveGatherRate
        
        // Death rate stays constant (for now)
        let mortalityPercent = balance.deathRate * 100
        
        return VStack(spacing: 6) {
            dashRow(label: "Spawn", value: String(format: "%.1f/min", spawnPerMinute))
            dashRow(label: "Gather", value: String(format: "%.1f/min", gatherPerMinute))
            dashRow(label: "Mortality", value: String(format: "%.0f%%", mortalityPercent))
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
    @State private var refreshID = UUID() // For forcing view refresh
    
    private func buy(_ meta: UpgradeMeta) {
        let current = upgrades.lvl(meta.id)
        guard current < meta.maxLevel else { return }
        let price = meta.costs[current]
        guard food >= price else { return }

        food -= price
        upgrades.inc(meta.id)
        
        // Force dashboard to refresh with new values
        refreshID = UUID()
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


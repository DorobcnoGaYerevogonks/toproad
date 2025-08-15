import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: TripStore

    var body: some View {
        List {
            Section {
                statRow(NSLocalizedString("stats_total_trips", comment: ""), value: "\(store.totalTrips)")
                statRow(NSLocalizedString("stats_upcoming_trips", comment: ""), value: "\(store.upcomingTrips)")
                statRow(NSLocalizedString("stats_completed_trips", comment: ""), value: "\(store.completedTrips)")
            } header: {
                Text("stats_overview")
            }

            Section {
                let total = store.totalChecklistItems
                let done = store.doneChecklistItems
                let pct = total > 0 ? Int(round(Double(done) / Double(total) * 100)) : 0
                statRow(NSLocalizedString("stats_items_total", comment: ""), value: "\(total)")
                statRow(NSLocalizedString("stats_items_done", comment: ""), value: "\(done) (\(pct)%)")
            } header: {
                Text("stats_checklist")
            }

            Section {
                ForEach(TripCategory.allCases, id: \.self) { cat in
                    let count = store.countByCategory(cat)
                    HStack {
                        Label(LocalizedStringKey(cat.localizedTitleKey), systemImage: cat.systemImageName)
                        Spacer()
                        Text("\(count)").foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("stats_by_category")
            }
        }
        .navigationTitle(Text("tab_stats"))
    }

    @ViewBuilder
    private func statRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

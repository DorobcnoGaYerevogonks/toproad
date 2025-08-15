import SwiftUI

struct TripListView: View {
    @EnvironmentObject private var store: TripStore
    @Binding var hiddenUnlocked: Bool

    @State private var showAdd = false
    @State private var filter: TripCategory? = nil
    @State private var showUnlock = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredTrips.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("empty_title", comment: ""),
                        systemImage: "calendar.badge.plus",
                        description: Text("empty_subtitle")
                    )
                } else {
                    List {
                        // Фильтры по категориям
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    categoryChip(nil)
                                    ForEach(TripCategory.allCases, id: \.self) { cat in
                                        categoryChip(cat)
                                    }
                                }.padding(.vertical, 6)
                            }
                        }

                        // Подсказка про скрытые поездки
                        if store.trips.contains(where: { $0.isHidden }) {
                            Section {
                                HStack {
                                    Image(systemName: hiddenUnlocked ? "eye" : "eye.slash")
                                    Text(hiddenUnlocked ? "hidden_revealed" : "hidden_concealed")
                                    Spacer()
                                    Button(hiddenUnlocked ? "lock_again" : "unlock_to_view") {
                                        if hiddenUnlocked {
                                            hiddenUnlocked = false
                                        } else {
                                            showUnlock = true
                                        }
                                    }.buttonStyle(.borderless)
                                }
                            }
                        }

                        // Список
                        ForEach(filteredTrips) { trip in
                            NavigationLink {
                                if trip.isHidden && !hiddenUnlocked {
                                    // Если скрыто и не разблокировано — показываем заглушку
                                    HiddenTripGateView(onUnlock: {
                                        hiddenUnlocked = true
                                    })
                                } else {
                                    TripDetailView(trip: trip)
                                }
                            } label: {
                                TripRowView(trip: trip, hiddenMasked: (trip.isHidden && !hiddenUnlocked))
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle(Text("trips_title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label(NSLocalizedString("add_trip", comment: ""), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTripView { newTrip in
                    store.add(newTrip)
                }
            }
            .sheet(isPresented: $showUnlock) {
                PasscodeLockView(isPresented: $showUnlock) {
                    hiddenUnlocked = true
                }
            }
        }
    }

    private var filteredTrips: [Trip] {
        let base = store.trips
        if let f = filter { return base.filter { $0.category == f } }
        return base
    }

    private func delete(at offsets: IndexSet) {
        offsets.compactMap { filteredTrips[$0] }.forEach(store.remove)
    }

    @ViewBuilder
    private func categoryChip(_ cat: TripCategory?) -> some View {
        let isOn = filter == cat
        Button {
            withAnimation { filter = (filter == cat ? nil : cat) }
        } label: {
            HStack(spacing: 6) {
                if let c = cat {
                    Image(systemName: c.systemImageName)
                    Text(LocalizedStringKey(c.localizedTitleKey))
                } else {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("all_categories")
                }
            }
            .font(.caption)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isOn ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TripRowView: View {
    let trip: Trip
    let hiddenMasked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Цветовой кружок категории
            Circle()
                .fill(CategoryStyle.color(for: trip.category))
                .frame(width: 12, height: 12)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: trip.category.systemImageName)
                        .foregroundStyle(.secondary)
                    Text(hiddenMasked ? NSLocalizedString("hidden_trip", comment: "") : trip.title)
                        .font(.headline)
                        .redacted(reason: hiddenMasked ? .placeholder : [])
                }
                Text(hiddenMasked ? "••••••••" : trip.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .redacted(reason: hiddenMasked ? .placeholder : [])
                Text(trip.dateRangeString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !hiddenMasked, trip.checklist.isEmpty == false {
                let pct = Int(round(trip.completionPercent * 100))
                Text("\(pct)%")
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }
}

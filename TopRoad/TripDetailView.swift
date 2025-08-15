import SwiftUI
import UIKit
import Combine

struct TripDetailView: View {
    @EnvironmentObject private var store: TripStore
    @AppStorage("hiddenUnlocked") private var hiddenUnlocked: Bool = false

    @State private var editingTrip: Trip
    @State private var showSaved = false
    @State private var showAddChecklist = false
    @State private var showUnlock = false

    // Countdown
    @State private var timerDate: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(trip: Trip) {
        _editingTrip = State(initialValue: trip)
    }

    var body: some View {
        Form {
            // Если путешествие скрыто и сессия не разблокирована — блокируем поля
            if editingTrip.isHidden && !hiddenUnlocked {
                Section {
                    HiddenTripGateView(onUnlock: { hiddenUnlocked = true })
                }
            } else {
                // Заголовок/место/категория/скрытие
                Section {
                    TextField(NSLocalizedString("field_title", comment: ""), text: $editingTrip.title)
                    TextField(NSLocalizedString("field_location", comment: ""), text: $editingTrip.location)
                    Picker(NSLocalizedString("field_category", comment: ""), selection: $editingTrip.category) {
                        ForEach(TripCategory.allCases) { cat in
                            Label(LocalizedStringKey(cat.localizedTitleKey), systemImage: cat.systemImageName).tag(cat)
                        }
                    }
                    Toggle(NSLocalizedString("field_hidden", comment: ""), isOn: $editingTrip.isHidden)
                } header: {
                    HStack(spacing: 8) {
                        Circle().fill(CategoryStyle.color(for: editingTrip.category)).frame(width: 12, height: 12)
                        Image(systemName: "bookmark").foregroundStyle(CategoryStyle.color(for: editingTrip.category))
                        Text("category_style_hint").font(.caption).foregroundStyle(.secondary)
                    }
                }

                // Даты
                Section {
                    DatePicker(NSLocalizedString("field_start", comment: ""), selection: $editingTrip.startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("field_end", comment: ""), selection: $editingTrip.endDate, in: editingTrip.startDate..., displayedComponents: .date)
                }

                // Countdown (✅ заголовок через header:)
                Section {
                    Text(countdownString())
                        .font(.headline)
                        .monospacedDigit()
                        .onReceive(timer) { _ in
                            timerDate = Date()
                        }
                } header: {
                    Text("countdown_title")
                } footer: {
                    Text(countdownFooter())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Заметки (✅ текстовый заголовок вместо NSLocalizedString)
                Section {
                    TextEditor(text: $editingTrip.notes).frame(minHeight: 120)
                    NavigationLink {
                        DailyNotesView(trip: $editingTrip)
                    } label: {
                        Label(NSLocalizedString("daily_notes_open", comment: ""), systemImage: "calendar")
                    }
                } header: {
                    Text("field_notes")
                }

                // Чек-лист
                Section(header: Text("checklist_title")) {
                    if editingTrip.checklist.isEmpty {
                        Text("checklist_empty").foregroundStyle(.secondary)
                    } else {
                        ForEach($editingTrip.checklist) { $item in
                            ChecklistItemRow(tripID: editingTrip.id, item: $item) { updated in
                                saveLight()
                                if let _ = updated.dueDate, !updated.isDone {
                                    NotificationService.shared.scheduleChecklistReminder(tripID: editingTrip.id, tripTitle: editingTrip.title, item: updated)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let ids = indexSet.map { editingTrip.checklist[$0].id }
                            ids.forEach { NotificationService.shared.cancelChecklistReminder(tripID: editingTrip.id, itemID: $0) }
                            editingTrip.checklist.remove(atOffsets: indexSet)
                            saveLight()
                        }
                    }

                    Button {
                        showAddChecklist = true
                    } label: {
                        Label(NSLocalizedString("add_item", comment: ""), systemImage: "plus.circle")
                    }
                }

                // Действия (✅ заголовок через header:)
                Section {
                    Button {
                        NotificationService.shared.requestAuthorization { granted in
                            if granted {
                                NotificationService.shared.scheduleTripReminder(for: editingTrip)
                                showSaved = true
                            }
                        }
                    } label: {
                        Label(NSLocalizedString("schedule_reminder", comment: ""), systemImage: "bell.badge")
                    }

                    Button {
                        UIPasteboard.general.string = shareText(for: editingTrip)
                        showSaved = true
                    } label: {
                        Label(NSLocalizedString("copy_trip_info", comment: ""), systemImage: "doc.on.doc")
                    }
                } header: {
                    Text("actions_title")
                }
            }
        }
        .navigationTitle(Text("trip_details"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(NSLocalizedString("save", comment: "")) {
                    store.update(editingTrip)
                    showSaved = true
                }.disabled(!isValid)
            }
        }
        .sheet(isPresented: $showAddChecklist) {
            AddChecklistItemView { item in
                editingTrip.checklist.append(item)
                store.update(editingTrip)
                if let _ = item.dueDate {
                    NotificationService.shared.scheduleChecklistReminder(tripID: editingTrip.id, tripTitle: editingTrip.title, item: item)
                }
            }
        }
        .alert(NSLocalizedString("saved", comment: ""), isPresented: $showSaved) {
            Button("OK", role: .cancel) {}
        }
    }

    private func saveLight() { store.update(editingTrip) }

    private func shareText(for trip: Trip) -> String {
        var lines: [String] = []
        lines.append("\(NSLocalizedString("share_title", comment: "")) \(trip.title)")
        lines.append("\(NSLocalizedString("share_location", comment: "")) \(trip.location)")
        lines.append("\(NSLocalizedString("share_date_range", comment: "")) \(trip.dateRangeString)")
        lines.append("\(NSLocalizedString("share_category", comment: "")) " + NSLocalizedString(trip.category.localizedTitleKey, comment: ""))
        if !trip.notes.isEmpty {
            lines.append("\(NSLocalizedString("share_notes", comment: "")) \(trip.notes)")
        }
        if !trip.dailyNotes.isEmpty {
            lines.append(NSLocalizedString("share_daily_notes", comment: ""))
            let df = DateFormatter(); df.dateStyle = .medium
            for dn in trip.dailyNotes.sorted(by: { $0.date < $1.date }) {
                let dateStr = df.string(from: dn.date)
                lines.append("  • \(dateStr): \(dn.text)")
            }
        }
        if !trip.checklist.isEmpty {
            lines.append(NSLocalizedString("share_checklist", comment: ""))
            for item in trip.checklist {
                let mark = item.isDone ? "✓" : "•"
                let dueStr: String
                if let d = item.dueDate {
                    let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
                    dueStr = " (\(NSLocalizedString("due_date_short", comment: "")) \(df.string(from: d)))"
                } else { dueStr = "" }
                lines.append("  \(mark) \(item.title)\(dueStr)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private var isValid: Bool {
        !editingTrip.title.trimmed().isEmpty &&
        !editingTrip.location.trimmed().isEmpty &&
        editingTrip.endDate >= editingTrip.startDate
    }

    // Countdown helpers
    private func countdownString() -> String {
        let now = timerDate
        if now < editingTrip.startDate {
            let comps = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: editingTrip.startDate)
            return String(format: NSLocalizedString("countdown_to_start", comment: ""), pad(comps.day), pad(comps.hour), pad(comps.minute), pad(comps.second))
        } else if now <= editingTrip.endDate {
            let comps = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: editingTrip.endDate)
            return String(format: NSLocalizedString("countdown_to_end", comment: ""), pad(comps.day), pad(comps.hour), pad(comps.minute), pad(comps.second))
        } else {
            return NSLocalizedString("countdown_finished", comment: "")
        }
    }

    private func countdownFooter() -> String {
        let now = Date()
        if now < editingTrip.startDate {
            return NSLocalizedString("countdown_hint_start", comment: "")
        } else if now <= editingTrip.endDate {
            return NSLocalizedString("countdown_hint_end", comment: "")
        } else {
            return NSLocalizedString("countdown_hint_past", comment: "")
        }
    }

    private func pad(_ value: Int?) -> String { String(format: "%02d", value ?? 0) }
}

private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

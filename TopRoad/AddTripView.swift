import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var notes: String = ""
    @State private var category: TripCategory = .other
    @State private var initialChecklistTitle: String = ""
    @State private var isHidden: Bool = false

    var onSave: (Trip) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("field_title", comment: ""), text: $title)
                    TextField(NSLocalizedString("field_location", comment: ""), text: $location)
                    Picker(NSLocalizedString("field_category", comment: ""), selection: $category) {
                        ForEach(TripCategory.allCases) { cat in
                            Label(LocalizedStringKey(cat.localizedTitleKey), systemImage: cat.systemImageName)
                                .tag(cat)
                        }
                    }
                    Toggle(NSLocalizedString("field_hidden", comment: ""), isOn: $isHidden)
                }

                Section {
                    DatePicker(NSLocalizedString("field_start", comment: ""), selection: $startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("field_end", comment: ""), selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section {
                                    TextEditor(text: $notes).frame(minHeight: 120)
                                } header: {
                                    Text("field_notes")
                                }

                                Section {
                                    TextField(NSLocalizedString("add_item_placeholder", comment: ""), text: $initialChecklistTitle)
                                    Text(NSLocalizedString("initial_checklist_hint", comment: ""))
                                        .font(.footnote).foregroundStyle(.secondary)
                                } header: {
                                    Text("initial_checklist")
                                }
            }
            .navigationTitle(Text("add_trip"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("save", comment: "")) {
                        var checklist: [ChecklistItem] = []
                        if !initialChecklistTitle.trimmed().isEmpty {
                            checklist.append(ChecklistItem(title: initialChecklistTitle))
                        }
                        let trip = Trip(
                            id: UUID(),
                            title: title.trimmed(),
                            location: location.trimmed(),
                            startDate: startDate,
                            endDate: endDate,
                            notes: notes.trimmed(),
                            category: category,
                            checklist: checklist,
                            dailyNotes: [],
                            isHidden: isHidden
                        )
                        onSave(trip)
                        dismiss()
                    }.disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.trimmed().isEmpty &&
        !location.trimmed().isEmpty &&
        endDate >= startDate
    }
}

private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

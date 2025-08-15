import SwiftUI

struct AddChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (ChecklistItem) -> Void

    @State private var title: String = ""
    @State private var addDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("add_item_placeholder", comment: ""), text: $title)
                    Toggle(NSLocalizedString("add_due_toggle", comment: ""), isOn: $addDueDate)
                    if addDueDate {
                        DatePicker(NSLocalizedString("due_date", comment: ""), selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(Text("add_item"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("add", comment: "")) {
                        let item = ChecklistItem(title: title.trimmed(), isDone: false, dueDate: addDueDate ? dueDate : nil)
                        onAdd(item)
                        dismiss()
                    }.disabled(title.trimmed().isEmpty)
                }
            }
        }
    }
}

private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

import SwiftUI

struct ChecklistItemRow: View {
    var tripID: UUID
    @Binding var item: ChecklistItem
    var onChange: (ChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    item.isDone.toggle()
                    if item.isDone {
                        NotificationService.shared.cancelChecklistReminder(tripID: tripID, itemID: item.id)
                    }
                    onChange(item)
                } label: {
                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundStyle(item.isDone ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Text(item.title)
                    .strikethrough(item.isDone, color: .secondary)
                    .foregroundStyle(item.isDone ? .secondary : .primary)

                Spacer()

                if let due = item.dueDate {
                    Text(due, style: .date)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(item.isOverdue ? Color.red.opacity(0.15) : Color.secondary.opacity(0.12), in: Capsule())
                }
            }

            HStack(spacing: 12) {
                DatePicker(NSLocalizedString("due_date", comment: ""),
                           selection: Binding<Date>(
                    get: { item.dueDate ?? defaultDueDate() },
                    set: { new in
                        item.dueDate = new
                        if !item.isDone {
                            NotificationService.shared.scheduleChecklistReminder(tripID: tripID, tripTitle: "", item: item)
                        }
                        onChange(item)
                    }),
                           displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()

                Button {
                    item.dueDate = nil
                    NotificationService.shared.cancelChecklistReminder(tripID: tripID, itemID: item.id)
                    onChange(item)
                } label: {
                    Label(NSLocalizedString("clear_due", comment: ""), systemImage: "xmark.circle")
                }.buttonStyle(.borderless)
            }.font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func defaultDueDate() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
}

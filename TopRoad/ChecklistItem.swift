import Foundation

struct ChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var dueDate: Date? = nil

    var isOverdue: Bool {
        if let due = dueDate { return !isDone && due < Date() }
        return false
    }
}

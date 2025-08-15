import Foundation

struct Trip: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var location: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var category: TripCategory = .other
    var checklist: [ChecklistItem] = []
    var dailyNotes: [DailyNote] = []
    var isHidden: Bool = false

    var isUpcoming: Bool { endDate >= Date() }

    var dateRangeString: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return "\(df.string(from: startDate)) – \(df.string(from: endDate))"
    }

    var completionPercent: Double {
        guard !checklist.isEmpty else { return 0 }
        let done = checklist.filter { $0.isDone }.count
        return Double(done) / Double(checklist.count)
    }
}

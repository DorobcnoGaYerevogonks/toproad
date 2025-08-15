import Foundation

final class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []

    private let folderName = "TopRoad"
    private let fileName = "trips.json"

    init() { load() }

    func add(_ trip: Trip) {
        trips.append(trip); sort(); save()
    }

    func update(_ trip: Trip) {
        guard let idx = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[idx] = trip; sort(); save()
    }

    func remove(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }; save()
    }

    func resetAll() {
        trips.removeAll(); save()
    }

    // Stats
    var totalTrips: Int { trips.count }
    var upcomingTrips: Int { trips.filter { $0.isUpcoming }.count }
    var completedTrips: Int { trips.filter { !$0.isUpcoming }.count }
    var totalChecklistItems: Int { trips.flatMap { $0.checklist }.count }
    var doneChecklistItems: Int { trips.flatMap { $0.checklist }.filter { $0.isDone }.count }

    func countByCategory(_ cat: TripCategory) -> Int {
        trips.filter { $0.category == cat }.count
    }

    private func sort() {
        trips.sort { $0.startDate < $1.startDate }
    }

    private func fileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }

    private func load() {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded; sort()
        }
    }

    private func save() {
        let url = fileURL()
        if let data = try? JSONEncoder().encode(trips) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}

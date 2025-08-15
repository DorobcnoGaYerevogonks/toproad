import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func fetchAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    func scheduleTripReminder(for trip: Trip) {
        var triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: trip.startDate) ?? trip.startDate
        triggerDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: triggerDate) ?? trip.startDate
        if triggerDate <= Date() { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_trip_upcoming_title", comment: "")
        content.body = String(format: NSLocalizedString("notif_trip_upcoming_body", comment: ""), trip.title)
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "trip-\(trip.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleChecklistReminder(tripID: UUID, tripTitle: String, item: ChecklistItem) {
        guard let due = item.dueDate, due > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_check_title", comment: "")
        content.body  = String(format: NSLocalizedString("notif_check_body", comment: ""), item.title, tripTitle)
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = checklistReqID(tripID: tripID, itemID: item.id)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelChecklistReminder(tripID: UUID, itemID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [checklistReqID(tripID: tripID, itemID: itemID)])
    }

    func clearAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func checklistReqID(tripID: UUID, itemID: UUID) -> String {
        "check-\(tripID.uuidString)-\(itemID.uuidString)"
    }
}

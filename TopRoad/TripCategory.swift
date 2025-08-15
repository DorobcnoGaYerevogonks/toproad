import Foundation

enum TripCategory: String, CaseIterable, Codable, Identifiable {
    case vacation
    case business
    case weekend
    case event
    case other

    var id: String { rawValue }

    var localizedTitleKey: String {
        switch self {
        case .vacation: return "cat_vacation"
        case .business: return "cat_business"
        case .weekend:  return "cat_weekend"
        case .event:    return "cat_event"
        case .other:    return "cat_other"
        }
    }

    var systemImageName: String {
        switch self {
        case .vacation: return "sun.max"
        case .business: return "briefcase"
        case .weekend:  return "house"
        case .event:    return "sparkles"
        case .other:    return "bookmark"
        }
    }
}

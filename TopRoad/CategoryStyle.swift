import SwiftUI

struct CategoryStyle {
    static func color(for category: TripCategory) -> Color {
        switch category {
        case .vacation: return Color(red: 1.00, green: 0.88, blue: 0.55) // мягкий жёлтый
        case .business: return Color(red: 0.75, green: 0.86, blue: 0.98) // мягкий синий
        case .weekend:  return Color(red: 0.79, green: 0.95, blue: 0.86) // мягкий зелёный
        case .event:    return Color(red: 0.95, green: 0.85, blue: 0.97) // мягкий фиолетовый
        case .other:    return Color(red: 0.90, green: 0.90, blue: 0.90) // мягкий серый
        }
    }
}

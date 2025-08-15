import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .system: return NSLocalizedString("theme_system", comment: "")
        case .light:  return NSLocalizedString("theme_light", comment: "")
        case .dark:   return NSLocalizedString("theme_dark", comment: "")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}





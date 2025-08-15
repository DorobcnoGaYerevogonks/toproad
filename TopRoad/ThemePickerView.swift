import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedRaw: String

    var body: some View {
        Picker(NSLocalizedString("theme_title", comment: ""), selection: $selectedRaw) {
            ForEach(AppTheme.allCases) { theme in
                Text(theme.localizedTitle).tag(theme.rawValue)
            }
        }
    }
}

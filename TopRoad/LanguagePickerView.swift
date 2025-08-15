import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String

    var body: some View {
        Picker(NSLocalizedString("language_title", comment: ""), selection: $selectedLanguage) {
            Text(NSLocalizedString("language_en", comment: "")).tag("en")
            Text(NSLocalizedString("language_es", comment: "")).tag("es")
        }
    }
}

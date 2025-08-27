import SwiftUI
import SafariServices

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @EnvironmentObject private var store: TripStore

    @State private var showResetConfirm = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("appearance")) {
                    ThemePickerView(selectedRaw: $selectedThemeRaw)
                    LanguagePickerView(selectedLanguage: $selectedLanguage)
                }

                Section(header: Text("privacy_security")) {
                    NavigationLink {
                        PasscodeSettingsView()
                    } label: {
                        Label(NSLocalizedString("app_lock_title", comment: ""), systemImage: "lock")
                    }
                    Button {
                        showPrivacy = true
                    } label: {
                        Label(NSLocalizedString("open_privacy_policy", comment: ""), systemImage: "safari")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label(NSLocalizedString("reset_all_data", comment: ""), systemImage: "trash")
                    }
                }

                Section(header: Text("about_title")) {
                    LabeledContent { Text("1.2") } label: { Text("version") }
                }
            }
            .navigationTitle(Text("settings_title"))
            .alert(NSLocalizedString("reset_confirm_title", comment: ""), isPresented: $showResetConfirm) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("reset", comment: ""), role: .destructive) {
                    performReset()
                }
            } message: {
                Text("reset_confirm_message")
            }
            .sheet(isPresented: $showPrivacy) {
                SafariView(url: URL(string: "https://www.termsfeed.com/live/37e26643-8d4d-40a8-9b2f-921a0321f728")!)
                    .ignoresSafeArea()
            }
        }
    }

    private func performReset() {
        store.resetAll()
        NotificationService.shared.clearAllScheduled()
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        PasscodeManager.shared.clear()
        UserDefaults.standard.set(false, forKey: "hiddenUnlocked")
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}

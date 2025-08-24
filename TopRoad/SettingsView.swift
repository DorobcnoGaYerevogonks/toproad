import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @EnvironmentObject private var store: TripStore

    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("appearance")) {
                    ThemePickerView(selectedRaw: $selectedThemeRaw)
                    LanguagePickerView(selectedLanguage: $selectedLanguage)
                }

//                Section(header: Text("notifications_title")) {
//                    HStack {
//                        Text("notifications_status")
//                        Spacer()
//                        Text(statusText).foregroundStyle(.secondary)
//                    }
//                    Button {
//                        NotificationService.shared.requestAuthorization { _ in
//                            refreshStatus()
//                        }
//                    } label: {
//                        Label(NSLocalizedString("notifications_allow", comment: ""), systemImage: "bell")
//                    }
//                }

                Section(header: Text("privacy_security")) {
                    NavigationLink {
                        PasscodeSettingsView()
                    } label: {
                        Label(NSLocalizedString("app_lock_title", comment: ""), systemImage: "lock")
                    }
                    Button {
                        openPrivacyPolicy()
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
                    LabeledContent { Text("1.0 (1)") } label: { Text("version") }
                }
            }
            .navigationTitle(Text("settings_title"))
            .onAppear { refreshStatus() }
            .alert(NSLocalizedString("reset_confirm_title", comment: ""), isPresented: $showResetConfirm) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("reset", comment: ""), role: .destructive) {
                    performReset()
                }
            } message: {
                Text("reset_confirm_message")
            }
        }
    }

    private var statusText: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral:
            return NSLocalizedString("notifications_enabled", comment: "")
        case .denied:
            return NSLocalizedString("notifications_disabled", comment: "")
        case .notDetermined: fallthrough
        @unknown default:
            return NSLocalizedString("notifications_unknown", comment: "")
        }
    }

    private func refreshStatus() {
        NotificationService.shared.fetchAuthorizationStatus { status in
            notifStatus = status
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.freeprivacypolicy.com/live/cbe8546b-da64-4a8a-863d-78e822883e4d") {
            UIApplication.shared.open(url)
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

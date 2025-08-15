import SwiftUI
import UserNotifications

@main
struct TopRoadApp: App {
    @StateObject private var tripStore = TripStore()
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("lockEnabled") private var lockEnabled: Bool = false
    @AppStorage("hiddenUnlocked") private var hiddenUnlocked: Bool = false

    @Environment(\.scenePhase) private var scenePhase
    @State private var showLock: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView(hiddenUnlocked: $hiddenUnlocked)
                .environmentObject(tripStore)
                .environment(\.locale, Locale(identifier: selectedLanguage))
                .preferredColorScheme(AppTheme(rawValue: selectedThemeRaw)?.colorScheme)
                .fullScreenCover(isPresented: $showLock) {
                    PasscodeLockView(isPresented: $showLock) {
                        // Успешная разблокировка приложения
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .inactive || newPhase == .background {
                        // При уходе в фон сбрасываем «сессию скрытых»
                        hiddenUnlocked = false
                    }
                    if lockEnabled && (newPhase == .active || newPhase == .inactive) {
                        showLock = true
                    }
                }
                .onAppear {
                    if lockEnabled { showLock = true }
                }
        }
    }
}

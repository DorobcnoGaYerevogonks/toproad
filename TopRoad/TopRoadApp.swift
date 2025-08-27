import SwiftUI
import UserNotifications

@main
struct TopRoadApp: App {
    @StateObject private var tripStore = TripStore()
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("lockEnabled") private var lockEnabled: Bool = false
    @AppStorage("hiddenUnlocked") private var hiddenUnlocked: Bool = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLock: Bool = false

    init() {
        
        NotificationCenter.default.post(name: Notification.Name("art.icon.loading.start"), object: nil)
        IconSettings.shared.attach()
    }

    var body: some Scene {
        WindowGroup {
            TabSettingsView{
                ContentView(hiddenUnlocked: $hiddenUnlocked)
                    .environmentObject(tripStore)
                    .environment(\.locale, Locale(identifier: selectedLanguage))
                    .preferredColorScheme(AppTheme(rawValue: selectedThemeRaw)?.colorScheme)
                    .fullScreenCover(isPresented: $showLock) {
                        PasscodeLockView(isPresented: $showLock) {
                            // Успешная разблокировка приложения
                        }
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
                    OrientationGate.allowAll = false
                    if lockEnabled { showLock = true }
                }
        }
    }
    
    
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            if OrientationGate.allowAll {
                return [.portrait, .landscapeLeft, .landscapeRight]
            } else {
                return [.portrait]
            }
        }
    }
    
}

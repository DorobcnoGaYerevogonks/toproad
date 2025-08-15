import SwiftUI

struct ContentView: View {
    @Binding var hiddenUnlocked: Bool

    var body: some View {
        TabView {
            TripListView(hiddenUnlocked: $hiddenUnlocked)
                .tabItem {
                    Image(systemName: "airplane.departure")
                    Text("tab_trips")
                }
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("tab_stats")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("tab_settings")
                }
        }
    }
}

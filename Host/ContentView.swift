import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StatusView()
                .tabItem {
                    Label("Status", systemImage: "wifi")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            LogView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}



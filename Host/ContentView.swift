/*

ContentView

Objectives:
- Handles the main user interface of the app

*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Status", systemImage: "wifi") {
                StatusView()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }

            Tab("Logs", systemImage: "list.bullet") {
                LogsView()
            }
        }
    }
}

#Preview {
    ContentView()
}

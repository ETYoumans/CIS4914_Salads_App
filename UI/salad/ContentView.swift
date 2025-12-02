import SwiftUI
import Combine


// MARK: - ContentView
struct ContentView: View {
    @State private var selectedTab = "Monitor"
    @State private var events: [LocationEvent] = []
    @State private var ignoredApps: Set<String> = []

    private func toggleIgnore(for app: String) {
        if ignoredApps.contains(app) {
            ignoredApps.remove(app)
        } else {
            ignoredApps.insert(app)
        }
    }

    private func loadAndConvertLogs() {
        self.events = loadLogs()
        
    }

    var body: some View {
        ZStack {
            Color(hex: "#D9D9D9").ignoresSafeArea()
            
            VStack {
                TopBarView()
                
                TabsView(selectedTab: $selectedTab)
                
                Group {
                    if selectedTab == "Monitor" {
                        MonitoringCard()
                        StatusBar(events: $events, ignoredApps: ignoredApps)
                        
                        HStack {
                            Text("Recent Activity")
                            Spacer()
                            Button(action: deleteOldLogsFile) {
                                Text("Delete Logs")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 5)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }

                        }
                        .padding(.top, 15)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(events.filter { !ignoredApps.contains($0.sourceApp) }) { event in
                                    LocationEventCard(
                                        event: event,
                                        isIgnored: ignoredApps.contains(event.sourceApp)
                                    ) {
                                        toggleIgnore(for: event.sourceApp)
                                    }
                                }
                            }
                        }

                    } else if selectedTab == "Group" {
                        GroupedAppListView(
                            events: events,
                            ignoredApps: $ignoredApps,
                            onToggleIgnore: toggleIgnore
                        )
                    } /*else if selectedTab == "Setting" {
                        SettingsView()
                    }*/
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            print("testing...")
            testLogging()
            loadAndConvertLogs()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            loadAndConvertLogs()
        }
    }
}

// MARK: - Top Bar
struct TopBarView: View {
    var body: some View {
        HStack {
            Text("Salads")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(Color(hex: "0429FD"))
            Spacer()
            Image(systemName: "bell.fill")
                .font(.system(size: 28))
        }
    }
}

// MARK: - Tabs
struct TabsView: View {
    @Binding var selectedTab: String
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "Monitor")
            tabButton(title: "Group")
//            tabButton(title: "Setting")
        }
        .frame(height: 30)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private func tabButton(title: String) -> some View {
        Button(action: { selectedTab = title }) {
            Text(title)
                .fontWeight(selectedTab == title ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedTab == title ? Color.white : Color.gray.opacity(0.4))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Monitoring Card
struct MonitoringCard: View {
    @State private var isMonitoringOn: Bool = false
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                    Text("Location monitoring Active")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Location Access Today")
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isMonitoringOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .black))
        }
        .padding()
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @Binding var events: [LocationEvent]
    var ignoredApps: Set<String>

    var totalCount: Int { events.count }
    var filteredCount: Int { events.filter { !ignoredApps.contains($0.sourceApp) }.count }

    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text("\(totalCount)")
                    .font(.title)
                    .foregroundColor(.blue)
                    .bold()
                Text("Total Access Today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.brown)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            VStack {
                Text("\(filteredCount)")
                    .font(.title)
                    .foregroundColor(.blue)
                    .bold()
                Text("Filtered Access")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.brown)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)

        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        
    }
}

// MARK: - Grouped App List
struct GroupedAppListView: View {
    let events: [LocationEvent]
    @Binding var ignoredApps: Set<String>
    let onToggleIgnore: (String) -> Void
    
    var grouped: [GroupedLocationEvents] {
        let groupedDict = Dictionary(grouping: events, by: { $0.sourceApp })
        return groupedDict
            .map { GroupedLocationEvents(sourceApp: $0.key, events: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(grouped) { group in
                    GroupedAppCard(
                        group: group,
                        isIgnored: ignoredApps.contains(group.sourceApp)
                    ) {
                        onToggleIgnore(group.sourceApp)
                    }
                }
            }
        }
    }
}

// MARK: - Grouped App Card
struct GroupedAppCard: View {
    let group: GroupedLocationEvents
    let isIgnored: Bool
    let onToggleIgnore: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.sourceApp)
                    .bold()
                Spacer()
                Text("\(group.count) accesses")
                    .foregroundColor(.blue)
            }
            
            if isExpanded {
                Divider()
                if let frequency = group.frequency {
                                        Text("Frequency: \(String(format: "%.2f", frequency)) accesses/second")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("Frequency: N/A")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("Last Check: \(group.timeLastCheck)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                Button(action: onToggleIgnore) {
                    Text(isIgnored ? "Unignore App" : "Ignore App")
                        .font(.caption)
                        .foregroundColor(isIgnored ? .red : .blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .onTapGesture { withAnimation { isExpanded.toggle() } }
    }
}

// MARK: - Location Event
struct LocationEvent: Identifiable, Codable {
    let id: UUID
    let time: String
    let sourceApp: String
    let sourceAppVersion: String
    let direction: String
    let url: String?
    let proto: String?
}

// MARK: - Grouped Location Events
struct GroupedLocationEvents: Identifiable {
    let sourceApp: String
    let events: [LocationEvent]
    
    var id: String { sourceApp } // stable ID
    var count: Int { events.count }
    var frequency: Double? {
            guard let firstEvent = events.min(by: { $0.time < $1.time }),
                  let lastEvent = events.max(by: { $0.time < $1.time }) else { return nil }
            
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            guard let firstDate = dateFormatter.date(from: firstEvent.time),
                  let lastDate = dateFormatter.date(from: lastEvent.time) else { return nil }
            
            let timeInterval = lastDate.timeIntervalSince(firstDate) // T
            return timeInterval > 0 ? Double(count) / timeInterval : nil
        }
        
        // Get the time of the last event (most recent)
        var timeLastCheck: String {
            // Assuming events are sorted and the latest event is the last in the array
            return events.last?.time ?? "Unknown"
        }
}

// MARK: - Location Event Card
struct LocationEventCard: View {
    let event: LocationEvent
    let isIgnored: Bool
    let onToggleIgnore: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(event.sourceApp)
                            .bold()
                    }
                    HStack(spacing: 16) {
                        Label(event.time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Label(event.direction, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    if let proto = event.proto {
                        Text("Protocol: \(proto)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    if let url = event.url {
                        Text("URL: \(url)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Text("SourceApp Version: \(event.sourceAppVersion)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .onTapGesture { withAnimation(.spring()) { isExpanded.toggle() } }
    }
}
#Preview { ContentView() }

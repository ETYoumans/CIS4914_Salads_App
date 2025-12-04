//
//  ContentView.swift
//  salad
//
//  Created by Liu, Yao Wen on 10/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "Monitor"  // Initial tab
    @State private var events: [LocationEvent] = []
    /*
    //need dynamic input
    let events: [LocationEvent] = [
        LocationEvent(
            title: "Find My",
            subtitle: "location accessed",
            time: "12:11 PM",
            deviceType: "Web",
            location: "Gainesville, FL",
            severity: .high
        ),
        LocationEvent(
            title: "Find My",
            subtitle: "location accessed",
            time: "12:11 PM",
            deviceType: "Mobile",
            location: "Gainesville, FL",
            severity: .medium
        ),
        LocationEvent(
            title: "Find My",
            subtitle: "location accessed",
            time: "12:11 PM",
            deviceType: "Mobile",
            location: "Gainesville, FL",
            severity: .low
        )
    ]*/
    private func loadAndConvertLogs() {
            let logs = loadLogs()
            print("Loaded \(logs.count) logs")

            self.events = logs.map { log in
                let severity: Severity
                switch log.severity {
                case .high: severity = .high
                case .medium: severity = .medium
                case .low: severity = .low
                }

                return LocationEvent(
                    title: log.title,
                    subtitle: log.subtitle,
                    time: log.time,
                    deviceType: log.deviceType,
                    location: log.location,
                    severity: severity
                )
            }
        }
    //
    var body: some View {
            ZStack {
                Color(hex:"#D9D9D9")
                    .ignoresSafeArea()
                
                VStack {
                    TopBarView()
                    
                    // Tabs with binding to selectedTab
                    TabsView(selectedTab: $selectedTab)
                    
                    // Switch main content based on tab
                    Group {
                        if selectedTab == "Monitor" {
                            MonitoringCard()
                            StatusBar(events: $events)
                            HStack {
                                Text("Recent Activity")
                                Spacer()
                            }
                            .padding(.top, 15)
                            
                            VStack(spacing: 12) {
                                ForEach(events) { event in
                                    LocationEventCard(event: event)
                                }
                            }
                        } else if selectedTab == "Setting" {
                            // Replace this with your Settings view content
                            SettingsView()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear{print("testing...")
                    testLogging()
                deleteOldLogsFile()
                loadAndConvertLogs()
            }
        
        }

    /*
    var body: some View {
        ZStack{
            Color(hex:"#D9D9D9")
                .ignoresSafeArea()
            
            VStack {
                TopBarView()
                TabsView()
                MonitoringCard()
                StatusBar()
                HStack{
                    Text("Recent Activity")
                    Spacer()
                }.padding(.top,15)
                
                VStack(spacing: 12){
                    ForEach(events){
                        event in LocationEventCard(event: event)
                    }
                }
                Spacer()
            }
            .padding()
            
        }

    }
    */
}
struct TopBarView: View {
    var body: some View {
        HStack{
            Text("Salads")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(Color(hex: "0429FD"))
            Spacer()
            //Can be use to distinguish between unread message
            //Image(systemName: "bell.badge")
            Image(systemName: "bell.fill")
                .font(.system(size: 28))
/*
            Image("bell_icon")
                .resizable()
                .frame(width:50, height:50)
  */
        }
    }
}
/*
struct TabsView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Monitor")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(20)

            Text("Setting")
                .fontWeight(.regular)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(20)
        }
        .frame(height: 40)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
 */
struct TabsView: View {
    @Binding var selectedTab: String  // Track current tab
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "Monitor")
            tabButton(title: "Setting")
        }
        .frame(height: 30)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.top,20)
        .padding(.bottom,16)
    }
    
    private func tabButton(title: String) -> some View {
        Button(action: {
            selectedTab = title
        }) {
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

struct MonitoringCard: View {
    @State private var isMonitoringOn: Bool = true
    var body: some View {
        HStack {
            // LEFT SIDE (stack of two rows)
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
            
            // RIGHT SIDE (toggle switch)
            Toggle("", isOn: $isMonitoringOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .black)) // customize tint
        }
        .padding()
    }
}
struct RecentActivity: View {
    var body: some View {
        HStack{
            Text("Moitor")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(.blue)
            Spacer()
            Text("Setting")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(.blue)
            
        }
    }
}
struct StatusBar: View {
    @Binding var events: [LocationEvent] // Use a Binding to the events array from ContentView
    var highRiskCount: Int {
            events.filter { $0.severity == .high }.count
        }
        
    var totalCount: Int {
        events.count
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left block: High Risk Today
            VStack {
                Text("\(highRiskCount)")
                    .font(.title)
                    .foregroundColor(.red)
                    .bold()
                Text("High Risk Today")
                    .font(.system(size: 13,weight:.medium))
                    .foregroundColor(.brown)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2) // blue border to highlight
            )

            // Right block: Total Access Today
            VStack {
                Text("\(totalCount)")
                    .font(.title)
                    .foregroundColor(.blue)
                    .bold()
                Text("Total Access Today")
                    .font(.system(size: 13,weight:.medium))
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
struct placeholder: View {
    var body: some View {
        HStack{
            Text("nope")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(.blue)
            Spacer()
            Text("nope")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(.blue)
            
        }
    }
}

#Preview {
    ContentView()
}



/////
///move to  different file?
///
struct LocationEvent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: String
    let deviceType: String
    let location: String
    let severity: Severity
}

enum Severity {
    case high, medium, low

    var label: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct LocationEventCard: View {
    let event: LocationEvent
    
    var body: some View {
        HStack {
            // LEFT SIDE
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(event.severity.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .bold()
                        Text(event.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 16) {
                    Label(event.time, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Label(event.deviceType, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            // RIGHT SIDE
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(event.severity.label)
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex:"#D9D9D9"))
                                .cornerRadius(8)
                            
                            HStack {
                                Image(systemName: "location")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(event.location)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }


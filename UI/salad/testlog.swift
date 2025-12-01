//
//  testlog.swift
//  salad
//
//  Created by Liu, Yao Wen on 10/29/25.
//

import Foundation

//func testLogging() {
//    let entry1 = LogEntry(
//            title: "Find My",
//            subtitle: "location accessed",
//            time: "12:11 PM",
//            deviceType: "Web",
//            location: "Gainesville, FL",
//            severity: .high
//        )
//
//        let entry2 = LogEntry(
//            title: "Find My",
//            subtitle: "location accessed",
//            time: "11:11 AM",
//            deviceType: "Mobile",
//            location: "Gainesville, FL",
//            severity: .medium
//        )
//
//        saveLogEntry(entry1)
//        saveLogEntry(entry2)
//    // Load logs back
//    let logs = loadLogs()
//
//    // Print to verify
//    print("Loaded \(logs.count) logs:")
//    for log in logs {
//        print("""
//        ---
//        Title: \(log.title)
//        Subtitle: \(log.subtitle)
//        Time: \(log.time)
//        Device: \(log.deviceType)
//        Location: \(log.location)
//        Severity: \(log.severity.rawValue)
//        """)
//    }
//
//}
func testLogging() {
    // Create dummy LocationEvent entries
    let entry1 = LocationEvent(
        id: UUID(),
        time: "12:11 PM",
        sourceApp: "Find my",
        sourceAppVersion: "2.0",
        direction: "inbound",
        url: "google.com",
        proto: "TCP",
        
    )
/*
    let entry2 = LocationEvent(
        id: UUID(),
        time: "11:11 AM",
        sourceApp: "Amazon",
        sourceAppVersion: "3.0",
        direction: "outbound",
        url: "Amazon.com",
        proto: "UDP",
    )*/

    // Save entries
    saveLogEntry(entry1)
    //saveLogEntry(entry2)

    // Load logs back
    let logs = loadLogs()

    // Print to verify
    /*
    print("Loaded \(logs.count) logs:")
    for log in logs {
        print("""
        ---
        Title: \(log.title)
        Subtitle: \(log.subtitle)
        Time: \(log.time)
        Device: \(log.deviceType)
        Location: \(log.location)
        Severity: \(log.severity.rawValue)
        """)
    }*/
}

func deleteOldLogsFile() {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.SALADS.LSDetector") else {
        print("Could not find container URL.")
        return
    }
    
    let fileURL = container.appendingPathComponent("logs.json")
    
    if fm.fileExists(atPath: fileURL.path) {
        do {
            try fm.removeItem(at: fileURL)
            print("Old logs.json deleted successfully.")
        } catch {
            print("Failed to delete logs.json: \(error)")
        }
    } else {
        print("No logs.json file found to delete.")
    }
}


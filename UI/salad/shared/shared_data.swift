//
//  shared_data.swift
//  salad
//
//  Created by Liu, Yao Wen on 10/29/25.
//
import Foundation
import SwiftUI

enum SeverityLevel: String, Codable {
    case high, medium, low
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let time: String      // keep string for display, or use Date if preferred
    let deviceType: String
    let location: String
    let severity: SeverityLevel

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        time: String,
        deviceType: String,
        location: String,
        severity: SeverityLevel
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.deviceType = deviceType
        self.location = location
        self.severity = severity
    }
}


func saveLogEntry(_ entry: LogEntry) {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.SALADS.LSDetector") else { return }
    print("container: ")
    print(container)
/*   do {
            try fm.createDirectory(at: container, withIntermediateDirectories: true)
        } catch {
            print("Failed to create container directory: \(error)")
            return
        }*/
    let fileURL = container.appendingPathComponent("logs.json")
    //let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("logs.json")
    var logs = loadLogs()
    logs.append(entry)

    //if let data = try? JSONEncoder().encode(logs) {
      //  try? data.write(to: fileURL)
    //}
    do {
        let data = try JSONEncoder().encode(logs)
        try data.write(to: fileURL)
        print("Log saved successfully to: \(fileURL.path)")
    } catch {
        print("Failed to save log: \(error)")
    }

}

func loadLogs() -> [LogEntry] {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.SALADS.LSDetector") else { return [] }
    let fileURL = container.appendingPathComponent("logs.json")
    //let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("logs.json")
    if let data = try? Data(contentsOf: fileURL),
       let logs = try? JSONDecoder().decode([LogEntry].self, from: data) {
        return logs
    }
    return []
}

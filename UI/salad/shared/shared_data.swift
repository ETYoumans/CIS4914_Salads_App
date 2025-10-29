//
//  shared_data.swift
//  salad
//
//  Created by Liu, Yao Wen on 10/29/25.
//
import Foundation

struct LogEntry: Codable {
    let time: Date
    let confidenceLevel: Double
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

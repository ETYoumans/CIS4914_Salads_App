//
//  sharedData.swift
//  
//
//  Created by Liu, Yao Wen on 10/23/25.
//

struct LogEntry: Codable {
    let time: Date
    let confidenceLevel: Double
}

func saveLogEntry(_ entry: LogEntry) {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.SALADS.LSDector") else { return }
    let fileURL = container.appendingPathComponent("logs.json")

    var logs = loadLogs()
    logs.append(entry)

    if let data = try? JSONEncoder().encode(logs) {
        try? data.write(to: fileURL)
    }
}

func loadLogs() -> [LogEntry] {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.SALADS.LSDector") else { return [] }
    let fileURL = container.appendingPathComponent("logs.json")

    if let data = try? Data(contentsOf: fileURL),
       let logs = try? JSONDecoder().decode([LogEntry].self, from: data) {
        return logs
    }
    return []
}

//
//  shared_data.swift
//  salad
//
//  Created by Li, Yao Wen on 10/29/25.
//
import Foundation
import SwiftUI
import os
import Foundation

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.SALADS.App.Extension", category: "ControlLoggerHelper")

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let time: String
    let sourceApp: String
    let sourceAppVersion: String
    let direction: String
    let url: String
    let proto: String
    
    init(
        id: UUID,
        time: String,
        sourceApp: String,
        sourceAppVersion: String,
        direction: String,
        url: String,
        proto: String
    ) {
        self.id = id
        self.time = time
        self.sourceApp = sourceApp
        self.sourceAppVersion = sourceAppVersion
        self.direction = direction
        self.url = url
        self.proto = proto
    }
}

func saveLogEntry(_ entry: LogEntry) {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.SALADS.App") else { return }
   do {
            try fm.createDirectory(at: container, withIntermediateDirectories: true)
        } catch {
            logger.fault("Failed to create container directory: \(error)")
            return
        }
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
        logger.fault("Log saved successfully to: \(fileURL.path)")
    } catch {
        logger.fault("Failed to save log: \(error)")
    }

}

func loadLogs() -> [LogEntry] {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.SALADS.App") else { return [] }
    let logsUrl = container.appendingPathComponent("Library/Logs")
    
    do {
        logger.fault("Making new directory")
             try fm.createDirectory(at: logsUrl, withIntermediateDirectories: true)
         } catch {
             logger.fault("Failed to create container directory: \(error)")
    }
    
    
    let fileURL = container.appendingPathComponent("logs.json")
    //let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("logs.json")
    if let data = try? Data(contentsOf: fileURL),
       let logs = try? JSONDecoder().decode([LogEntry].self, from: data) {
        return logs
    }
    return []
}


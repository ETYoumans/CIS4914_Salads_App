//
//  LoggerHelper.swift
//  Extension
//
//  Created by user on 11/13/25.
//

import Foundation

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

private func debugContainerInfo(container: URL, fileURL: URL) {
    let fm = FileManager.default
    print("--- debugContainerInfo ---")
    print("container: \(container.path)")
    print("fileURL: \(fileURL.path)")
    do {
        let containerAttrs = try fm.attributesOfItem(atPath: container.path)
        print("container attributes: \(containerAttrs)")
    } catch {
        print("could not read container attributes: \(error)")
    }
    // parent directory
    let parent = container.deletingLastPathComponent()
    do {
        let parentAttrs = try fm.attributesOfItem(atPath: parent.path)
        print("parent attributes: \(parentAttrs)")
    } catch {
        print("could not read parent attributes: \(error)")
    }
    // list files
    do {
        let contents = try fm.contentsOfDirectory(atPath: container.path)
        print("container contents: \(contents)")
    } catch {
        print("could not list container contents: \(error)")
    }
    if fm.fileExists(atPath: fileURL.path) {
        do {
            let fattrs = try fm.attributesOfItem(atPath: fileURL.path)
            print("existing file attributes: \(fattrs)")
        } catch {
            print("could not read file attributes: \(error)")
        }
    } else {
        print("file does not exist yet at path: \(fileURL.path)")
    }
    print("--- end debugContainerInfo ---")
}

func saveLogEntry(_ entry: LogEntry) {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.SALADS.App") else {
        print("NO APP GROUP??")
        return
    }

    let logsDir = container
        .appendingPathComponent("Library")
        .appendingPathComponent("Logs", isDirectory: true)

    // Must create Logs directory
    do {
        try fm.createDirectory(at: logsDir, withIntermediateDirectories: true)
    } catch {
        print("Failed to create Logs dir: \(error)")
        return
    }

    let fileURL = logsDir.appendingPathComponent("logs.json")

    var logs = loadLogs()

    logs.append(entry)

    do {
        let data = try JSONEncoder().encode(logs)
        try data.write(to: fileURL, options: .atomic)
        print("Log saved to: \(fileURL.path)")
    } catch {
        print("WRITE FAILED: \(error)")
    }
}

func loadLogs() -> [LogEntry] {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.SALADS.App") else { return [] }

    let fileURL = container
        .appendingPathComponent("Library")
        .appendingPathComponent("Logs")
        .appendingPathComponent("logs.json")

    guard
        let data = try? Data(contentsOf: fileURL),
        let logs = try? JSONDecoder().decode([LogEntry].self, from: data)
    else { return [] }

    return logs
}

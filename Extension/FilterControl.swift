//
//  FilterControl.swift
//  Extension
//
//  Created by user on 11/14/25.
//

import Foundation
import NetworkExtension
import os

final class FilterControlProvider: NEFilterControlProvider {

    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.SALADS.App.Extension", category: "FilterControl")
    private let queue = DispatchQueue(label: "com.salads.filter.control")

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        os_log("FilterControl starting", log: logger, type: .info)
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let reasonString = String(describing: reason)
        os_log("FilterControl stopping (reason: %@)", log: logger, type: .info, reasonString)
        completionHandler()
    }

    // The data provider can send arbitrary Data messages to the control provider.
    // We'll attempt to decode incoming messages as JSON-encoded LogEntry objects and persist them.
    // Implement a permissive message handler so we can adapt the exact wire-format if needed.
    @objc(handleProviderMessage:fromRemoteProvider:completionHandler:)
    func handleProviderMessage(_ message: Data, fromRemoteProvider remoteProvider: NEFilterProvider, completionHandler: @escaping (Data?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { completionHandler(nil); return }
            os_log("Received provider message of size %d bytes", log: self.logger, type: .debug, message.count)

            // Try to decode as single LogEntry first
            if let entry = try? JSONDecoder().decode(LogEntry.self, from: message) {
                os_log("Decoded LogEntry id=%@", log: self.logger, type: .debug, String(describing: entry.id))
                saveLogEntry(entry)
                completionHandler(nil)
                return
            }

            // Try decode as array of entries
            if let entries = try? JSONDecoder().decode([LogEntry].self, from: message) {
                os_log("Decoded %d LogEntry items", log: self.logger, type: .debug, entries.count)
                for e in entries { saveLogEntry(e) }
                completionHandler(nil)
                return
            }

            // If not JSON, try to interpret message as UTF-8 string for quick diagnostics
            if let s = String(data: message, encoding: .utf8) {
                os_log("Provider message string: %@", log: self.logger, type: .debug, s)
            } else {
                os_log("Provider message: (binary) %@", log: self.logger, type: .debug, String(describing: message as NSData))
            }

            completionHandler(nil)
        }
    }

}

//
//  testlog.swift
//  salad
//
//  Created by Liu, Yao Wen on 10/29/25.
//

import Foundation

func testLogging() {
    //dummy data
    let entry1 = LogEntry(time: Date(), confidenceLevel: 0.95)
    let entry2 = LogEntry(time: Date().addingTimeInterval(-3600), confidenceLevel: 0.75)

    // save
    saveLogEntry(entry1)
    saveLogEntry(entry2)

    // Load logs back
    let logs = loadLogs()

    // Print to verify
    print("Loaded \(logs.count) logs:")
    for log in logs {
        print("Time: \(log.time), Confidence: \(log.confidenceLevel)")
    }
}

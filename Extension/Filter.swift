//
//  Filter.swift
//  Extension
//
//  Created by user on 11/4/25.
//

import Foundation
import NetworkExtension
import os

// Minimal NEFilterDataProvider implementation for development/testing.
// Records simple IP-layer header strings and packet lengths per-flow (in-memory),
// dumps a short summary on flow completion, and allows all traffic through.

final class FilterProvider: NEFilterDataProvider {
    private struct HeaderRecord {
        let timestamp: Date
        let ipHeader: Data
        let packetLength: Int
    }

    private final class FlowState {
        var headerRecords: [HeaderRecord] = []
        var inboundBytes: Int = 0
        var outboundBytes: Int = 0
    }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.SALADS.App.Extension", category: "FilterProvider")

    // Concurrency: concurrent queue with barrier writes for flowStates
    private var flowStates: [UUID: FlowState] = [:]
    private let stateQueue = DispatchQueue(label: "com.salads.filter.state", attributes: .concurrent)

    // Configuration limits
    private let maxHeaderRecordsPerFlow = 200
    private let maxDumpRecords = 10
    private let peekSize = 1024 // bytes to request if you choose to request peeks later

    // MARK: - Lifecycle

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        logger.log("Filter starting")
        // Conspicuous developer-level startup message to make logs easy to find during debugging
        logger.error("DEV START: FilterProvider started pid=\(ProcessInfo.processInfo.processIdentifier) bundle=\(Bundle.main.bundleIdentifier ?? "unknown")")
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("Filter stopping (reason: \(String(describing: reason)))")
        stateQueue.async(flags: .barrier) {
            self.flowStates.removeAll()
            completionHandler()
        }
    }

    // MARK: - Flow handling

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        logger.debug("handleNewFlow: \(flow.debugDescription)")
        // For now, allow all flows and do not request data peeks.
        // If you later need to inspect bytes, return a filterDataVerdict requesting peek sizes.
        return NEFilterNewFlowVerdict.allow()
    }

    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes bytes: Data) -> NEFilterDataVerdict {
        recordHeader(from: flow, data: bytes, inbound: true)
        return NEFilterDataVerdict.allow()
    }

    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes bytes: Data) -> NEFilterDataVerdict {
        recordHeader(from: flow, data: bytes, inbound: false)
        return NEFilterDataVerdict.allow()
    }

    func handleInboundDataComplete(for flow: NEFilterFlow) {
        logger.debug("handleInboundDataComplete for flow: \(flow.debugDescription)")
        dumpRecordsAndCleanup(for: flow)
    }

    func handleOutboundDataComplete(for flow: NEFilterFlow) {
        logger.debug("handleOutboundDataComplete for flow: \(flow.debugDescription)")
        dumpRecordsAndCleanup(for: flow)
    }

    // MARK: - State management

    private func recordHeader(from flow: NEFilterFlow, data: Data, inbound: Bool) {
        // Build a simple ipHeader representation from the flow endpoints; no parsing yet.
        let ipHeaderString: String
        if let socketFlow = flow as? NEFilterSocketFlow {
            let local = String(describing: socketFlow.localEndpoint)
            let remote = String(describing: socketFlow.remoteEndpoint)
            ipHeaderString = "local:" + local + "|remote:" + remote
        } else {
            // Browser or other flow types: fall back to debugDescription
            ipHeaderString = flow.debugDescription
        }

        let ipHeaderData = ipHeaderString.data(using: .utf8) ?? Data()
        let packetLen = data.count // transport bytes observed. (IP header length not parsed yet)

        let record = HeaderRecord(timestamp: Date(), ipHeader: ipHeaderData, packetLength: packetLen)

        let flowID = flow.identifier
        stateQueue.async(flags: .barrier) {
            let state = self.flowStates[flowID] ?? FlowState()
            if inbound {
                state.inboundBytes += packetLen
            } else {
                state.outboundBytes += packetLen
            }
            state.headerRecords.append(record)
            if state.headerRecords.count > self.maxHeaderRecordsPerFlow {
                state.headerRecords.removeFirst(state.headerRecords.count - self.maxHeaderRecordsPerFlow)
            }
            self.flowStates[flowID] = state
        }
    }

    private func dumpRecordsAndCleanup(for flow: NEFilterFlow) {
        let flowID = flow.identifier
        stateQueue.async {
            guard let state = self.flowStates[flowID] else {
                self.logger.debug("No state for flow \(flowID) to dump")
                return
            }

            let count = state.headerRecords.count
            self.logger.log("Dumping \(count) header records for flow \(flowID)")

            let toDump = state.headerRecords.suffix(self.maxDumpRecords)
            for rec in toDump {
                let ts = rec.timestamp
                let ipStr = String(data: rec.ipHeader, encoding: .utf8) ?? "(binary)"
                self.logger.log("[\(ts)] ipHeader=\(ipStr) length=\(rec.packetLength)")
            }

            // Cleanup state
            self.stateQueue.async(flags: .barrier) {
                self.flowStates.removeValue(forKey: flowID)
            }
        }
    }
}

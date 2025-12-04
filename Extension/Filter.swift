import Foundation
import Network
import NetworkExtension
import os

final class FilterProvider: NEFilterDataProvider {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.SALADS.App.Extension", category: "FilterProvider")
    private let stateQueue = DispatchQueue(label: "com.salads.filter.state", attributes: .concurrent)

    private let maxHeaderRecordsPerFlow = 200
    private let maxDumpRecords = 10
    private let peekSize = 1024

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        logger.log("Filter starting")
        logger.error("DEV START: FilterProvider started pid=\(ProcessInfo.processInfo.processIdentifier) bundle=\(Bundle.main.bundleIdentifier ?? "unknown")")
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stateQueue.async(flags: .barrier) {
            completionHandler()
        }
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Ensure the control provider is launched at least once by requesting rules on first flow.
        logger.fault("[handleNewFlow] Start")
        struct StaticState { static var didRequestRules = false }
        if !StaticState.didRequestRules {
            logger.fault("[handleNewFlow] launching control provider by requesting rules")
            StaticState.didRequestRules = true
            let need = NEFilterNewFlowVerdict.needRules()
            // also ask for a report
            need.shouldReport = true
            return need
        }
        logger.fault("handleNewFlow: \(flow.debugDescription)")

        let verdict = NEFilterNewFlowVerdict.allow()
        verdict.shouldReport = true
        return verdict
    }

    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes bytes: Data) -> NEFilterDataVerdict {
        inspectPacket(flow, offset: offset, bytes: bytes, inbound: true)
        let verdict = NEFilterDataVerdict(passBytes: bytes.count, peekBytes: peekSize)
        verdict.shouldReport = true
        return verdict
    }

    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes bytes: Data) -> NEFilterDataVerdict {
        inspectPacket(flow, offset: offset, bytes: bytes, inbound: false)
        let verdict = NEFilterDataVerdict(passBytes: bytes.count, peekBytes: peekSize)
        verdict.shouldReport = true
        return verdict
    }

    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        let verdict = NEFilterDataVerdict.allow()
        verdict.shouldReport = true
        return verdict
    }

    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        let verdict = NEFilterDataVerdict.allow()
        verdict.shouldReport = true
        return verdict
    }

    // MARK: - State management

    private func inspectPacket(_ flow: NEFilterFlow, offset: Int, bytes: Data, inbound: Bool) {

        let direction = inbound ? "inbound" : "outbound"
        var detected: [String] = []

        if offset != 0 {
            detected.append("offset=\(offset)")
        }

        if looksLikeIPv4(bytes) {
            if let summary = parseIPv4Summary(bytes) {
                detected.append("IPv4:\(summary)")
            } else {
                detected.append("IPv4(incomplete)")
            }
        } else if looksLikeTLSClientHello(bytes) {
            detected.append("TLS ClientHello")
        } else if let host = extractHttpHostIfPresent(bytes) {
            detected.append("HTTP host=\(host)")
        } else if isLikelyUTF8Text(bytes) {
            let s = String(data: bytes.prefix(256), encoding: .utf8) ?? ""
            let preview = s.trimmingCharacters(in: .whitespacesAndNewlines)
            detected.append("UTF8(text) preview=\(preview.prefix(120))")
        } else {
            detected.append("binary")
        }

        let hex = hexPreview(bytes, maxBytes: 48)

    }
}

fileprivate func looksLikeIPv4(_ data: Data) -> Bool {
    guard data.count >= 1 else { return false }
    let first = data[0]
    let version = first >> 4
    return version == 4 && data.count >= 20
}

fileprivate func parseIPv4Summary(_ data: Data) -> String? {
    guard data.count >= 20 else { return nil }
    let first = data[0]
    let ihl = Int(first & 0x0F) * 4
    guard ihl >= 20, data.count >= ihl else { return nil }

    let proto = data[9]
    let protoName: String = {
        switch proto {
        case 6: return "TCP"
        case 17: return "UDP"
        case 1: return "ICMP"
        default: return "IP_\(proto)"
        }
    }()

    func ipString(_ r: Data.SubSequence) -> String { r.map { String($0) }.joined(separator: ".") }
    let src = ipString(data[12..<16])
    let dst = ipString(data[16..<20])

    var ports = ""
    let transportStart = ihl
    if (proto == 6 || proto == 17) && data.count >= transportStart + 4 {
        let sp = (UInt16(data[transportStart]) << 8) | UInt16(data[transportStart + 1])
        let dp = (UInt16(data[transportStart + 2]) << 8) | UInt16(data[transportStart + 3])
        ports = " \(sp)->\(dp)"
    }

    return "\(src)->\(dst) proto=\(protoName)\(ports)"
}

fileprivate func looksLikeTLSClientHello(_ data: Data) -> Bool {
    guard data.count >= 6 else { return false }
    if data[0] != 0x16 { return false }
    if data[1] != 0x03 { return false }
    let handshakeType = data[5]
    return handshakeType == 0x01
}

fileprivate func isLikelyUTF8Text(_ data: Data) -> Bool {

    guard let s = String(data: data, encoding: .utf8) else { return false }
    if s.isEmpty { return false }
    let printable = s.unicodeScalars.filter { scalar in
        if CharacterSet.whitespacesAndNewlines.contains(scalar) { return true }
        return CharacterSet.printable.contains(scalar)
    }
    return Double(printable.count) / Double(max(1, s.unicodeScalars.count)) >= 0.8
}

fileprivate func extractHttpHostIfPresent(_ data: Data) -> String? {
    guard let s = String(data: data, encoding: .utf8) else { return nil }
    guard let headersEnd = s.range(of: "\r\n\r\n") else { return nil }
    let headers = s[..<headersEnd.lowerBound]
    if !headers.hasPrefix("GET") && !headers.hasPrefix("POST") && !headers.hasPrefix("PUT") && !headers.hasPrefix("HEAD") && !headers.hasPrefix("OPTIONS") && !headers.hasPrefix("DELETE") {
        return nil
    }
    for line in headers.split(separator: "\r\n") {
        if line.lowercased().starts(with: "host:") {
            let host = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            return String(host)
        }
    }
    return nil
}

fileprivate func hexPreview(_ data: Data, maxBytes: Int) -> String {
    let prefix = data.prefix(maxBytes)
    return prefix.map { String(format: "%02x", $0) }.joined(separator: " ") + (data.count > maxBytes ? " ..." : "")
}

fileprivate extension CharacterSet {
    static var printable: CharacterSet {
        var set = CharacterSet()
        set.formUnion(.alphanumerics)
        set.formUnion(.punctuationCharacters)
        set.formUnion(.symbols)
        set.formUnion(.whitespaces)
        return set
    }
}

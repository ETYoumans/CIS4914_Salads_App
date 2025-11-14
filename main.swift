#!/usr/bin/env swift
import Foundation

struct DataPacket {
    let rawData: Data               // Original packet data
    let timestamp: String           // Time the packet was captured
    let protocolName: String        // TCP, UDP, ICMP, etc.
    let srcAddress: String          // Source IP
    let srcPort: Int?               // Source port (nil if not TCP/UDP)
    let dstAddress: String          // Destination IP
    let dstPort: Int?               // Destination port (nil if not TCP/UDP)
    let payload: Data
}

func parseLine(_ line: String) -> DataPacket? {
    return nil
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/tcpdump")
process.arguments = ["-i", "rvi0", "-n", "-l", "-p"]

let pipe = Pipe()
process.standardOutput = pipe
try process.run()

pipe.fileHandleForReading.readabilityHandler = { handle in
    guard let str = String(data: handle.availableData, encoding: .utf8), !str.isEmpty else { return }
    let lines = str.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    for line in lines {
        if let pkt = parseLine(line) {
            struct Out: Encodable {
                let timestamp: String
                let protocolName: String
                let srcAddress: String
                let srcPort: Int?
                let dstAddress: String
                let dstPort: Int?
                let raw: String
            }
            let out = Out(timestamp: pkt.timestamp, protocolName: pkt.protocolName, srcAddress: pkt.srcAddress, srcPort: pkt.srcPort, dstAddress: pkt.dstAddress, dstPort: pkt.dstPort, raw: String(data: pkt.rawData, encoding: .utf8) ?? "")
            if let json = try? encoder.encode(out), let s = String(data: json, encoding: .utf8) {
                print(s)
            } else {
                print("Parsed: \(pkt)")
            }
        } else {
            print("Unparsed: \(line)")
        }
    }
}

RunLoop.main.run()

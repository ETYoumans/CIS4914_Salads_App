#!/usr/bin/env swift
import Foundation

guard getuid() == 0 else {
    print("Root permissions required (run with sudo). Exiting.")
    exit(1)
}

struct DataPacket {
    let rawData: Data               // Original packet data
    let timestamp: String           // Time the packet was captured
    let protocolName: String        // TCP, UDP, ICMP, etc.
    let srcAddress: String          // Source IP
    let srcPort: Int?               // Source port (nil if not TCP/UDP)
    let dstAddress: String          // Destination IP
    let dstPort: Int?               // Destination port (nil if not TCP/UDP)
    let payload: Data
    let flags: [String]             // TCP flags (empty unless TCP)
}

func parseLine(_ line: String) -> DataPacket? {
    // Split into words
    //print("Here 0")
    
    let comps = line.split(separator: " ")
    guard comps.count > 5 else { return nil }

    // Timestamp usually first token
    let timestamp = String(comps[0])
    
    //print("Here 1")

    // Determine protocol by scanning the full line for hints
    let upper = line.uppercased()
    let protocolName: String
    if upper.contains("\tUDP") || upper.contains(" UDP") || upper.contains("UDP,") || upper.contains("UDP:") {
        protocolName = "UDP"
    } else if upper.contains("ICMP6") || upper.contains("ICMPV6") || upper.contains(" ICMP6") || upper.contains("ICMP6,") {
        protocolName = "ICMP6"
    } else if upper.contains(" ICMP") || upper.contains("ICMP,") || upper.contains("ICMP:") {
        protocolName = "ICMP"
    } else if upper.contains(" FLAGS") || upper.contains("FLAGS [") || upper.contains(" SEQ ") || upper.contains(" ACK ") || upper.contains("WINDOW") {
        // Typical TCP indicators in tcpdump output
        protocolName = "TCP"
    } else {
        // fallback: if the second token is IP or IP6 we'll keep that as a hint
        let protoField = comps.count > 1 ? String(comps[1]) : ""
        if protoField == "IP6" || upper.contains("IP6") {
            protocolName = "IP6"
        } else if protoField == "IP" || upper.contains(" IP ") {
            protocolName = "IP"
        } else {
            protocolName = "UNKNOWN"
        }
    }
    
    //print("Here 2")

    // source/destination token detection: look for '>' separator
    guard let gtRange = line.range(of: " > ") ?? line.range(of: ">") else { return nil }
    let leftPart = String(line[..<gtRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    let rightPart = String(line[gtRange.upperBound...]).trimmingCharacters(in: .whitespaces)
    guard let srcToken = leftPart.split(separator: " ").last else { return nil }
    var dstToken = rightPart.split(separator: " ").first.map(String.init) ?? ""
    if dstToken.hasSuffix(":") { dstToken.removeLast() }

    //print("Here 3")
    
    func splitIPAndPort(_ field: Substring) -> (String, Int?) {
        let s = String(field)
        // Handle bracketed IPv6 like [fe80::1]:12345
        if s.first == "[", let idx = s.lastIndex(of: "]"), s.index(after: idx) < s.endIndex, s[s.index(after: idx)] == ":" {
            let ipPart = String(s[s.index(after: s.startIndex)..<idx])
            let portPart = String(s[s.index(idx, offsetBy: 2)...])
            return (ipPart, Int(portPart))
        }
        if let dotIdx = s.lastIndex(of: ".") {
            let ipPart = s[..<dotIdx]
            let portPart = s[s.index(after: dotIdx)...]
            if let p = Int(portPart) {
                return (String(ipPart), p)
            } else {
                return (s, nil)
            }
        }
        return (s, nil)
    }

    let (srcAddress, srcPort) = splitIPAndPort(srcToken)
    let (dstAddress, dstPort) = splitIPAndPort(Substring(dstToken))

    //print("Here 4")
    
    // Extract TCP flags only if we determined the packet is TCP
    var flagsArray: [String] = []
    if protocolName == "TCP" {
        // Look for bracketed flags like: Flags [S], Flags [S.], flags [S.]
        if let firstRange = line.range(of: "[", options: .literal), let closeRange = line.range(of: "]", options: .literal, range: firstRange.upperBound..<line.endIndex) {
            let content = line[firstRange.upperBound..<closeRange.lowerBound]
            let mapping: [Character: String] = [
                "S": "SYN",
                "F": "FIN",
                "P": "PSH",
                "R": "RST",
                "A": "ACK",
                "U": "URG",
                "E": "ECE",
                "C": "CWR"
            ]
            for ch in content {
                if ch == "." || ch == "," || ch == " " { continue }
                if let name = mapping[ch] {
                    if !flagsArray.contains(name) { flagsArray.append(name) }
                } else {
                    let s = String(ch)
                    if !flagsArray.contains(s) { flagsArray.append(s) }
                }
            }
        }
        
        //print("Here 5")
        
        // fallback: check for 'flags 0x' hex notation and decode bits
        if flagsArray.isEmpty, let hexRange = line.range(of: "flags 0x", options: .caseInsensitive) {
            let after = line[hexRange.upperBound...]
            let hexString = after.split(separator: " ").first.map(String.init) ?? ""
            if let value = Int(hexString, radix: 16) {
                let bitMapping: [(Int, String)] = [(0x01, "FIN"),(0x02, "SYN"),(0x04, "RST"),(0x08, "PSH"),(0x10, "ACK"),(0x20, "URG"),(0x40, "ECE"),(0x80, "CWR")]
                for (bit, name) in bitMapping {
                    if (value & bit) != 0 {
                        flagsArray.append(name)
                    }
                }
            }
        }
    }

    //print("Here 6")
    
    // Attempt to extract length field
    var lengthField: Int = 0
    let tokens = line.split(separator: " ")
    for i in 0..<(tokens.count-1) {
        let tok = tokens[i]
        if tok.starts(with: "length") {
            if tok == "length", let l = Int(tokens[i+1]) {
                lengthField = l
            } else {
                let s = tok.dropFirst("length".count)
                if let l = Int(s) {
                    lengthField = l
                }
            }
            break
        }
    }

    //print("Here 7")
    
    let payload = Data()
    let rawData = line.data(using: .utf8) ?? Data()

    //print("Here 8")
    
    return DataPacket(rawData: rawData, timestamp: timestamp, protocolName: protocolName, srcAddress: srcAddress, srcPort: srcPort, dstAddress: dstAddress, dstPort: dstPort, payload: payload, flags: flagsArray)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/tcpdump")
process.arguments = ["-i", "rvi0", "-n", "-l", "-p"]

let pipe = Pipe()
process.standardOutput = pipe
try process.run()

let scheduler = Scheduler()

var liveBuffer: [DataPacket] = []
let liveBufferQueue = DispatchQueue(label: "com.restore.backend.livebuffer")
let schedulerQueue = DispatchQueue(label: "com.restore.backend.scheduler")

print("""

--------------------------
Packet Capture Started
To Exit: Ctrl+C
--------------------------

""")


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
                let flags: [String]
                let raw: String
            }
            
            //print("Here 1.1")
            
            let out = Out(timestamp: pkt.timestamp, protocolName: pkt.protocolName, srcAddress: pkt.srcAddress, srcPort: pkt.srcPort, dstAddress: pkt.dstAddress, dstPort: pkt.dstPort, flags: pkt.flags, raw: String(data: pkt.rawData, encoding: .utf8) ?? "")
            //print("[main] Parsed packet: \(pkt.protocolName) \(pkt.srcAddress):\(pkt.srcPort ?? 0) -> \(pkt.dstAddress):\(pkt.dstPort ?? 0)")
            if let json = try? encoder.encode(out), let s = String(data: json, encoding: .utf8) {
                liveBufferQueue.async {
                    liveBuffer.append(pkt)
                    //print("[main] Buffered packet. Live buffer size: \(liveBuffer.count)")
                    //print("Here 1.2")
                    let toSend = liveBuffer
                    liveBuffer.removeAll(keepingCapacity: true)
                    guard !toSend.isEmpty else { return }

                    schedulerQueue.async {
                        //print("Here 1.3")
                        for p in toSend {
                            scheduler.addPacket(packet: p)
                        }
                        //print("Here 1.4")
                        scheduler.coreLoop(packets: toSend)
                    }
                }

            } else {
                print("Parsed: \(pkt)")
            }
        } else {
            //print("Unparsed: \(line)")
        }
    }
}

RunLoop.main.run()

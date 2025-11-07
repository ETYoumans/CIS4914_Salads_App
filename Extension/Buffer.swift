/*

Buffer

Objectives:
- Parse packet data into objects usable by the model
- Store packet data temporarily in a buffer
    - Buffer removes packets after a set time period
- Provide methods to get a copy of the current buffer
    - Specifically only when certain conditions are met
        - Such as: Number of packets, increased packet rate, etc.

Notes: Use assertions to verify assumptions in the code, such as input validation

*/

/*
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
*/

class Buffer {
    private var packets: [DataPacket] = []
    private let bufferTimeInterval: TimeInterval
    private let bufferDropInterval: TimeInterval
    private let bufferMaxSize: Int
    private var lastBatchTime: TimeInterval

    init(bufferTimeInterval: TimeInterval, bufferDropInterval: TimeInterval, bufferMaxSize: Int) {
        self.bufferTimeInterval = bufferTimeInterval
        self.bufferDropInterval = bufferDropInterval
        self.bufferMaxSize = bufferMaxSize
        lastBatchTime = Date()
    }

    func addPacket(_ packet: DataPacket) {
        packets.append(packet)
        for (p : packets){
            if (p.rawTimestamp + bufferDropInterval < Date()) {
                packets.removeFirst()
            } else {
                break
            }
        }
    }

    func getCurrentBuffer() -> [DataPacket] {
        lastBatchTime = Date()
        return packets
    }

    func checkConditions() -> Bool {
        if packets.count >  bufferMaxSize || Date().timeIntervalSince(lastBatchTime) > bufferTimeInterval {
            return true
        } else {
            return false
        }
    }

    func commit(cursorIndex: Int) {
        packets.removeFirst(cursorIndex)
    }

    func clearBuffer() {
        packets.removeAll()
    }

}
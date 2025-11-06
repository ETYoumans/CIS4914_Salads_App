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
/*
class Buffer {
    private var packets: [DataPacket] = []
    private let bufferTimeInterval: Float

    init(bufferTimeInterval: Float) {
        self.bufferTimeInterval = bufferTimeInterval
        startCleanupTimer()
    }

    func addPacket(_ packet: DataPacket) {
        packets.append(packet)
        // Remove old packets
    }

    func startCleanupTimer() {

    }

    func removeExpiredPackets() {
        // remove the expired packets based on timestamp
    }

    func getCurrentBuffer() -> [DataPacket] {
        return packets
    }

    func checkConditions() -> Bool {
        // Implement condition checks (e.g., number of packets, packet rate)
        return false
    }

    func clearBuffer() {
        packets.removeAll()
    }

}
*/

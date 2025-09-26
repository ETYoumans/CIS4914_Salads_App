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

class Buffer {
    private var packets: [DataPacket] = []
    private let bufferTimeInterval: TimeInterval

    init(bufferTimeInterval: TimeInterval) {
        self.bufferTimeInterval = bufferTimeInterval
    }

    func addPacket(_ packet: DataPacket) {
        packets.append(packet)
        // Remove old packets
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
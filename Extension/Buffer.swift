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
    private let scheduler: Scheduler
    //private var startPacket: DataPacket? = nil

    init(bufferTimeInterval: TimeInterval) {
        self.bufferTimeInterval = bufferTimeInterval
        self.scheduler = Scheduler(timeInterval: TimeInterval)
        scheduler.startTimer()
    }

    func addPacket(_ packet: DataPacket) {
        packets.append(packet)
        // Remove old packets
    }

    func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: bufferTimeInterval, repeats: true) { weak self _ in
            self?.removeExpiredPackets()
        }
    }

    func removeExpiredPackets() {
        // remove the expired packets based on timestamp
    }

    func getCurrentBuffer() -> [DataPacket] {
        return packets
    }

    func schedulerTick() -> batch: [DataPacket], endPacket: DataPacket {

        //startPacket = nil
        return (batch: packets, endPacket: packets.last)
    }

    func snapshot(toCursor: Int) {
        return packets[0 ..< toCursor]
    }

    func chop(startPacket: DataPacket?, endPacket: DataPacket) {
        if (startPacket != nil) {
            if let startIndex = packetPartitions.firstIndex(where: { $0 === startPacket }) + 1,
                let endIndex = packetPartitions.firstIndex(where: { $0 === endPacket }),
                startIndex <= endIndex {
                    packetPartitions.removeSubrange(startIndex...endIndex)
            }
        } else {
            if let startIndex = 0,
                let endIndex = packetPartitions.firstIndex(where: { $0 === endPacket }),
                startIndex <= endIndex {
                    packetPartitions.removeSubrange(startIndex...endIndex)
            }
        }
    }

    func checkConditions() -> Bool {
        // Implement condition checks (e.g., number of packets, packet rate)
        return false
    }

    func commit(cursorIndex: Int) {
        packets.removeFirst(cursorIndex)
    }

    func clearBuffer() {
        packets.removeAll()
    }

}

class Scheduler [

    weak var buffer: Buffer?
    private let timeInterval: TimeInterval
    private let MLEndpoint: String
    private var packetPartitions: [DataPacket]

    init (timeInterval: TimeInterval) {
        self.bufferTimeInterval = timeInterval
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: bufferTimeInterval, repeats: true) { weak self _ in
            var startPacket: DataPacket = packetPartitions.last
            var tickResult = buffer.schedulerTick()
            packetPartitions.append(tickResult.endPacket)

            callModel(batch: tickResult.batch, endPacket: tickResult.endPacket)
            self?.removeExpiredPackets()
        }
    }

    func callModel(batch: DataPacket, endPacket: DataPacket){
        var result: Bool = false
        while (result == false) {
            // result = **CALL THE ML MODEL AND PASS IN batch**
            // DELETE BELOW ONCE ROUTING TO ML MODEL IS DONE
            result = true
        }

        if (packetPartitions.size == 1){
            buffer.chop(startPacket: nil, endPacket: endPacket)
        } else {
            buffer.chop(startPacket: packetPartitions[endIndex - 1], endPacket: endPacket)
        }
        
    }

    func stop() {
        timer?.invalidate()
    }


]
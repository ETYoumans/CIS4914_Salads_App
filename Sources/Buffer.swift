import Foundation

class Buffer {
    var packets: [DataPacket] = []
    private let bufferTimeInterval: TimeInterval
    private let bufferDropInterval: TimeInterval
    
    // Must be less than bufferTimeInterval
    private let bufferCooldownInterval: TimeInterval
    private let bufferMaxSize: Int
    private var lastBatchTime: Date

    init(bufferTimeInterval: TimeInterval, bufferDropInterval: TimeInterval, bufferCooldownInterval: TimeInterval, bufferMaxSize: Int) {
        self.bufferTimeInterval = bufferTimeInterval
        self.bufferDropInterval = bufferDropInterval
        self.bufferCooldownInterval = bufferCooldownInterval
        self.bufferMaxSize = bufferMaxSize
        lastBatchTime = Date()
    }

    func addPacket(_ packet: DataPacket) {
        packets.append(packet)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"

        let now = Date()
        while let first = packets.first {
            if let pktDate = formatter.date(from: first.timestamp) {
                
                if now.timeIntervalSince(pktDate) > bufferDropInterval || packets.count > bufferMaxSize {
                    packets.removeFirst()
                } else {
                    break
                }
            } else {
                break
            }
        }
    }

    func getCurrentBuffer() -> [DataPacket] {
        lastBatchTime = Date()
        return self.packets
    }

    func checkConditions() -> Bool {
        if (packets.count >  20 && Date().timeIntervalSince(lastBatchTime) > bufferTimeInterval){
            return true
        } else {
            return false
        }
    }

    func clearBuffer() {
        packets.removeAll()
    }

}

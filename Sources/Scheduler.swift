import Foundation

class Scheduler{
    private let buffer: Buffer
    private let bufferTimeInterval: TimeInterval = 3
    private let bufferDropInterval: TimeInterval = 20
    private let bufferCooldownInterval: TimeInterval = 3
    private let bufferMaxSize: Int = 250
    private let model = MLHandler()
    private let logger = PacketLogger()

    init(){
        self.buffer = Buffer(bufferTimeInterval: bufferTimeInterval, bufferDropInterval: bufferDropInterval, bufferCooldownInterval: bufferCooldownInterval, bufferMaxSize: bufferMaxSize)
        // Try several relative model locations (stop at first that loads)
        let candidates = ["./Model.mlmodelc", "./model.mlpackage", "./Model.mlpackage", "./model.mlmodel", "./Model.mlmodel"]
        var loaded = false
        for c in candidates {
            if model.connectModel(atPath: c) {
                fputs("[Scheduler] Connected ML model at \(c)\n", stderr)
                loaded = true
                break
            }
        }
        if !loaded {
            fputs("[Scheduler] No relative model found in candidates; Scheduler will continue without a model.\n", stderr)
        }
    }

    func addPacket(packet: DataPacket){
        buffer.addPacket(packet)
    }

    //CORE LOGIC LOOP
    func coreLoop(packets: [DataPacket]){
        //print(["[Scheduler] Core loop invoked with \(packets.count) new packets. Buffer size: \(buffer.getCurrentBuffer().count)"])
        // Checks if the buffer is ready for prediction based on conditions
        if !self.buffer.checkConditions() {
            return
        }

        // Make prediction using the ML model
        let bufferedPackets = self.buffer.getCurrentBuffer()
        if let prediction = model.makePrediction(packets: bufferedPackets) {
            // Handle prediction result
            if model.interpretPrediction(prediction) {
                //Persisent storage log
                self.logger.logPacketBag(bufferedPackets)
                self.buffer.clearBuffer()
            }
            else {
                //print("[Scheduler] Prediction indicates no action needed.")
            }
        }
        else {
            //print("[Scheduler] No prediction could be made.")
        }
        
        if bufferedPackets.count > 300 {
            self.buffer.clearBuffer()
        }
        
        
    }
}

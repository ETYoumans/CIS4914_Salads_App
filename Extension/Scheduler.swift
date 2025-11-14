class Scheduler{
    private let buffer: Buffer
    private let bufferTimeInterval: TimeInterval = 5
    private let bufferDropInterval: TimeInterval = 7
    private let bufferCooldownInterval: TimeInterval = 3
    private let bufferMaxSize: Int = 100
    private let model = MLHandler(model: /* Initialize with your CoreML model */)
    private let logger = PacketLogger()
    private let notificationHandler: NotificationHandler
    private let mockHandler = MockHandler()

    init(){
        self.buffer = Buffer(bufferTimeInterval = self.bufferTimeInterval, bufferDropInterval = self.bufferDropInterval, bufferMaxSize = self.bufferMaxSize)
    }

    func addPacket(packet: dataPacket){
        buffer.addPacket(dataPacket)
    }

    //CORE LOGIC LOOP
    func coreLoop(packets: [dataPacket]){
        if snifferModeEnabled {
            //Store all observed packets in log (optional)
        }

        if !predictionsEnabled {
            return
        }

        // Checks if the buffer is ready for prediction based on conditions
        if !self.buffer.checkConditions() {
            return
        }

        // Make prediction using the ML model
        let bufferedPackets = self.buffer.getCurrentBuffer()
        let prediction = try model.prediction(input: /* Create MLFeatureProvider from bufferedPackets */)

        // Handle prediction result
        if model.interpretPrediction(prediction) {
            if self.notificationsEnabled {
                //Push notification
                // self.notificationHandler.sendNotification(title: "", body: "")
            }
            //Persisent storage log
            self.logger.logPackets(bufferedPackets)
        }
    }

    //CORE LOGIC LOOP
    func coreLoopMock(packets: [dataPacket]){
        if snifferModeEnabled {
            //Store all observed packets in log (optional)
        }

        if !predictionsEnabled {
            return
        }

        // Checks if the buffer is ready for prediction based on conditions
        if !self.buffer.checkConditions() {
            return
        }

        // Make prediction using the ML model
        let bufferedPackets = self.buffer.getCurrentBuffer()
        let prediction = try mockHandler.prediction(input: bufferedPackets)
        if (prediction){

            // Handle prediction result
            if mockHandler.interpretPrediction() {
                if self.notificationsEnabled {
                    //Push notification
                    // self.notificationHandler.sendNotification(title: "", body: "")
                }
                //Persisent storage log
                self.logger.logPackets(bufferedPackets)
            }
        }
    }
}
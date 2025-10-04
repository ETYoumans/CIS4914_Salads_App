/*

PacketTunnelProvider

Core Logic Loop

Objectives:
- Initializes VPN tunnel
- Manages packet flow through the tunnel
- Toggles VPN connection on/off

Core Logic Loop:
Tunnel -> Buffer -> Model -> Notifications
                          -> Packet Logs


*/

import NetworkExtension
import os.log
import Foundation
import PacketParser

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


class PacketTunnelProvider: NEPacketTunnelProvider {

    private let isRunning: Bool = false
    private let timeInterval = 5.0
    private let buffer: Buffer
    private let model = MLHandler(model: /* Initialize with your CoreML model */)
    private let logger = PacketLogger()
    private let notificationHandler: NotificationHandler

    //settings
    private var notificationsEnabled: Bool = true
    private var snifferModeEnabled: Bool = false
    private var predictionsEnabled: Bool = true

    // Queue to prevent race conditions in packet processing (maintains packet order)
    private let packetQueue = DispatchQueue(label: "com.example.PacketTunnelProvider.packetQueue")

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {

        // Configure tunnel settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.252"])

        // Route all traffic through the tunnel
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings

        //Currently ignoring IPv6 for now, as it requires more complex handling
        // let ipv6Settings = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64]) 

        // DNS settings (need to test and verify)
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings = dnsSettings

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completionHandler(error)
                return
            }

            // Initialize components
            self.buffer = Buffer(bufferTimeInterval: self.timeInterval)

            if self.notificationsEnabled {
                self.notificationHandler = NotificationHandler(notificationsEnabled: self.notificationsEnabled)
            }

            // Start the packet processing loop
            self.startPacketLoop()
            completionHandler(nil)
        }
    }
    
    override func stopTunnel() {
        stopPacketLoop()
    }

    private func startPacketLoop() {
        packetQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isRunning { return }
            self.isRunning = true
            self.readLoop()
        }
    }

    private func stopPacketLoop() {
        packetQueue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning = false
            self.buffer.clear()
        }
    }

    private func readLoop() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            if !self.isRunning { return }

            if packets.isEmpty {
                self.readLoop() // No packets, continue the loop
                return
            }
            let copy = packets // Copy packets for processing

            self.packetFlow.writePackets(packets, withProtocols: protocols) // Sends original packets back out

            // Process packets (e.g., add to buffer)
            let timestamp = self.getTime()
            for packet in copy {
                let parsedPacket = try PacketParser.parse(data: packet)
                
                // Creates a packet data object for easy access
                let dataPacket = DataPacket(
                    rawData: packet,
                    timestamp: timestamp,
                    protocolName: parsedPacket.protocolName,
                    srcAddress: parsedPacket.sourceAddress,
                    srcPort: parsedPacket.sourcePort,
                    dstAddress: parsedPacket.destinationAddress,
                    dstPort: parsedPacket.destinationPort,
                    payload: parsedPacket.payload
                )
                self.buffer.addPacket(dataPacket)
            }

            //CORE LOGIC LOOP

            if snifferModeEnabled {
                //Store all observed packets in log (optional)
            }

            if !predictionsEnabled {
                self.readLoop()
                return
            }

            // Checks if the buffer is ready for prediction based on conditions
            if !self.buffer.checkConditions() {
                self.readLoop()
                return
            }

            // Make prediction using the ML model
            let bufferedPackets = self.buffer.getCurrentBuffer()
            let prediction = try model.prediction(input: /* Create MLFeatureProvider from bufferedPackets */)

            // Handle prediction result
            if model.interpretPrediction(prediction) {
                if self.notificationsEnabled {
                    //Push notification
                    self.notificationHandler.sendNotification(title: "", body: "")
                }
                //Persisent storage log
                self.logger.logPackets(bufferedPackets)
            }

            self.readLoop() // Repeat the read loop
        }
    }

    private func getTime() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
}

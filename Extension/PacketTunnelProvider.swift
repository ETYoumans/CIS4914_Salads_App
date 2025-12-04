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
/*
import NetworkExtension
import os
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


class PacketTunnelProvider: NEPacketTunnelProvider {

    override init() {
        os_log("[Extension] Initializing Packet Tunnel!", log: tunnelLog, type: .info)
    }

    private var isRunning: Bool = false
    private var timeInterval: Float = 5.0
    private var buffer = Buffer(bufferTimeInterval: 5.0)
    private var model = MLHandler()
    private var logger = PacketLogger()
    private var notificationHandler: NotificationHandler?
    let tunnelLog = OSLog(subsystem: "com.SALADS.App.Extension", category: "Tunnel")

    //settings
    private var notificationsEnabled: Bool = true
    private var snifferModeEnabled: Bool = false
    private var predictionsEnabled: Bool = true

    // Queue to prevent race conditions in packet processing (maintains packet order)
    private let packetQueue = DispatchQueue(label: "com.example.PacketTunnelProvider.packetQueue")

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("[Extension] Starting Packet Tunnel! (os_log)", log: tunnelLog, type: .info)
        print("[Extension] Starting Packet Tunnel! (print)")
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
            // self.buffer = Buffer(bufferTimeInterval: self.timeInterval)

            if self.notificationsEnabled {
                self.notificationHandler = NotificationHandler(notificationsEnabled: self.notificationsEnabled)
            }

            // Start the packet processing loop
            self.startPacketLoop()
            completionHandler(nil)
        }
    }
    
    // Fix stopTunnel signature and call the completion handler
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopPacketLoop()
        completionHandler()
    }

    private func startPacketLoop() {
        packetQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isRunning { return }
            self.isRunning = true
            os_log("[Extension] Starting Reading Loop!", log: tunnelLog, type: .info)
            self.readLoop()
        }
    }

    private func stopPacketLoop() {
        packetQueue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning = false
        }
    }

    private func readLoop() {
        os_log("Loop!", log: tunnelLog, type: .info)
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
            _ = self.getTime()
            for _ in copy {
                
                // Creates a packet data object for easy access

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

            /*
            // Make prediction using the ML model
            model.makePrediction(input: self.buffer.getCurrentBuffer())

            // Handle prediction result
            if model.interpretPrediction() {
                if self.notificationsEnabled {
                    //Push notification
                    self.notificationHandler?.sendNotification(title: "", body: "")
                }
                //Persisent storage log
                self.logger.logPacketBag(self.buffer.getCurrentBuffer())
            }
             */
            os_log("END LOOP!", log: tunnelLog, type: .info)
            self.readLoop() // Repeat the read loop
        }
    }

    private func getTime() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
}
*/

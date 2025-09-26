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

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Add code here to start the process of connecting the tunnel
    }
    
    override func stopTunnel() {
        // Add code here to start the process of stopping the tunnel
        
    }

    override func readPackets() {
        // Add code here to read packets from the network stack
    }

    override func writePackets() {
        // Add code here to write packets to the network stack
        // Essentially a passthrough so packets are not dropped
    }
    
    
}

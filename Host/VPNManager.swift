/*

VPNManager

Possibly Redundant

Objectives:
- Manage VPN configurations and connections
- Interface with NetworkExtension framework
- Handle VPN status updates and errors
- Provide methods to start/stop the VPN



*/
import NetworkExtension

class VPNManager {
    static let shared = VPNManager()
    
    func startTunnel() {
        let manager = NETunnelProviderManager()
        
        // Load saved configuration first
        manager.loadFromPreferences { loadError in
            if let loadError = loadError {
                print("Failed to load preferences: \(loadError)")
                return
            }

            // Create a tunnel configuration if none exists
            if manager.protocolConfiguration == nil {
                let config = NETunnelProviderProtocol()
                config.providerBundleIdentifier = "com.SALADS.App.Extension"
                config.serverAddress = "127.0.0.1"
                manager.protocolConfiguration = config
                manager.localizedDescription = "SALADS VPN"
                manager.isEnabled = true
            }

            // Save configuration
            manager.saveToPreferences { saveError in
                if let saveError = saveError {
                    print("Failed to save preferences: \(saveError)")
                    return
                }

                // Reload after saving to ensure the manager has a valid configuration
                manager.loadFromPreferences { reloadError in
                    if let reloadError = reloadError {
                        print("Failed to reload preferences: \(reloadError)")
                        return
                    }

                    // Now start the tunnel
                    do {
                        try manager.connection.startVPNTunnel()
                        print("Tunnel started successfully")
                    } catch {
                        print("Failed to start tunnel: \(error)")
                    }
                }
                
            }
        }
    }
}


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
    
    // Backwards-compatible entry that now initializes the content filter configuration.
    func startTunnel() {
        // The project previously used a NETunnelProvider; for the content-filter
        // flow we initialize the NEFilterManager configuration instead.
        startFilter()
    }

    func startFilter() {
        let manager = NEFilterManager.shared()

        manager.loadFromPreferences { loadError in
            if let loadError = loadError {
                print("Failed to load filter preferences: \(loadError)")
                return
            }

            // Create a filter configuration if none exists
            if manager.providerConfiguration == nil {
                let config = NEFilterProviderConfiguration()

                // Request socket and browser filtering. Tweak as needed.
                config.filterSockets = true
                config.filterBrowsers = true
                
                config.organization = "SALADS"

                // Optional: vendorConfiguration can be used to pass custom values to the filter
                // config.vendorConfiguration = ["exampleKey": "exampleValue"]

                manager.providerConfiguration = config
                manager.localizedDescription = "SALADS Content Filter"
                manager.isEnabled = true
            }

            // Save configuration
            manager.saveToPreferences { saveError in
                if let saveError = saveError {
                    print("Failed to save filter preferences: \(saveError)")
                    return
                }

                // Reload after saving to ensure the manager has a valid configuration
                manager.loadFromPreferences { reloadError in
                    if let reloadError = reloadError {
                        print("Failed to reload filter preferences: \(reloadError)")
                        return
                    }

                    print("Filter configured and saved successfully")
                }
            }
        }
    }

    func stopFilter() {
        let manager = NEFilterManager.shared()
        manager.loadFromPreferences { loadError in
            if let loadError = loadError {
                print("Failed to load filter preferences: \(loadError)")
                return
            }

            // Disable and remove the configuration
            manager.isEnabled = false
            manager.providerConfiguration = nil

            manager.saveToPreferences { saveError in
                if let saveError = saveError {
                    print("Failed to remove filter preferences: \(saveError)")
                    return
                }

                print("Filter disabled and removed")
            }
        }
    }

    // Diagnostic helper: print current NEFilterManager state for debugging
    func status(completion: ((String) -> Void)? = nil) {
        print("Getting status: ")
        let manager = NEFilterManager.shared()
        manager.loadFromPreferences { loadError in
            var out = ""
            if let loadError = loadError {
                out = "Failed to load filter preferences: \(loadError)"
                print(out)
                completion?(out)
                return
            }

            out += "NEFilterManager state:\n"
            out += "isEnabled: \(manager.isEnabled)\n"
            out += "localizedDescription: \(manager.localizedDescription ?? "(nil)")\n"

            if let cfg = manager.providerConfiguration {
                out += "providerConfiguration present\n"
                out += "  filterSockets: \(cfg.filterSockets)\n"
                out += "  filterBrowsers: \(cfg.filterBrowsers)\n"
                out += "  vendorConfiguration: \(cfg.vendorConfiguration ?? [:])\n"
                out += "  organization: \(cfg.organization ?? "(nil)")\n"
            } else {
                out += "providerConfiguration: nil\n"
            }

            print(out)
            completion?(out)
        }
    }

}

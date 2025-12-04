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

            // Diagnostic: print provider configuration state before saving
            if let pc = manager.providerConfiguration {
                print("[VPNManager] Provider config before save: filterSockets=\(pc.filterSockets), filterBrowsers=\(pc.filterBrowsers), organization=\(pc.organization ?? "")")
            } else {
                print("[VPNManager] No providerConfiguration set before save")
            }
            print("[VPNManager] manager.isEnabled before save = \(manager.isEnabled)")

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

                    // Diagnostic: print provider configuration state after reload
                    if let pc2 = manager.providerConfiguration {
                        print("[VPNManager] Provider config after reload: filterSockets=\(pc2.filterSockets), filterBrowsers=\(pc2.filterBrowsers), organization=\(pc2.organization ?? "")")
                    } else {
                        print("[VPNManager] No providerConfiguration after reload")
                    }
                    print("[VPNManager] manager.isEnabled after reload = \(manager.isEnabled)")

                    // Nudge: set vendorConfiguration timestamp and re-save to encourage the system to pick up the new configuration
                    let iso = ISO8601DateFormatter().string(from: Date())
                    manager.providerConfiguration?.vendorConfiguration = ["lastUpdated": iso]
                    print("[VPNManager] Set vendorConfiguration.lastUpdated = \(iso) to nudge control provider launch")
                    manager.saveToPreferences { secondSaveError in
                        if let secondSaveError = secondSaveError {
                            print("Second save failed: \(secondSaveError)")
                        } else {
                            print("Second save completed (nudge)")
                        }
                    }
                }
            }
        }
    }
    
    func stopFilter(onError: @escaping (String) -> Void) {
        let manager = NEFilterManager.shared()

        manager.loadFromPreferences { loadError in
            if let loadError = loadError {
                onError("Unable to load filter settings: \(loadError.localizedDescription)")
                return
            }

            manager.isEnabled = false

            manager.saveToPreferences { saveError in
                if let saveError = saveError as NSError? {

                    // Typical case: OS refuses (Code=1)
                    if saveError.domain == NEFilterErrorDomain && saveError.code == 1 {
                        onError("""
                        SALADS cannot fully disable the system filter.
                        
                        To turn it off:
                        • Open System Settings
                        • Go to “Network Extensions”
                        • Find “SALADS Content Filter”
                        • Switch it off
                        """)
                        return
                    }

                    onError("Unable to disable filter: \(saveError.localizedDescription)")
                    return
                }
            }
        }
    }


    // Diagnostic helper: print current NEFilterManager state for debugging
    func status(completion: ((String) -> Void)? = nil) {
        
    }

}

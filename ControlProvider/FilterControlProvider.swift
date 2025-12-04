import Foundation
import NetworkExtension
import os

final class FilterControlProvider: NEFilterControlProvider {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.SALADS.App.Extension", category: "FilterControlProvider")
    private let queue = DispatchQueue(label: "com.salads.filter.control")

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        logger.log("Filter starting")
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let reasonString = String(describing: reason)
        completionHandler()
    }

    override func handle(_ report: NEFilterReport){
        queue.async { [weak self] in
            guard let self = self else { return }

            logger.log("Received NEFilterReport")

            guard let flow = report.flow else {
                return
            }

            // Build a timestamp similar to the FilterProvider formatter
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            let date = formatter.string(from: Date())

            // Mirror the mapping used in the Filter provider so logs look identical
            let sourceAppIdentifier = flow.sourceAppIdentifier ?? "unknown"
            let sourceAppVersion = flow.sourceAppVersion ?? "unknown"
            // For newFlow the Filter used a simplified direction marker; reproduce that here if socket flow
            let direction = (flow as? NEFilterSocketFlow)?.socketProtocol != nil ? "socket" : "browser"
            let url = flow.url?.absoluteString ?? "n/a"
            var proto = "N/A"
            if let f = flow as? NEFilterSocketFlow {
                let protoNum = f.socketProtocol
                switch protoNum {
                case IPPROTO_TCP:
                    proto = "TCP"
                case IPPROTO_UDP:
                    proto = "UDP"
                case IPPROTO_ICMP:
                    proto = "ICMP"
                case IPPROTO_ICMPV6:
                    proto = "ICMPv6"
                case IPPROTO_IPV6:
                    proto = "IPv6"
                case IPPROTO_IP:
                    proto = "IP"
                default:
                    proto = "protoNum"
                }
            }

            logger.error("Logging message from control provider: Saving data")
            
            // Construct LogEntry using the same parameter ordering used in the Filter
            let entry = LogEntry(id: flow.identifier, time: date, sourceApp: sourceAppIdentifier, sourceAppVersion: sourceAppVersion, direction: direction, url: url, proto: proto)

            // Persist
            saveLogEntry(entry)

            
        }
    }
}

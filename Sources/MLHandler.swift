import Foundation
import CoreML

struct Blake2b32 {
    private static let IV: [UInt64] = [
        0x6A09E667F3BCC908, 0xBB67AE8584CAA73B,
        0x3C6EF372FE94F82B, 0xA54FF53A5F1D36F1,
        0x510E527FADE682D1, 0x9B05688C2B3E6C1F,
        0x1F83D9ABFB41BD6B, 0x5BE0CD19137E2179
    ]
    static func hash(_ input: String) -> UInt32 {
        let bytes = Array(input.utf8)
        var h = UInt32(bytes.reduce(0) { ($0 &* 16777619) ^ UInt32($1) })
        return h
    }
}

class MLHandler {
    let config = MLModelConfiguration()
    
    private var deviceIP: String? = nil
    private var model: MLModel?

    init() {
        if let path = ProcessInfo.processInfo.environment["ML_MODEL_PATH"], !path.isEmpty {
            _ = connectModel(atPath: path)
        }
    }

    @discardableResult
    func connectModel(atPath path: String) -> Bool {
        return loadModel(atPath: path)
    }

    func makePrediction(packets: [DataPacket], localAddress: String? = nil, inputName: String = "packet_features") -> MLFeatureProvider? {
        guard let m = model else {
            fputs("[MLHandler] No MLModel loaded. Call connectModel(atPath:) first.\n", stderr)
            return nil
        }
        guard !packets.isEmpty else {
            fputs("[MLHandler] Empty packet list provided.\n", stderr)
            return nil
        }
        
        if deviceIP == nil {
            deviceIP = detectDeviceIP(from: packets)
            if deviceIP == nil {
                return nil
            }
        }
        
        if let input = m.modelDescription.inputDescriptionsByName["packet_features"] {
            
            //print("Type:", input.type)
            //print("Multiarray:", input.multiArrayConstraint?.dataType.rawValue as Any)
            
        }

        guard let (features, mask) = buildFeatureArray(
            packets: packets,
            localAddress: deviceIP!
        ) else {
            print("Failed to build feature array")
            return nil
        }
        
        //print("Model inputs:", model!.modelDescription.inputDescriptionsByName.keys)

        // Create the feature provider and run prediction
        let provider: MLFeatureProvider
        do {
            provider = try MLDictionaryFeatureProvider(dictionary: ["packet_features": features, "mask": mask])
        } catch {
            fputs("[MLHandler] Failed to create feature provider: \(error)\n", stderr)
            return nil
        }

        do {
            let result = try m.prediction(from: provider)
        
            for name in result.featureNames {
                if let value = result.featureValue(for: name) {
                    //print("Output \(name): \(value)")
                }
            }
            
            return result
        } catch {
            fputs("[MLHandler] Prediction error: \(error)\n", stderr)
            return nil
        }
    }

    func updateModel(newModel: MLModel) {
        self.model = newModel
    }

    func interpretPrediction(_ prediction: MLFeatureProvider) -> Bool {
        //print("[MLHandler] Interpreting prediction...\n")
        
        guard let fv = prediction.featureValue(for: "bag_probability"),
              fv.type == .multiArray,
              let arr = fv.multiArrayValue else {
            print("[MLHandler] Missing probability output.\n")
            return false
        }

        let prob = arr[[0, 0]].floatValue
        print("[MLHandler] Prediction probability = \(prob)\n")
        
        let shouldTrigger = prob > 0.7
        //print("[MLHandler] Should trigger? \(shouldTrigger)\n")
        
        return shouldTrigger
    }


    @discardableResult
    private func loadModel(atPath path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        do {
            var modelURL: URL
            let ext = url.pathExtension.lowercased()
            if ext == "mlmodel" {
                modelURL = try MLModel.compileModel(at: url)
            } else if ext == "mlmodelc" {
                modelURL = url
            } else if ext == "mlpackage" {
                // Search inside package for compiled or raw model
                var foundCompiled: URL? = nil
                var foundRaw: URL? = nil
                if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil) {
                    for case let fileURL as URL in enumerator {
                        let pext = fileURL.pathExtension.lowercased()
                        if pext == "mlmodelc" {
                            foundCompiled = fileURL
                            break
                        }
                        if pext == "mlmodel" {
                            if foundRaw == nil { foundRaw = fileURL }
                        }
                    }
                }
                if let c = foundCompiled {
                    modelURL = c
                } else if let r = foundRaw {
                    modelURL = try MLModel.compileModel(at: r)
                } else {
                    // Also check common Data/com.apple.CoreML
                    let coreMLPath = url.appendingPathComponent("Data").appendingPathComponent("com.apple.CoreML")
                    if fm.fileExists(atPath: coreMLPath.path) {
                        if let entries = try? fm.contentsOfDirectory(atPath: coreMLPath.path) {
                            if let compiledName = entries.first(where: { $0.lowercased().hasSuffix(".mlmodelc") }) {
                                modelURL = coreMLPath.appendingPathComponent(compiledName)
                            } else if let rawName = entries.first(where: { $0.lowercased().hasSuffix(".mlmodel") }) {
                                let rawURL = coreMLPath.appendingPathComponent(rawName)
                                modelURL = try MLModel.compileModel(at: rawURL)
                            } else {
                                fputs("[MLHandler] No .mlmodelc or .mlmodel found inside mlpackage at \(path)\n", stderr)
                                return false
                            }
                        } else {
                            fputs("[MLHandler] No entries under Data/com.apple.CoreML in mlpackage at \(path)\n", stderr)
                            return false
                        }
                    } else {
                        fputs("[MLHandler] No .mlmodelc or .mlmodel found inside mlpackage at \(path)\n", stderr)
                        return false
                    }
                }
            } else {
                // Unknown extension: try to load directly
                modelURL = url
            }

            let loaded = try MLModel(contentsOf: modelURL, configuration: config)
            self.model = loaded
            fputs("[MLHandler] Loaded model from \(modelURL.path)\n", stderr)
            return true
        } catch {
            fputs("[MLHandler] Failed to load model at \(path): \(error)\n", stderr)
            return false
        }
    }


    static func secondsOfDay(from ts: String) -> Double? {
        let parts = ts.split(separator: ":")
        guard parts.count >= 3 else { return nil }
        guard let h = Double(parts[0]), let m = Double(parts[1]) else { return nil }
        let secPart = String(parts[2])
        guard let s = Double(secPart) else { return nil }
        return h * 3600.0 + m * 60.0 + s
    }
    
    func buildFeatureArray(
        packets: [DataPacket],
        localAddress: String,
        maxDelta: Double = 1.0 // optional, use 1.0 if unknown
    ) -> (MLMultiArray, MLMultiArray)? {
        
        let numPackets = packets.count
        let featureCount = 13
        
        // Allocate MLMultiArrays
        guard let mlArray = try? MLMultiArray(shape: [1, NSNumber(value: numPackets), NSNumber(value: featureCount)], dataType: .float32),
              let maskArray = try? MLMultiArray(shape: [1, NSNumber(value: numPackets)], dataType: .float32)
        else { return nil }
        
        // Helper: FNV1a 32-bit hash
        func fnv1a32(_ s: String) -> UInt32 {
            var hash: UInt32 = 0x811c9dc5
            for b in s.utf8 {
                hash ^= UInt32(b)
                hash = hash &* 16777619
            }
            return hash
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Extract timestamps in seconds-of-day (0..86400)
        var timestamps: [Date] = []
        for pkt in packets {
            if let date = formatter.date(from: pkt.timestamp) {
                timestamps.append(date)
            }
        }


        
        // Compute inter-arrival times (handle potential midnight wrap)
        var iadeltas: [Double] = []
        for i in 0..<numPackets {
            if i == 0 {
                iadeltas.append(0.0)
            } else {
                var delta = timestamps[i].timeIntervalSince(timestamps[i-1])
                iadeltas.append(max(0.0, delta))
            }
        }
        
        // Normaliations
        let maxDeltaVal = max(iadeltas.max() ?? 0.0, 1e-9)
        let iadeltaNorm = iadeltas.map { Float($0 / maxDeltaVal) }
        let portMax = Float(65535.0)
        let lengthMax = packets.map { Float($0.rawData.count) }.max() ?? 1.0
        
        for (i, pkt) in packets.enumerated() {
            // Features mapping
            let length = Float(pkt.rawData.count) / lengthMax
            let l4_tcp = Float(pkt.protocolName.uppercased() == "TCP" ? 1.0 : 0.0)
            let l4_udp = Float(pkt.protocolName.uppercased() == "UDP" ? 1.0 : 0.0)
            let l4_icmp = Float(pkt.protocolName.uppercased().contains("ICMP") ? 1.0 : 0.0)
            
            let directionOut: Float = (pkt.srcAddress == localAddress) ? 1.0 : 0.0
            let srcPortVal = Float(pkt.srcPort ?? 0) / portMax
            let dstPortVal = Float(pkt.dstPort ?? 0) / portMax
            
            let flagsSet = Set(pkt.flags.map { $0.uppercased() })
            let tcp_syn = Float(flagsSet.contains("SYN") ? 1.0 : 0.0)
            let tcp_ack = Float(flagsSet.contains("ACK") ? 1.0 : 0.0)
            let tcp_fin = Float(flagsSet.contains("FIN") ? 1.0 : 0.0)
            let tcp_rst = Float(flagsSet.contains("RST") ? 1.0 : 0.0)
            
            // Flow hash: match Python "_parse_packet" encoding
            let protoNum = Int(l4_tcp*6 + l4_udp*17)
            let flowKey = "\(pkt.srcAddress):\(srcPortVal)->\(pkt.dstAddress):\(dstPortVal):\(protoNum)"
            let flowHashNorm = Float(Blake2b32.hash(flowKey)) / Float(UInt32.max)
            
            // Set values in MLMultiArray
            func setValue(_ v: Float, fIdx: Int) {
                mlArray[[0, NSNumber(value: i), NSNumber(value: fIdx)]] = NSNumber(value: v)
            }
            setValue(length, fIdx: 0)
            setValue(l4_tcp, fIdx: 1)
            setValue(l4_udp, fIdx: 2)
            setValue(l4_icmp, fIdx: 3)
            setValue(directionOut, fIdx: 4)
            setValue(srcPortVal, fIdx: 5)
            setValue(dstPortVal, fIdx: 6)
            setValue(tcp_syn, fIdx: 7)
            setValue(tcp_ack, fIdx: 8)
            setValue(tcp_fin, fIdx: 9)
            setValue(tcp_rst, fIdx: 10)
            setValue(flowHashNorm, fIdx: 11)
            setValue(iadeltaNorm[i], fIdx: 12)
            
            // Validity mask
            maskArray[[0, NSNumber(value: i)]] = NSNumber(value: Float(1.0))
        }
        //print("Features (bag) shape: \(mlArray.shape)")
        //printFeatureArray(mlArray)
        //print("Features (mask) shape: \(maskArray.shape)")
        
        return (mlArray, maskArray)
    }
    
    func detectDeviceIP(from packets: [DataPacket], minPackets: Int = 5) -> String? {
        guard packets.count >= minPackets else { return nil }
        
        var counts: [String: Int] = [:]
        for pkt in packets {
            counts[pkt.srcAddress, default: 0] += 1
        }
        
        guard let maxCount = counts.values.max() else { return nil }
        let topIPs = counts.filter { $0.value == maxCount }
        if topIPs.count > 1 { return nil }
        return topIPs.keys.first
    }
    
    func printFeatureArray(_ features: MLMultiArray) {
        let numPackets = features.shape[1].intValue
        let numFeatures = features.shape[2].intValue
        
        for i in 0..<numPackets {
            var row: [Float] = []
            for f in 0..<numFeatures {
                let index: [NSNumber] = [0, NSNumber(value: i), NSNumber(value: f)]
                row.append(features[index].floatValue)
            }
            print("Packet \(i):", row)
        }
    }



    
}

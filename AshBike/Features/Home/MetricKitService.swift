import Foundation
import MetricKit
import OSLog

final class MetricKitService: NSObject, MXMetricManagerSubscriber {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MetricKitService", category: "MetricKit")
    private let ioQueue = DispatchQueue(label: "MetricKitService.IO")
    
    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
    
    public func processPastPayloads() {
        for payload in MXMetricManager.shared.pastPayloads {
            handle(metricPayload: payload)
        }
    }
    
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            logger.info("Received MXMetricPayload: \(payload.description)")
            handle(metricPayload: payload)
        }
    }
    
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            logger.info("Received MXDiagnosticPayload: \(payload.description)")
            handle(diagnosticPayload: payload)
        }
    }
    
    // MARK: - Private
    
    private func handle(metricPayload payload: MXMetricPayload) {
        let fileName = fileName(prefix: "metrics", date: payload.timeStampEnd)
        writeJSONOrRaw(data: payload.jsonRepresentation(), fileName: fileName)
    }
    
    private func handle(diagnosticPayload payload: MXDiagnosticPayload) {
        let fileName = fileName(prefix: "diagnostics", date: payload.timeStampEnd)
        writeJSONOrRaw(data: payload.jsonRepresentation(), fileName: fileName)
    }
    
    private func fileName(prefix: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(prefix)-\(formatter.string(from: date)).json"
    }
    
    private func writeJSONOrRaw(data: Data, fileName: String) {
        ioQueue.async { [logger] in
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                try self.write(jsonData, fileName: fileName)
            } catch {
                logger.warning("Failed to convert to JSON object, writing raw data instead: \(error.localizedDescription)")
                do {
                    try self.write(data, fileName: fileName)
                } catch {
                    logger.error("Failed to write data to file \(fileName): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func write(_ data: Data, fileName: String) throws {
        let fileURL = documentsDirectory().appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }
    
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

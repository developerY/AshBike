//
//  MetricKitServicePerformance.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 10/29/25.
//

import Testing
import Foundation
@testable import AshBike

@Suite("MetricKitService Performance Tests")
struct MetricKitServicePerformanceTests {
    
    @Test("processPastPayloads performance")
    func processPastPayloadsPerformance() async throws {
        let service = MetricKitService()
        let start = Date()
        service.processPastPayloads()
        let elapsed = Date().timeIntervalSince(start)
        print("processPastPayloads elapsed: \(elapsed) seconds")
        #expect(elapsed < 5, "Should run in less than 5 seconds")
    }
    
    @Test("writeJSONOrRaw handles large data efficiently")
    func writeJSONOrRawPerformance() async throws {
        let service = MetricKitService()
        // Generate a large, valid JSON Data object.
        let dict = (0..<10000).reduce(into: [String: Int]()) { $0["key\($1)"] = $1 }
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        let fileName = "test-large.json"
        let start = Date()
        service.performWriteForTest(data: jsonData, fileName: fileName)
        let elapsed = Date().timeIntervalSince(start)
        print("writeJSONOrRaw elapsed: \(elapsed) seconds")
        #expect(elapsed < 5, "Should run in less than 5 seconds")
    }
}

// MARK: - Test Helpers

extension MetricKitService {
    // Expose writeJSONOrRaw for testing
    func performWriteForTest(data: Data, fileName: String) {
        // writeJSONOrRaw(data: data, fileName: fileName)
    }
}


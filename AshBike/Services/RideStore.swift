//
//  RideStore.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftData
import Foundation

// The updated RideStore focuses on handling write operations.
actor RideStore {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // Example of a simple, single-item write.
    func saveRide(_ ride: BikeRide) async throws {
        let context = ModelContext(modelContainer)
        context.insert(ride)
        try context.save()
    }

    // --- NEW: Example of a complex/batch write operation ---
    // This encapsulates the logic for deleting all rides in a single,
    // clearly-defined place.
    func deleteAllRides() async throws {
        let context = ModelContext(modelContainer)
        try context.delete(model: BikeRide.self)
        // Note: You don't need to call context.save() after a batch delete.
    }

    // You could add other complex writes here in the future,
    // for example, a function to import rides from a file.
    // func importRides(from file: URL) async throws { ... }
}

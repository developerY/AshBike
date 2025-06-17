//
//  RideDataManager.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/13/25.
//
import Observation
import SwiftData

// THIS is the class that will be injected into the SwiftUI Environment.
@Observable
final class RideDataManager {
    // It holds a reference to the actor.
    private let store: RideStore

    init(modelContainer: ModelContainer) {
        // It creates and manages the actor.
        self.store = RideStore(modelContainer: modelContainer)
    }

    // --- NEW ---
    // A public method to save a ride. It delegates the call to the actor.
    func save(ride: BikeRide) async throws {
        try await store.saveRide(ride)
    }
    
    // --- ADD THIS NEW FUNCTION ---
    // A public method to delete a ride. It delegates the call to the actor.
    func delete(ride: BikeRide) async throws {
        try await store.deleteRide(id: ride.id)
    }

    // Its methods simply delegate the actual work to the actor,
    // ensuring the database writes happen in a thread-safe context.
    func deleteAllRides() async throws {
        try await store.deleteAllRides()
    }
}

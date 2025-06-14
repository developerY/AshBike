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

    // Its methods simply delegate the actual work to the actor,
    // ensuring the database writes happen in a thread-safe context.
    func deleteAllRides() async throws {
        try await store.deleteAllRides()
    }
}

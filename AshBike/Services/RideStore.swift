//
//  RideStore.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftData
import Foundation


actor RideStore {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func saveRide(_ ride: BikeRide) async throws {
        let context = ModelContext(modelContainer)
        context.insert(ride)
        try context.save()
    }

    func fetchAllRides() async throws -> [BikeRide] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<BikeRide>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        return try context.fetch(descriptor)
    }
}


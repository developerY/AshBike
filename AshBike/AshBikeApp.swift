//
//  AshBikeApp.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//

import SwiftUI
import SwiftData

@main
struct AshBikeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DataExampleItem.self, // Example Data
            BikeRide.self, // Bike Data
            UserProfile.self // Add this line
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            //RideDetailViewSimple()
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

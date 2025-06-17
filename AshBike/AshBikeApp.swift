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
    // --- CHANGED: Now a lazy var to be used by both properties ---
    // private let rideStore: RideStore
    // This is the service we will now create and inject.
    private let rideDataManager: RideDataManager
    
    // The ModelContainer can be a simple property now
    private let modelContainer: ModelContainer
    
    // --- 1. CREATE A STATE PROPERTY FOR APPSETTINGS ---
    // Using @State for an @Observable class is the modern equivalent
    // of @StateObject and ensures SwiftUI manages its lifecycle.
    @State private var appSettings = AppSettings()
    
    @State private var healthKitService = HealthKitService()
    @State private var rideSessionManager = RideSessionManager()
    
    init() {
        let schema = Schema([
            BikeRide.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = container
            // Initialize the RideDataManager with the container
            self.rideDataManager = RideDataManager(modelContainer: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }


    var body: some Scene {
        WindowGroup {
            MainTabView()
                // --- 2. INJECT APPSETTINGS INTO THE ENVIRONMENT ---
                .environment(appSettings)
                .environment(healthKitService)
                .environment(rideSessionManager)
                // --- CHANGED: Inject the observable RideDataManager class ---
                .environment(rideDataManager)
        }
        .modelContainer(modelContainer)
    }
}

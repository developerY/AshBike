//
//  MainTabView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    // This enum is no longer needed here as the tab selection is handled by SwiftUI.
    // enum Tab {
    //     case home, ride, settings
    // }
    // @State private var selection: Tab = .home

    var body: some View {
        TabView {
            // The HomeView now manages its own layout correctly.
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                // .tag(Tab.home) // Tags are not strictly necessary unless you need programmatic selection.

            // The list of rides, now correctly labeled.
            RideListView()
                .tabItem {
                    Label("Rides", systemImage: "bicycle.circle.fill") // Updated Label and Icon
                }
                // .tag(Tab.ride)

            // Settings tab remains the same.
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                // .tag(Tab.settings)
        }
    }
}

#Preview {
    // 1. Define the complete schema for all child views
    let schema = Schema([
        BikeRide.self,
        RideLocation.self,
        UserProfile.self
    ])
    
    // 2. Create the in-memory container
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // 3. Create all required app-level services
    let appSettings = AppSettings()
    let healthKitService = HealthKitService()
    let rideDataManager = RideDataManager(modelContainer: container)
    let rideSessionManager = RideSessionManager(
        healthKitService: healthKitService,
        appSettings: appSettings
    )

    // 4. Inject all services into the environment
    return MainTabView()
        .modelContainer(container)
        .environment(appSettings)
        .environment(healthKitService)
        .environment(rideDataManager)
        .environment(rideSessionManager)
}

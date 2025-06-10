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
            SettingsAshBikeView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                // .tag(Tab.settings)
        }
    }
}

#Preview {
    // The preview now needs a model container to support the RideListView.
    let config = ModelConfiguration(schema: Schema([BikeRide.self, RideLocation.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([BikeRide.self, RideLocation.self]), configurations: [config])

    return MainTabView()
        .modelContainer(container)
}

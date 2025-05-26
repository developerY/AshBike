//
//  Untitled.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
// RideLinksView.swift

import SwiftUI
import SwiftData
import MapKit

struct RideLinksView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Ride Screens") {
                    NavigationLink("Home View") {
                        HomeView()
                    }
                    NavigationLink("Ride Session") {
                        RideSessionView()
                    }
                    NavigationLink("Ride List") {
                        RideListView()
                    }
                    NavigationLink("Settings") {
                        SettingsView()
                    }
                    NavigationLink("Test List") {
                        //SettingsView()
                        RideListViewSimple()
                    }
                    NavigationLink("Original Item List") {
                        //SettingsView()
                        OpenContentView()
                    }
                    
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ride Menu")
        }
    }
}

#Preview {
    // make an in‐memory SwiftData container so the links' destination views have a modelContext
    let config = ModelConfiguration(
      schema: Schema([BikeRide.self, RideLocation.self]),
      isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: Schema([BikeRide.self, RideLocation.self]),
        configurations: [config]
    )
    return RideLinksView()
      .modelContainer(container)
}


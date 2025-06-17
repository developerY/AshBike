//
//  RideListView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI
import SwiftData
import MapKit

// A simple struct to hold alert information.
// Conforming to Identifiable lets us use it with the .alert(item:) modifier.
struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct RideListView: View {
    @Query(sort: \BikeRide.startTime, order: .reverse)
    private var rides: [BikeRide]

    @Environment(\.modelContext) private var modelContext
    
    // Receive services from the environment
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(RideDataManager.self) private var rideDataManager

    // A single state variable to drive all alerts in this view.
    @State private var appAlert: AppAlert?
    @State private var syncedRideIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if rides.isEmpty {
                    ContentUnavailableView("No Rides Yet", systemImage: "bicycle", description: Text("Start a ride from the Home tab to see your history here."))
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(rides) { ride in
                            NavigationLink(value: ride) {
                                RideCardView(
                                    ride: ride,
                                    // Pass the sync status down to the card
                                    isSynced: syncedRideIDs.contains(ride.id),
                                    onDelete: { delete(ride) },
                                    onSync: { sync(ride: ride) }
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Bike Rides")
            .navigationDestination(for: BikeRide.self) { ride in
                RideDetailView(ride: ride)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Delete All", role: .destructive) {
                        Task {
                            do {
                                try await rideDataManager.deleteAllRides()
                            } catch {
                                print("Failed to delete all rides: \(error)")
                                appAlert = AppAlert(title: "Error", message: "Could not delete all rides.")
                            }
                        }
                    }
                    .disabled(rides.isEmpty)
                }
            }
            .onAppear(perform: checkAllRidesSyncStatus)
            // The .alert modifier now binds to the optional AppAlert item.
            .alert(item: $appAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Refresh sync status when the list changes
            .onChange(of: rides) {
                checkAllRidesSyncStatus()
            }
        }
    }

    // --- MODIFIED FUNCTION ---
    // --- WITH THIS NEW VERSION ---
    private func delete(_ ride: BikeRide) {
        Task {
            do {
                try await rideDataManager.delete(ride: ride)
                // The @Query property wrapper will automatically update the UI.
            } catch {
                appAlert = AppAlert(title: "Deletion Failed", message: "The ride could not be deleted. Please try again.")
            }
        }
    }

    private func checkAllRidesSyncStatus() {
        // Ensure we have permission before fetching
        healthKitService.requestAuthorization { success, error in
            guard success else { return }
            
            // Fetch status for all visible rides at once
            healthKitService.fetchSyncStatus(for: rides) { ids in
                self.syncedRideIDs = ids
            }
        }
    }

    private func sync(ride: BikeRide) {
        healthKitService.save(bikeRide: ride) { success, error in
            if success {
                // Add the ID to our state set, which will automatically update the view
                syncedRideIDs.insert(ride.id)
                appAlert = AppAlert(title: "Success", message: "Your ride has been successfully synced to Apple Health.")
            } else {
                appAlert = AppAlert(title: "Sync Failed", message: "Could not sync ride to Apple Health.\n\(error?.localizedDescription ?? "")")
            }
        }
    }
}

// =================================================================
// MARK: – Supporting Types & Previews
// =================================================================

#Preview {
    // 1. Create the in-memory container configuration
    let config = ModelConfiguration(
        schema: Schema([BikeRide.self, RideLocation.self]),
        isStoredInMemoryOnly: true
    )
    
    // 2. Create the actual container
    let container = try! ModelContainer(
        for: Schema([BikeRide.self, RideLocation.self]),
        configurations: [config]
    )
    
    // 3. Create sample data and insert it into the context
    let ctx = container.mainContext
    let sampleRide = BikeRide(
        startTime: .now.addingTimeInterval(-1800),
        endTime: .now,
        totalDistance: 8200,
        avgSpeed: 6.8,
        maxSpeed: 9.1,
        calories: 310,
        notes: "A nice evening ride."
    )
    ctx.insert(sampleRide)

    // 4. Create instances of the services needed for the preview
    let rideDataManager = RideDataManager(modelContainer: container)
    let healthKitService = HealthKitService()
    
    // 5. Return the view, injecting the container and all necessary services
    return RideListView()
        .modelContainer(container)
        .environment(rideDataManager)
        .environment(healthKitService)
}

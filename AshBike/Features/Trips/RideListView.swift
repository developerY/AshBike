//
//  RideListView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI
import SwiftData
import MapKit

struct RideListView: View {
    @Query(sort: \BikeRide.startTime, order: .reverse)
    private var rides: [BikeRide]

    @Environment(\.modelContext) private var modelContext
    
    // Receive services from the environment
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(RideDataManager.self) private var rideDataManager

    // State for the UI
    @State private var syncedRideIDs: Set<UUID> = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

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
                                alertTitle = "Error"
                                alertMessage = "Could not delete all rides."
                                showingAlert = true
                            }
                        }
                    }
                    .disabled(rides.isEmpty)
                }
            }
            .onAppear(perform: checkAllRidesSyncStatus)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            // Refresh sync status when the list changes
            .onChange(of: rides) {
                checkAllRidesSyncStatus()
            }
        }
    }

    // --- MODIFIED FUNCTION ---
    private func delete(_ ride: BikeRide) {
        modelContext.delete(ride)
        do {
            // This line ensures the change is saved and the UI updates reliably.
            try modelContext.save()
        } catch {
            // Handle potential errors during the save operation.
            print("Failed to save context after deleting ride: \(error)")
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
                self.alertTitle = "Success"
                self.alertMessage = "Your ride has been successfully synced to Apple Health."
            } else {
                self.alertTitle = "Sync Failed"
                self.alertMessage = "Could not sync ride to Apple Health.\n\(error?.localizedDescription ?? "")"
            }
            self.showingAlert = true
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

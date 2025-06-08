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
    
    @State private var healthKitService = HealthKitService()
    
    // NEW: A single source of truth for the sync status of all rides in this view
    @State private var syncedRideIDs: Set<UUID> = []
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(rides) { ride in
                        NavigationLink(value: ride) {
                            RideCardViewSimple(
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
            .navigationTitle("Bike Rides")
            .navigationDestination(for: BikeRide.self) { ride in
                RideDetailView(ride: ride)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { addDebugRide() } label: { Image(systemName: "plus") }
                    Button { deleteAllRides() } label: { Image(systemName: "trash") }
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
    
    private func addDebugRide() {
        let newRide = makeRandomBikeRide()
        modelContext.insert(newRide)
    }
    
    private func delete(_ ride: BikeRide) {
        modelContext.delete(ride)
    }
    
    private func deleteAllRides() {
        try? modelContext.delete(model: BikeRide.self)
    }
    
    private func checkAllRidesSyncStatus() {
        healthKitService.requestAuthorization { success, error in
            guard success else { return }
            // Fetch status for all rides at once
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
    let config = ModelConfiguration(
        schema: Schema([BikeRide.self, RideLocation.self]),
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: Schema([BikeRide.self, RideLocation.self]),
        configurations: [config]
    )
    let ctx = container.mainContext
    
    for _ in 0..<3 {
        let ride = makeRandomBikeRide()
        ctx.insert(ride)
    }
    try? ctx.save()
    
    return RideListView()
        .modelContainer(container)
}

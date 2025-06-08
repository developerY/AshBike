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
    
    // HealthKit Service
    @State private var healthKitService = HealthKitService()
    
    // State for alert pop-up
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
            .onAppear(perform: requestHealthKitPermission)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func addDebugRide() {
        let newRide = makeRandomBikeRide()
        modelContext.insert(newRide)
        try? modelContext.save()
    }
    
    private func delete(_ ride: BikeRide) {
        modelContext.delete(ride)
        try? modelContext.save()
    }
    
    private func deleteAllRides() {
        try? modelContext.delete(model: BikeRide.self)
    }
    
    // MARK: - HealthKit Actions
    
    private func requestHealthKitPermission() {
        healthKitService.requestAuthorization { success, error in
            if let error = error {
                print("HealthKit Auth Error: \(error.localizedDescription)")
            }
            if success {
                print("HealthKit authorization successful.")
            }
        }
    }
    
    private func sync(ride: BikeRide) {
        healthKitService.save(bikeRide: ride) { [self] success, error in
            if success {
                self.alertTitle = "Success"
                self.alertMessage = "Your ride has been successfully synced to Apple Health."
            } else {
                self.alertTitle = "Sync Failed"
                self.alertMessage = "Could not sync ride to Apple Health. Please make sure you have granted permissions in the Health app.\n\(error?.localizedDescription ?? "")"
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

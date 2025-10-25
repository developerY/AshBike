//
//  RideDetailView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
// RideDetailView.swift

import SwiftUI
import SwiftData
import MapKit

struct RideDetailView: View {
    @Bindable var ride: BikeRide
    
    // --- 1. ADD ENVIRONMENT VARIABLES ---
    @Environment(RideDataManager.self) private var rideDataManager
    @Environment(\.dismiss) private var dismiss

    // ... (coordinates and formatters remain the same) ...
    // ** THE FIX IS HERE **
    // We must explicitly sort the locations by timestamp to guarantee the
    // route is drawn in the correct order.
    private var coordinates: [CLLocationCoordinate2D] {
        ride.locations.sorted(by: { $0.timestamp < $1.timestamp }).map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    // Formatters
    private let dateFmt: DateIntervalFormatter = {
        let f = DateIntervalFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private let durationFmt: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // — Top Stats Cards —
                HStack(spacing: 12) {
                    StatCard(title: "Distance",
                             value: ride.totalDistance / 1_000,
                             unit: "km")
                    StatCard(title: "Avg Speed",
                             value: ride.avgSpeed * 3.6,
                             unit: "km/h")
                    StatCard(title: "Max Speed",
                             value: ride.maxSpeed * 3.6,
                             unit: "km/h")
                }

                // — Date & Duration —
                Text(dateFmt.string(from: ride.startTime, to: ride.endTime))
                    .font(.headline)
                Text(durationFmt.string(from: ride.duration) ?? "--")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                  
                // — Map with Polyline Overlay —
                RideMapView(route: coordinates, showUserLocation: false)
                    .frame(height: 250)
                    .cornerRadius(12)
                    .shadow(radius: 4)

                // — Elevation Profile Disclosure —
                DisclosureGroup("Elevation Profile") {
                    HStack(spacing: 24) {
                        StatCard(title: "↑ / ↓",
                                 value: ride.elevationGain,
                                 unit: "m")
                        StatCard(title: "Duration",
                                 value: ride.duration,
                                 unit: "",
                                 format: .time)
                        StatCard(title: "Calories",
                                 value: Double(ride.calories),
                                 unit: "kcal")
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                // — Notes Editor —
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextEditor(text: $ride.notes.bound)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.1)))
                }
            }
            .padding()
        }
        .navigationTitle("Ride Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // --- 2. MODIFY THE BUTTON ACTION ---
                Button(role: .destructive) {
                    Task {
                        do {
                            try await rideDataManager.delete(ride: ride)
                            // Dismiss the view after successful deletion
                            dismiss()
                        } catch {
                            // Handle or log the error appropriately
                            print("Error deleting ride: \(error)")
                            // You could show an alert here if needed
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

// Helper for optional string binding in TextEditor
extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue }
    }
}


// MARK: — Preview with in-memory container
#Preview {
    // 1. Create the container
    let container = try! ModelContainer(
      for: Schema([BikeRide.self, RideLocation.self]),
      configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    
    // 2. Create the RideDataManager
    let rideDataManager = RideDataManager(modelContainer: container)
    
    // 3. Create and insert the sample data
    let sampleRide = BikeRide(
        startTime: .now.addingTimeInterval(-600),
        endTime: .now,
        locations: [
            RideLocation(timestamp: .now.addingTimeInterval(-300), lat: 37.331, lon: -122.031),
            RideLocation(timestamp: .now.addingTimeInterval(-200), lat: 37.332, lon: -122.032),
            RideLocation(timestamp: .now.addingTimeInterval(-100), lat: 37.333, lon: -122.030)
        ]
    )
    container.mainContext.insert(sampleRide)
    
    // 4. Return the view and inject ALL dependencies
    return NavigationStack {
        RideDetailView(ride: sampleRide)
    }
    .modelContainer(container)
    .environment(rideDataManager) // <-- ADD THIS LINE
}

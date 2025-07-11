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
    @Environment(\.modelContext) private var modelContext
    
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
                RideMapView(route: coordinates)
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
                Button(role: .destructive) {
                    modelContext.delete(ride)
                    // ** THE FIX IS HERE: **
                    // Explicitly save the context after deleting.
                    try? modelContext.save()
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
    let container = try! ModelContainer(
      for: Schema([BikeRide.self, RideLocation.self]),
      configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    
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
    
    return NavigationStack {
        RideDetailView(ride: sampleRide)
    }
    .modelContainer(container)
}

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
    
    @State private var fullText: String = "This is some editable text..."


  // Convert your RideLocation models into plain map coordinates
  private var coordinates: [CLLocationCoordinate2D] {
    ride.locations.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  // A simple region centered on the last point, with a small span
  /*private var region: MKCoordinateRegion {
    let center = coordinates.last ?? CLLocationCoordinate2D()
    return MKCoordinateRegion(
      center: center,
      span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
  }*/
    let route: [CLLocationCoordinate2D]

    private var region: MKCoordinateRegion {
      MKCoordinateRegion(
        center: route.last ?? .init(),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
      )
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
        Text(durationFmt.string(from: ride.endTime.timeIntervalSince(ride.startTime)) ?? "--")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          
          
        // — Map with Polyline Overlay —
        /*Map(
          position: .constant(.region(region)),
          showsUserLocation: true,
          interactionModes: .all
        ) {
          if coordinates.count > 1 {
            MapPolyline(coordinates: coordinates)
              .stroke(.red, lineWidth: 3)
          }
        }*/
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
                     value: ride.endTime.timeIntervalSince(ride.startTime),
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
            
            TextEditor(text: $fullText)
                        .foregroundColor(Color.gray)
                        .font(.custom("HelveticaNeue", size: 13))
            
            
          /*TextEditor(text: $ride.notes.bound)
            .frame(minHeight: 80)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.1)))*/
        }
      }
      .padding()
    }
    .navigationTitle("Ride Details")
    .toolbar {
      // Delete button
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(role: .destructive) {
          modelContext.delete(ride)
        } label: {
          Image(systemName: "trash")
        }
      }
    }
  }
}


// MARK: — Preview with in-memory container
/*#Preview {
  // 1) Build a sample RideLocation sequence
  let locs: [RideLocation] = [
    RideLocation(timestamp: .now.addingTimeInterval(-300), lat: 37.7749, lon: -122.4194, speed: 5),
    RideLocation(timestamp: .now.addingTimeInterval(-200), lat: 37.7750, lon: -122.4190, speed: 7),
    RideLocation(timestamp: .now.addingTimeInterval(-100), lat: 37.7751, lon: -122.4185, speed: 6)
  ]

  // 2) Create a sample BikeRide
  let sample = BikeRide(
    startTime: .now.addingTimeInterval(-600),
    endTime: .now,
    totalDistance: 2_500,
    avgSpeed: 5.0,
    maxSpeed: 7.0,
    elevationGain: 20,
    calories: 120,
    notes: "Lovely little loop!",
    locations: locs
  )

  // 3) In-memory container & insert the sample
  var cfg = ModelConfiguration(
    schema: Schema([BikeRide.self, RideLocation.self]),
    isStoredInMemoryOnly: true
  )
  let container = try! ModelContainer(
    for: Schema([BikeRide.self, RideLocation.self]),
    configurations: [cfg]
  )
  // must insert on the main actor
  await container.mainContext.insert(sample)

  // 4) Show the detail view
  NavigationStack {
    RideDetailView(ride: sample)
      .modelContainer(container)
  }
}*/


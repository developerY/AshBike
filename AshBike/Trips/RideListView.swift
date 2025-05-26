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
  // 1) Fetch all rides, most-recent first
  @Query(
    sort: \.startTime,
    order: .reverse
  ) private var rides: [BikeRide]

  // 2) SwiftData context
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(rides, id: \.id) { ride in
            RideCardView(
              ride: ride,
              onDelete:   { delete(ride) },
              onSync:     { sync(ride)   }
            )
          }
        }
        .padding()
      }
      .navigationTitle("Bike Rides")
      .toolbar {
        // Add a single ride for debugging
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            addDebugRide()
          } label: {
            Image(systemName: "plus")
          }
        }
        // Wipe out all rides
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            deleteAllRides()
          } label: {
            Image(systemName: "trash")
          }
        }
      }
    }
  }

  // MARK: – Actions

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
    for ride in rides {
      modelContext.delete(ride)
    }
    try? modelContext.save()
  }

  private func sync(_ ride: BikeRide) {
    // your real sync logic here…
    ride.isSynced = true
    try? modelContext.save()
  }
}


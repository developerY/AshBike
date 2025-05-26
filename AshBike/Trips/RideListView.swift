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
  // 1) Fetch all rides, most‐recent first
  @Query() //  sort: \.startTime, order: .reverse)
  private var rides: [BikeRide]
  
  // 2) SwiftData context for inserts/deletes
  @Environment(\.modelContext) private var modelContext

  var body: some View {
      NavigationStack {
          ScrollView {
              LazyVStack(spacing: 12) {
                  ForEach(rides, id: \.id) { ride in
                      NavigationLink(value: ride) {
                          Text("Here is the ride \(ride.id)")
                          /*RideCardView(
                           ride: ride,
                           onDelete: { delete(ride) },
                           onSync:   { sync(ride)   }
                           )*/
                      }
                      .buttonStyle(.plain)
                  }
              }
              .padding()
          }
      } // ← now these attach to the NavigationStack
      .navigationTitle("Bike Rides")
      // 3) Detail‐screen push
      .navigationDestination(for: BikeRide.self) { ride in
        //Text("D Ride Detail")
        RideDetailViewSimple(ride: ride)
      }
      // 4) Add / Clear toolbar
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button { addDebugRide() } label: { Image(systemName: "plus") }
          Button { deleteAllRides() } label: { Image(systemName: "trash") }
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
    rides.forEach { modelContext.delete($0) }
    try? modelContext.save()
  }
}

// =================================================================
// MARK: – Supporting Types & Previews
// =================================================================

#Preview {
  // seed an in‐memory ModelContainer
  let config = ModelConfiguration(
    schema: Schema([BikeRide.self, RideLocation.self]),
    isStoredInMemoryOnly: true
  )
  let container = try! ModelContainer(
    for: Schema([BikeRide.self, RideLocation.self]),
    configurations: [config]
  )
  let ctx = container.mainContext
  
  // insert a couple of random rides
  for _ in 0..<3 {
    let ride = makeRandomBikeRide()
    ctx.insert(ride)
  }
  try? ctx.save()
  
  return RideListView()
    .modelContainer(container)
}

//
//  SimpleList.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI
import SwiftData

// MARK: — Your model
@Model
class BikeRideSimple {
  @Attribute(.unique) var id: UUID // = .init()
  var startTime: Date
  var endTime: Date
  
  init(startTime: Date, endTime: Date) {
    self.id = .init()
    self.startTime = startTime
    self.endTime   = endTime
  }
}

// MARK: — A trivial detail view
struct RideDetailViewSimple: View {
  let ride: BikeRide
  var body: some View {
    VStack(spacing: 20) {
      Text("Ride Detail")
      Text("Started: \(ride.startTime.formatted())")
      Text("Ended:   \(ride.endTime.formatted())")
    }
    .navigationTitle("Details")
    .padding()
  }
}

// MARK: — The list view using value‐based links
struct RideListViewSimple: View {
  // 1) Fetch rides, most‐recent first
    // sort: \.startTime, order: .reverse
  @Query() private var rides: [BikeRide]
  @Environment(\.modelContext) private var modelContext
  
  var body: some View {
    NavigationStack {
      List(rides) { ride in
        // 2) Value‐based binding: push when ride is tapped
        NavigationLink(value: ride) {
          Text(ride.startTime, format: .dateTime.hour().minute())
        }
      }
      .navigationTitle("Bike Rides")
      // 3) Wire up the destination for BikeRide
      .navigationDestination(for: BikeRide.self) { ride in
        RideDetailViewSimple(ride: ride)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            addDebugRide()
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    }
  }
  
  private func addDebugRide() {
    let now = Date()
    let oneHourAgo = now.addingTimeInterval(-3600)
    let newRide = BikeRide(startTime: oneHourAgo, endTime: now)
    modelContext.insert(newRide)
    try? modelContext.save()
  }
}

// MARK: — Preview setup
#Preview {
  // build an in‐memory container seeded with a couple rides
  let config = ModelConfiguration(
    schema: Schema([BikeRide.self]),
    isStoredInMemoryOnly: true
  )
  let container = try! ModelContainer(for: Schema([BikeRide.self]), configurations: [config])
  let ctx = container.mainContext
  
  // seed two
  let r1 = BikeRide(startTime: .now.addingTimeInterval(-600), endTime: .now)
  let r2 = BikeRide(startTime: .now.addingTimeInterval(-3600), endTime: .now.addingTimeInterval(-3000))
  ctx.insert(r1); ctx.insert(r2)
  try? ctx.save()
  
  return RideListView().modelContainer(container)
}


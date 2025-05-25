//
//  RideView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI
import Charts
import SwiftData

struct RideView: View {
  // 1) Fetch your past rides (or just last N) sorted by startTime
    // Pull in your saved rides, sorted by date
      @Query(
        sort: [
          SortDescriptor(\BikeRide.startTime, order: .forward)
        ]
      ) private var rides: [BikeRide]

  var body: some View {
    NavigationStack {
      VStack {
        Text("Ride History")
          .font(.title2).bold()
          .padding(.top)

        // 2) Show Chart of distance over time
        Chart {
          ForEach(rides) { ride in
            LineMark(
              x: .value("Date", ride.startTime, unit: .day),
              y: .value("Distance (km)", ride.totalDistance / 1_000)
            )
            PointMark(
              x: .value("Date", ride.startTime, unit: .day),
              y: .value("Distance (km)", ride.totalDistance / 1_000)
            )
          }
        }
        .chartXAxis {
          AxisMarks(values: .stride(by: .day, count: 1)) { _ in
            AxisTick()
            AxisValueLabel(format: .dateTime.month().day())
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading)
        }
        .frame(height: 200)
        .padding()

        Spacer()
      }
      .navigationTitle("Ride Stats")
    }
  }
}

// MARK: – Helpers pulled out of #Preview

// 1) Build some dummy rides once, at file scope
// ↓ moved map into an explicit loop so the compiler can follow it
private let previewDemoRides: [BikeRide] = {
  var rides = [BikeRide]()
  for i in 0..<7 {
    let start = Date().addingTimeInterval(Double(i) * -86_400)
    let end   = start.addingTimeInterval(600)
    let ride = BikeRide(
      startTime:     start,
      endTime:       end,
      totalDistance: Double(i + 1) * 1_000,
      avgSpeed:      Double(10 + i),
      maxSpeed:      Double(15 + i),
      elevationGain: 0,
      calories:      (i + 1) * 50,
      notes:         nil,
      locations:     []
    )
    rides.append(ride)
  }
  return rides
}()

// 2) Create and populate an in-memory ModelContainer once
@MainActor
private let previewContainer: ModelContainer = {
    // 2a) build an in-memory configuration
    let config = ModelConfiguration(
        schema: Schema([BikeRide.self, RideLocation.self]),
        isStoredInMemoryOnly: true
    )

    // 2b) initialize the container
    let container = try! ModelContainer(
        for: Schema([BikeRide.self, RideLocation.self]),
        configurations: [config]
    )

    // 2c) insert each preview ride into the mainContext
    let ctx = container.mainContext
    for ride in previewDemoRides {
        ctx.insert(ride)
    }

    return container
}()

// 3) Use that container in your preview
#Preview("Ride Stats w/ Charts") {
    RideView()
      .modelContainer(previewContainer)
      //.previewDisplayName
}

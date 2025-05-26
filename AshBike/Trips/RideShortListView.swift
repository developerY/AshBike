//
//  RideListView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftUI
import SwiftData

struct RideShortListView: View {
    @Query(sort: \BikeRide.startTime, order: .reverse) private var rides: [BikeRide]

    var body: some View {
        List(rides) { ride in
            VStack(alignment: .leading) {
                Text("Distance: \(ride.totalDistance, specifier: "%.2f") m")
                Text("Duration: \(ride.duration.formatted())")
                Text("Calories: \(ride.calories)")
            }
        }
    }
}

#Preview {
    RideShortListView()
}

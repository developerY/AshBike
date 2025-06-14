//
//  RideCardView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI

struct RideCardView: View {
    let ride: BikeRide
    let isSynced: Bool // Receives status from the parent
    let onDelete: () -> Void
    let onSync: () -> Void
  
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(ride.startTime, format: .dateTime.month().day().hour().minute())
                    .font(.headline)
                Spacer()
                Text("(\(Int(ride.endTime.timeIntervalSince(ride.startTime)))s)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Text("Distance: \(ride.totalDistance / 1000, format: .number.precision(.fractionLength(1))) km")
            Text("Avg: \(ride.avgSpeed * 3.6, format: .number.precision(.fractionLength(1))) km/h   Max: \(ride.maxSpeed * 3.6, format: .number.precision(.fractionLength(1))) km/h")
            
            HStack {
                Spacer()
                
                // The view now simply reflects the isSynced property
                if isSynced {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button(action: onSync) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .font(.title3)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
        .shadow(radius: 1)
    }
}


#Preview {
  // 1) Build a sample BikeRide
  let sampleRide = BikeRide(
    startTime: .now.addingTimeInterval(-3600),   // 1 h ago
    endTime:   .now,                             // now
    totalDistance: 5_200,                        // m
    avgSpeed:      5.2,                          // m/s
    maxSpeed:      8.3,                          // m/s
    elevationGain: 42,                           // m
    calories:      210,
    notes:         "Lovely little loop!",
    locations:     []                            // omit GPS trace for card
  )

  // 2) Render both cards in a VStack
  VStack(spacing: 32) {
    RideCardView(
        ride: sampleRide,
        isSynced: true,
      onDelete: { print("deleteSimple tapped") },
      onSync:   { print("syncSimple tapped")   }
    )
  }
  .padding()
}

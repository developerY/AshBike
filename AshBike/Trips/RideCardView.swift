//
//  RideCardView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI

struct RideCardView: View {
  let ride: BikeRide
  let onDelete: () -> Void
  let onSync:   () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        // Date range
        Text(ride.startTime, format: .dateTime.month(.abbreviated).day().hour().minute())
        Text("–")
        Text(ride.endTime,   format: .dateTime.hour().minute())

        Spacer()

        // Duration badge
        Text(durationString(for: ride))
          .font(.subheadline)
          .foregroundStyle(.secondary)

        // Delete button
        Button {
          onDelete()
        } label: {
          Image(systemName: "trash")
        }
        .buttonStyle(.plain)
      }

      // Key stats
      VStack(alignment: .leading, spacing: 4) {
        Text("Distance: \(ride.totalDistance / 1_000, specifier: "%.1f") km")
        Text("Avg: \(ride.avgSpeed * 3.6, specifier: "%.1f") km/h")
        Text("Max: \(ride.maxSpeed * 3.6, specifier: "%.1f") km/h")
      }
      .font(.subheadline)

      // Optional notes
      if let notes = ride.notes, !notes.isEmpty {
        Text(notes)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      HStack {
        Text("Is Synced =  False") //  \(ride.isSynced ? "true" : "false")")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          onSync()
        } label: {
          Image(systemName: "arrow.triangle.2.circlepath")
            .foregroundColor(.pink)
        }
        .buttonStyle(.plain)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.ultraThinMaterial)
    )
  }

  private func durationString(for ride: BikeRide) -> String {
    let secs = Int(ride.endTime.timeIntervalSince(ride.startTime))
    let m = secs / 60, s = secs % 60
    return "(\(m) min \(s)s)"
  }
}

/// A simple “card” view for display in the list
struct RideCardViewSimple: View {
    let ride: BikeRide
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
                
                // UPDATED: Conditionally show the sync button or a success icon
                if ride.isSyncedToHealthKit {
                    // You can replace this with your custom icon from image_348830.png
                    // after adding it to your Assets.xcassets catalog.
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
      onDelete: { print("delete tapped") },
      onSync:   { print("sync tapped")   }
    )
    RideCardViewSimple(
      ride: sampleRide,
      onDelete: { print("deleteSimple tapped") },
      onSync:   { print("syncSimple tapped")   }
    )
  }
  .padding()
  .previewLayout(.sizeThatFits)
}


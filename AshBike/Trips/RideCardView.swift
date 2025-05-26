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
        Text("Is Synced = \(ride.isSynced ? "true" : "false")")
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


//
//  StatCard.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI
import SwiftData
import MapKit


// MARK: — A little reusable “stat card”
struct StatCard: View {
  let title: String
  let value: Double
  let unit: String
  var format: FormatStyle = .decimal

  enum FormatStyle { case decimal, time }
  private var formatted: String {
    switch format {
    case .decimal:
      return String(format: "%.1f", value)
    case .time:
      let f = DateComponentsFormatter()
      f.allowedUnits = [.minute, .second]
      f.unitsStyle = .abbreviated
      return f.string(from: value) ?? "--"
    }
  }

  var body: some View {
    VStack {
      Text(formatted)
        .font(.title2).bold()
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      if !unit.isEmpty {
        Text(unit).font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
  }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(
            title: "Distance",
            value: 25.8,
            unit: "km",
            format: .decimal
        )
        
        StatCard(
            title: "Duration",
            value: 3720, // (62 minutes)
            unit: "",
            format: .time
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}


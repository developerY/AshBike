//
//  MetricCard.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// MetricCard.swift
import SwiftUI
struct MetricCard: View {
  let label: String
  let value: String

  var body: some View {
    VStack {
      Text(value)
        .font(.headline)
      Text(label)
        .font(.caption)
    }
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(8)
  }
}

#Preview("MetricCard") {
  MetricCard(label: "Speed", value: "22.4 mph")
    .padding()
    .background(Color(.systemBackground))
}

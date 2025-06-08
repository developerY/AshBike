//
//  RideSessionView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftUI
import SwiftData
import MapKit

struct RideSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = RideSessionManager()
    
    var body: some View {
        VStack(spacing: 16) {
            Gauge(value: sessionManager.currentSpeed * 3.6, in: 0...60) {
                Text("Speed (km/h)")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Color.blue)
            .scaleEffect(2.0)
            .padding(.vertical)

            VStack(spacing: 12) {
                RideStatView(label: "Distance", value: sessionManager.distance / 1000, unit: "km")
                RideStatView(label: "Duration", value: sessionManager.duration, unit: nil, format: .time)
                RideStatView(label: "Calories", value: Double(sessionManager.calories), unit: "kcal")
            }

            if !sessionManager.routeCoordinates.isEmpty {
                RideMapView(route: sessionManager.routeCoordinates)
                    .frame(height: 200)
                    .cornerRadius(10)
            }

            Spacer()

            HStack(spacing: 40) {
                Button(action: {
                    sessionManager.start()
                }) {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .disabled(sessionManager.isRecording)

                Button(action: {
                    sessionManager.stopAndSave(context: modelContext)
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .disabled(!sessionManager.isRecording)
            }
        }
        .padding()
        .navigationTitle("Record a Ride")
    }
}

// MARK: - Subviews

fileprivate struct RideStatView: View {
    let label: String
    let value: Double
    let unit: String?
    var format: FormatStyle = .number

    enum FormatStyle {
        case number, time
    }

    var formattedValue: String {
        switch format {
        case .number:
            return String(format: "%.1f", value)
        case .time:
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: value) ?? "0:00"
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            if let unit = unit {
                Text(formattedValue)
                    .font(.title3.bold().monospacedDigit())
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(formattedValue)
                    .font(.title3.bold().monospacedDigit())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
    }
}


#Preview {
    // This preview needs a model container to function.
    let config = ModelConfiguration(schema: Schema([BikeRide.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([BikeRide.self]), configurations: [config])

    return NavigationStack {
        RideSessionView()
            .modelContainer(container)
    }
}

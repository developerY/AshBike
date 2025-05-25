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
    // 1️⃣ Grab the live SwiftData context
    @Environment(\.modelContext) private var modelContext    // now the compiler knows \.modelContext

    
    // 2️⃣ Hold your @Observable manager in @State
    @State private var sessionManager = RideSessionManager()
    @State private var isRiding = false
    
    var body: some View {
        VStack(spacing: 16) {
            Gauge(value: sessionManager.currentSpeed, in: 0...40) {
                Text("Speed (km/h)")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.blue)
            .scaleEffect(2)

            VStack(spacing: 12) {
                RideStatView(label: "Distance", value: sessionManager.distance / 1000, unit: "km")
                RideStatView(label: "Duration", value: sessionManager.duration, unit: "min", format: .time)
                RideStatView(label: "Calories", value: Double(sessionManager.calories), unit: "kcal")
            }

            if !sessionManager.routeCoordinates.isEmpty {
                RideMapView(route: sessionManager.routeCoordinates)
                    .frame(height: 200)
                    .cornerRadius(10)
            }

            Spacer()

            HStack(spacing: 40) {
                Button(action: startPauseTapped) {
                    Image(systemName: isRiding ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .background(isRiding ? .orange : .green)
                        .clipShape(Circle())
                }

                Button(action: stopTapped) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .navigationTitle("Ride Session")
        // 3️⃣ As soon as the view appears, wire up the context
        /*.onAppear {
            sessionManager.modelContext = modelContext
        }*/
    }

    // MARK: - Actions

    private func startPauseTapped() {
        if isRiding {
            sessionManager.pause()
        } else {
            sessionManager.start()
        }
        isRiding.toggle()
    }

    @MainActor
        private func stopTapped() {
            //sessionManager.stopAndSaveRide()   // ← no “context:” label
            isRiding = false
        }
}

// MARK: - Subviews

struct RideStatView: View {
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
            formatter.unitsStyle = .full
            formatter.includesApproximationPhrase = true
            formatter.includesTimeRemainingPhrase = true
            formatter.allowedUnits = [.minute]

            return formatter.string(from: value) ?? "0:00"
        }
    }

    var body: some View {
        VStack {
            Text(formattedValue)
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RideSessionView()
            .modelContainer(for: BikeRide.self)
    }
}


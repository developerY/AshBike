//
//  HomeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// AshBike/Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    // MARK: – Live Ride State
    @State private var distance: Double = 0          // in km
    @State private var duration: TimeInterval = 0    // in seconds
    @State private var avgSpeed: Double = 0          // in km/h
    @State private var heartRate: Int?               // in bpm
    @State private var calories: Int = 0             // in kcal
    @State private var isRunning: Bool = false
    @State private var showEbikeStats: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // — Gauge + Compass —
            ZStack {
                GaugeView(speed: avgSpeed)        // your circular gauge
                    .frame(width: 200, height: 200)
                CompassView(direction: .degrees(210)) // your mini compass
                    .frame(width: 60, height: 60)
                    .offset(x: 70, y: -70)
            }

            // — Metric Cards —
            HStack(spacing: 12) {
                MetricCard(label: "Distance",
                           value: String(format: "%.1f km", distance))
                MetricCard(label: "Duration",
                           value: formattedDuration(duration))
                MetricCard(label: "Avg Speed",
                           value: String(format: "%.1f km/h", avgSpeed))
            }

            HStack(spacing: 12) {
                MetricCard(label: "Heart Rate",
                           value: heartRate.map { "\($0) bpm" } ?? "-- bpm")
                MetricCard(label: "Calories",
                           value: "\(calories) kcal")
            }

            // — Collapsible E-bike Stats —
            CollapsibleSection(title: "E-bike Stats", isExpanded: $showEbikeStats) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Battery: --%")
                    Text("Motor Power: -- W")
                }
                .padding(.horizontal)
            }

            Spacer()

            // — Controls —
            HStack(spacing: 40) {
                Button(action: toggleRide) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)

                Button(action: stopRide) {
                    Image(systemName: "stop.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isRunning)
            }
        }
        .padding()
    }

    // MARK: – Actions

    private func toggleRide() {
        isRunning.toggle()
        if isRunning {
            startRide()
        } else {
            pauseRide()
        }
    }

    private func startRide() {
        // TODO: hook into CoreMotion / Location updates
    }

    private func pauseRide() {
        // TODO: pause timers / location updates
    }

    private func stopRide() {
        isRunning = false
        // TODO: finalize the session, save to SwiftData, reset metrics
    }

    // MARK: – Formatting

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = interval >= 3600
            ? [.hour, .minute, .second]
            : [.minute, .second]
        fmt.zeroFormattingBehavior = .pad
        return fmt.string(from: interval) ?? "00:00"
    }
}

// MARK: – Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .previewLayout(.sizeThatFits)
    }
}


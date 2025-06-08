//
//  HomeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI
import Observation
import MapKit

struct HomeView: View {
    @State private var session = RideSessionManager()
    
    // State for the accordion sections
    private enum ExpandedSection {
        case metrics, ebike
    }
    @State private var expandedSection: ExpandedSection? = .metrics
    
    // State to control the map's bottom sheet presentation
    @State private var isShowingMapSheet = false

    var body: some View {
        VStack(spacing: 16) {
            // — Gauge —
            GaugeView(
                speed: session.currentSpeed * 3.6,
                heading: session.heading,
                onMapButtonTapped: {
                    isShowingMapSheet = true
                }
            )
            .frame(width: 300, height: 300)
            .padding(.horizontal)

            // — Live Metrics Section —
            CollapsibleSection(
                title: "Live Metrics",
                isExpanded: Binding(
                    get: { expandedSection == .metrics },
                    set: { isExpanding in expandedSection = isExpanding ? .metrics : nil }
                )
            ) {
                VStack {
                    HStack(spacing: 12) {
                        MetricCard(label: "Distance", value: String(format: "%.1f km", session.distance / 1000))
                        MetricCard(label: "Duration", value: formattedDuration(session.duration))
                        MetricCard(label: "Avg Speed", value: String(format: "%.1f km/h", session.avgSpeed * 3.6))
                    }
                    HStack(spacing: 12) {
                        MetricCard(label: "Heart Rate", value: "-- bpm")
                        MetricCard(label: "Calories", value: "\(session.calories) kcal")
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)

            // — E-bike Stats —
            CollapsibleSection(
                title: "E-bike Stats",
                isExpanded: Binding(
                    get: { expandedSection == .ebike },
                    set: { isExpanding in expandedSection = isExpanding ? .ebike : nil }
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Battery: --%")
                    Text("Motor Power: -- W")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)

            Spacer()

            // — Controls —
            HStack(spacing: 40) {
                Button(action: { session.start() }) {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { session.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.duration == 0)
            }
        }
        .padding(.vertical)
        .sheet(isPresented: $isShowingMapSheet) {
            // This is the content for the bottom sheet
            VStack {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                Text("Live Route")
                    .font(.headline)
                    .padding()
                
                RouteMapView(route: session.routeCoordinates)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func formattedDuration(_ sec: TimeInterval) -> String {
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = sec >= 3600
            ? [.hour, .minute, .second]
            : [.minute, .second]
        fmt.zeroFormattingBehavior = .pad
        return fmt.string(from: sec) ?? "00:00"
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

//
//  HomeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// AshBike/Views/HomeView.swift
import SwiftUI
import MapKit

struct HomeView: View {
    
    @State private var session = RideSessionManager()

    // MARK: – Live Ride State
    @State private var distance: Double = 0          // in km
    @State private var duration: TimeInterval = 0    // in seconds
    @State private var avgSpeed: Double = 0          // in km/h
    @State private var heartRate: Int?               // in bpm
    @State private var calories: Int = 0             // in kcal
    @State private var isRunning: Bool = false
    @State private var showEbikeStats: Bool = false
    @State private var showMap = false
    
    @State private var manager = SpeedManager()   // no init needed

    
    static var sampleRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3349, longitude: -122.0090),
        .init(latitude: 37.3350, longitude: -122.0091),
        .init(latitude: 37.3351, longitude: -122.0092)
    ]
    
    
    var body: some View {
        VStack(spacing: 16) {
            // — Gauge + Compass —
            ZStack {
                GaugeView(speed: session.currentSpeed * 3.6)        // your circular gauge
                    .frame(width: 200, height: 200)
                CompassView(direction: .degrees(210)) // your mini compass
                    .frame(width: 60, height: 60)
                    .offset(x: 70, y: -70)
            }
        

            // — Metric Cards —
            HStack(spacing: 12) {
                MetricCard(label: "Distance",
                           value: String(format: "%.1f km", session.distance / 1000))
                MetricCard(label: "Duration",
                           value: formattedDuration(session.duration))
                MetricCard(label: "Avg Speed",
                           value: String(format: "%.1f km/h", session.avgSpeed))
            }

            HStack(spacing: 12) {
                MetricCard(label: "Heart Rate",
                           value: heartRate.map { "\($0) bpm" } ?? "-- bpm")
                MetricCard(label: "Calories",
                           value: "\(calories) kcal")
            }
            
            // — Map Section —
            //DisclosureGroup("Map", isExpanded: $showMap) {
            CollapsibleSection(title: "Map", isExpanded: $showMap) {
                RouteMapView(route: HomeView.sampleRoute)//session.routeCoordinates)
                    .frame(height: 200)
                    .cornerRadius(8)
                    .padding(.horizontal)
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
        Group {
            HomeView()
                .previewDisplayName("Empty Session")
            HomeView()
                .onAppear {
                    // seed a fake route for preview
                    let coords = RouteMapView_Previews.sampleRoute
                    let mgr = RideSessionManager()
                    mgr.routeCoordinates = coords
                    mgr.distance = coords.count * 10
                    mgr.duration = 120
                    mgr.avgSpeed = mgr.distance / mgr.duration
                    mgr.currentSpeed = 5
                    // override the @State initial value
                    _ = HomeView().session // no longer needed; just illustrative
                }
                .previewDisplayName("Sample Session")
        }
        .previewLayout(.sizeThatFits)
    }
}

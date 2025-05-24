//
//  HomeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// AshBike/Views/HomeView.swift
import SwiftUI
import Observation  // for @Observable
import MapKit

struct HomeView: View {
    @State private var session = RideSessionManager()  // not @StateObject
    @State private var showMap = false
    @State private var showEbikeStats = false

    
    static var sampleRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3349, longitude: -122.0090),
        .init(latitude: 37.3350, longitude: -122.0091),
        .init(latitude: 37.3351, longitude: -122.0092)
    ]
    
    
    var body: some View {
        VStack(spacing: 16) {
            // — Gauge —
            GaugeView(speed: session.currentSpeed * 3.6)
                .frame(width: 200, height: 200)

            // — Metrics row 1 —
            HStack(spacing: 12) {
                MetricCard(
                  label: "Distance",
                  value: String(format: "%.1f km", session.distance / 1000)
                )
                MetricCard(
                  label: "Duration",
                  value: formattedDuration(session.duration)
                )
                MetricCard(
                  label: "Avg Speed",
                  value: String(format: "%.1f km/h", session.avgSpeed * 3.6)
                )
            }

            // — Metrics row 2 —
            HStack(spacing: 12) {
                MetricCard(
                  label: "Heart Rate",
                  value: session.heartRate.map { "\($0) bpm" } ?? "-- bpm"
                )
                MetricCard(
                  label: "Calories",
                  value: "\(session.calories) kcal"
                )
            }

            // — Map section —
            CollapsibleSection(title: "Map", isExpanded: $showMap) {
              RouteMapView(route: session.routeCoordinates)
                .frame(height: 200)
                .cornerRadius(8)
                .padding(.horizontal)
            }


            // — E-bike Stats —
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
                Button {
                    session.start()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    session.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.duration == 0)
            }
        }
        .padding()
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
        Group {
            HomeView()
                .previewDisplayName("Empty Session")
            HomeView()
                .onAppear {
                    // seed a fake route for preview
                    let coords = RouteMapView_Previews.sampleRoute
                    let mgr = RideSessionManager()
                    //mgr.routeCoordinates = HomeView.sampleRoute
                    mgr.distance = Double(coords.count) * 10.0
                    mgr.duration = 120
                    mgr.avgSpeed = mgr.distance / mgr.duration
                    mgr.currentSpeed = 5
                    // override the @State initial value
                    // _ = HomeView().session // no longer needed; just illustrative
                }
                .previewDisplayName("Sample Session")
        }
        .previewLayout(.sizeThatFits)
    }
}

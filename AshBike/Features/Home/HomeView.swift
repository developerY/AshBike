//
//  HomeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI
import Observation
import MapKit
import SwiftData

struct HomeView: View {
    // Use @State instead of @StateObject for the new @Observable model
    @Environment(RideSessionManager.self) private var session
    @Environment(RideDataManager.self) private var rideDataManager
    
    // --- ADD THIS STATE FOR ALERTS ---
    @State private var appAlert: AppAlert?
    
    // --- ADDED ---
    // A query to fetch the user's profile from SwiftData.
    @Query private var profiles: [UserProfile]

    // State for the accordion sections
    private enum ExpandedSection {
        case metrics, ebike
    }
    @State private var expandedSection: ExpandedSection? = .metrics
    @State private var isShowingMapSheet = false

    // --- UPDATED ---
    // Use two immutable static formatters to avoid mutating shared state.
    private static let hmsFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()

    private static let msFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // — Gauge —
                    GaugeView(
                        speed: session.currentSpeed * 3.6,
                        heading: session.heading,
                        onMapButtonTapped: {
                            isShowingMapSheet = true
                        }
                    )
                    .equatable()
                    .transaction { $0.disablesAnimations = true }
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
                        LiveMetricsView(
                            distance: session.distance,
                            durationText: formattedDuration(session.duration),
                            avgSpeed: session.avgSpeed,
                            heartRate: session.heartRate,
                            calories: session.calories
                        )
                        .equatable()
                        .transaction { $0.disablesAnimations = true }
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
                }
                .padding(.vertical)
            }
            
            // — Controls —
            HStack(spacing: 40) {
                // --- MODIFIED ---
                // The Play button now fetches the user's weight and passes it
                // to the session manager.
                Button(action: {
                    // Use the first profile's weight, or a default if no profile exists.
                    let userWeight = profiles.first?.weightKg ?? 75.0
                    session.start(userWeightKg: userWeight)
                }) {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.isRecording)

                // --- MODIFIED ---
                // The Stop button's action now runs an async task to handle saving.
                // --- MODIFY THE STOP BUTTON'S ACTION ---
                Button(action: {
                    Task {
                        if let ride = session.stop() {
                            do {
                                try await rideDataManager.save(ride: ride)
                                // Optionally show a success alert
                                // appAlert = AppAlert(title: "Ride Saved", message: "Your ride was successfully saved.")
                            } catch {
                                // Show an error alert on failure
                                appAlert = AppAlert(title: "Save Failed", message: "Your ride could not be saved. Please try again.")
                            }
                        }
                    }
                }) {
                    Image(systemName: "stop.fill")                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!session.isRecording)
            }
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $isShowingMapSheet) {
            LiveRouteSheetView(route: session.routeCoordinates)
                .equatable()
                .transaction { $0.disablesAnimations = true }
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
        }
        // --- ADD THIS MODIFIER TO THE END OF THE VIEW ---
        .alert(item: $appAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func formattedDuration(_ sec: TimeInterval) -> String {
        let fmt = sec >= 3600 ? HomeView.hmsFormatter : HomeView.msFormatter
        return fmt.string(from: sec) ?? "00:00"
    }
}

private struct LiveMetricsView: View, Equatable {
    let distance: Double
    let durationText: String
    let avgSpeed: Double
    let heartRate: Double
    let calories: Int

    static func == (lhs: LiveMetricsView, rhs: LiveMetricsView) -> Bool {
        lhs.distance == rhs.distance &&
        lhs.durationText == rhs.durationText &&
        lhs.avgSpeed == rhs.avgSpeed &&
        lhs.heartRate == rhs.heartRate &&
        lhs.calories == rhs.calories
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                MetricCard(label: "Distance", value: String(format: "%.1f km", distance / 1000))
                MetricCard(label: "Duration", value: durationText)
                MetricCard(label: "Avg Speed", value: String(format: "%.1f km/h", avgSpeed * 3.6))
            }
            HStack(spacing: 12) {
                MetricCard(
                    label: "Heart Rate",
                    value: heartRate > 0 ? String(format: "%.0f bpm", heartRate) : "-- bpm"
                )
                MetricCard(label: "Calories", value: "\(calories) kcal")
            }
        }
        .padding(.top, 8)
    }
}

private struct LiveRouteSheetView: View, Equatable {
    let route: [CLLocationCoordinate2D]

    // Equatable conformance: compare lightweight snapshot to reduce recomputations
    static func == (lhs: LiveRouteSheetView, rhs: LiveRouteSheetView) -> Bool {
        guard lhs.route.count == rhs.route.count else { return false }
        let l = lhs.route.last
        let r = rhs.route.last
        return l?.latitude == r?.latitude && l?.longitude == r?.longitude
    }

    // Gating state
    @State private var displayedRoute: [CLLocationCoordinate2D] = []
    @State private var lastUpdate: Date = .distantPast

    // Tuning knobs
    private let minUpdateInterval: TimeInterval = 2.0 // seconds
    private let minDistanceMeters: Double = 10.0 // meters

    // 1. Define an Equatable struct to hold the values we want to observe.
    private struct RouteSnapshot: Equatable {
        let count: Int
        let lastLat: CLLocationDegrees?
        let lastLon: CLLocationDegrees?
    }
    
    // 2. Create a computed property that builds this struct from the route.
    private var routeSnapshot: RouteSnapshot {
        RouteSnapshot(
            count: route.count,
            lastLat: route.last?.latitude,
            lastLon: route.last?.longitude
        )
    }
    
    var body: some View {
        VStack {
            Capsule()
                .fill(Color.secondary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Live Route")
                .font(.headline)
                .padding()
            
            // --- THIS IS THE FIX ---
            // Changed from RouteMapView to RideMapView
            RideMapView(route: displayedRoute)
        }
        .onAppear {
            displayedRoute = thinRoute(route, minDistanceMeters: minDistanceMeters)
            lastUpdate = Date()
        }
        // --- THIS IS THE FIX ---
        // 3. Observe the Equatable struct using the zero-parameter closure.
        .onChange(of: routeSnapshot) {
            let now = Date()
            let timeOK = now.timeIntervalSince(lastUpdate) >= minUpdateInterval
            let distOK = hasMovedEnough(from: displayedRoute.last, to: route.last, thresholdMeters: minDistanceMeters)
            if timeOK || distOK {
                displayedRoute = thinRoute(route, minDistanceMeters: minDistanceMeters)
                lastUpdate = now
            }
        }
    }

    // MARK: - Helpers

    private func hasMovedEnough(from a: CLLocationCoordinate2D?, to b: CLLocationCoordinate2D?, thresholdMeters: Double) -> Bool {
        guard let a = a, let b = b else { return true }
        return haversineDistanceMeters(a, b) >= thresholdMeters
    }

    private func thinRoute(_ points: [CLLocationCoordinate2D], minDistanceMeters: Double) -> [CLLocationCoordinate2D] {
        guard var last = points.first else { return [] }
        var result: [CLLocationCoordinate2D] = [last]
        for p in points.dropFirst() {
            if haversineDistanceMeters(last, p) >= minDistanceMeters {
                result.append(p)
                last = p
            }
        }
        return result
    }

    // Haversine distance in meters
    private func haversineDistanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let sinDLat = sin(dLat / 2)
        let sinDLon = sin(dLon / 2)
        let aVal = sinDLat * sinDLat + sinDLon * sinDLon * cos(lat1) * cos(lat2)
        let c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal))
        return R * c
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Create instances of all the required services.
        let appSettings = AppSettings()
        let healthKitService = HealthKitService()
        
        // 2. Create the data manager with an in-memory container for the preview.
        let modelContainer = try! ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let rideDataManager = RideDataManager(modelContainer: modelContainer)
        
        // 3. Create the RideSessionManager, injecting its dependencies.
        let rideSessionManager = RideSessionManager(
            healthKitService: healthKitService,
            appSettings: appSettings
        )

        // 4. Return the HomeView and inject all services into the environment,
        //    mirroring the setup in AshBikeApp.swift.
        HomeView()
            .environment(appSettings)
            .environment(healthKitService)
            .environment(rideSessionManager)
            .environment(rideDataManager)
            .modelContainer(modelContainer)
    }
}

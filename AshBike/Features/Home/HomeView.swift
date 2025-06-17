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

    // --- MODIFIED ---
    // The formatter is now a static constant for better performance.
    private static let durationFormatter: DateComponentsFormatter = {
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = [.hour, .minute, .second]
        fmt.zeroFormattingBehavior = .pad
        return fmt
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
            // ** THIS IS THE FIX **
            // This modifier makes the sheet's background transparent,
            // preventing the view behind it from dimming.
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
        // Use the static formatter. Adjust units based on duration.
        HomeView.durationFormatter.allowedUnits = sec >= 3600
            ? [.hour, .minute, .second]
            : [.minute, .second]
        return HomeView.durationFormatter.string(from: sec) ?? "00:00"
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(RideSessionManager())
            .environment(RideDataManager(modelContainer: try! ModelContainer(for: UserProfile.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
    }
}

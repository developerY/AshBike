//
//  RideSessionManager.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import Foundation
import CoreLocation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RideSessionManager: NSObject, @MainActor CLLocationManagerDelegate {
    // --- 1. UI-FACING PROPERTIES ---
    // These are read by the UI and will now update on a fixed timer.
    var currentSpeed: Double = 0
    var heading: CLLocationDirection = 0
    
    // --- ADD THE HEART RATE PROPERTY ---
    var heartRate: Double = 0
    
    // Recorded properties (only tracked during a ride)
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var calories: Int = 0
    
    // --- MODIFIED ---
    // Now stores the full CLLocation object to preserve the timestamp of each point.
    var route: [CLLocation] = []
    
    // Expose just the coordinates for the map view.
    var routeCoordinates: [CLLocationCoordinate2D] {
        route.map { $0.coordinate }
    }
    
    // State management
    var isRecording = false
    
    // --- MODIFIED ---
    // The hardcoded weight is removed and replaced with a private property
    // that will be set when a ride starts.
    private var userWeight: Double = 75 // A default weight in kg.
    
    // --- 1. DEFINE PROPERTIES TO HOLD THE DEPENDENCIES ---
    // This requires access to the HealthKitService from the environment
    private let healthKitService: HealthKitService
    private let appSettings: AppSettings

    private let locationManager = CLLocationManager()
    
    // --- 2. INTERNAL "LATCH" PROPERTIES ---
    // These get updated rapidly by CoreLocation on any thread.
    private var lastKnownSpeed: Double = 0
    private var lastKnownHeading: CLLocationDirection = 0

    // --- 3. TIMERS ---
    // This timer updates the live ride metrics (duration, calories, etc.)
    private var recordingTimer: Timer?
    // This timer throttles high-frequency UI updates for the gauge.
    private var uiUpdateTimer: Timer?


    // Location tuning constants
    private let idleDesiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    private let recordingDesiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    private let idleDistanceFilter: CLLocationDistance = 25 // meters
    private let recordingDistanceFilter: CLLocationDistance = 5 // meters
    private let headingChangeThreshold: CLLocationDegrees = 5 // degrees

    // Check if the app has Location background capability
    private var hasLocationBackgroundCapability: Bool {
        if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            return modes.contains("location")
        }
        return false
    }

    // Configure manager for low-power idle tracking
    private func configureForIdle() {
        locationManager.desiredAccuracy = idleDesiredAccuracy
        locationManager.distanceFilter = idleDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.headingFilter = headingChangeThreshold
    }

    // Configure manager for high-accuracy recording
    private func configureForRecording() {
        locationManager.desiredAccuracy = recordingDesiredAccuracy
        locationManager.distanceFilter = recordingDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = hasLocationBackgroundCapability
        locationManager.headingFilter = headingChangeThreshold
    }

    private var startDate: Date?
    
    init(healthKitService: HealthKitService, appSettings: AppSettings) {
        self.healthKitService = healthKitService
        self.appSettings = appSettings
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.requestWhenInUseAuthorization()

        // Start in low-power idle mode (still updates for the gauge)
        configureForIdle()
        // Note: Location updates are now started via startIdleMonitoring()
        // from the view's .onAppear modifier.
        // locationManager.startUpdatingLocation()
        // locationManager.startUpdatingHeading()
    }
    
    // --- ADD THESE TWO PUBLIC METHODS ---
    public func startIdleMonitoring() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        startUiUpdateTimer() // Start the UI throttle timer
    }

    public func stopIdleMonitoring() {
        // Only stop if we are NOT recording a ride
        if !isRecording {
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
            stopUiUpdateTimer() // Stop the UI throttle timer
        }
    }
    
    // --- 4. UI THROTTLE TIMER ---
    private func startUiUpdateTimer() {
        stopUiUpdateTimer() // Ensure no duplicates
        // Update the UI 5 times per second (0.2s interval)
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // On the timer fire, publish the latched values to the UI
            Task { @MainActor in
                self.currentSpeed = self.lastKnownSpeed
                self.heading = self.lastKnownHeading
            }
        }
        if let timer = self.uiUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopUiUpdateTimer() {
        uiUpdateTimer?.invalidate()
        uiUpdateTimer = nil
    }


    // --- MODIFIED ---
    // The start method now accepts the user's weight.
    // --- MODIFY THE START AND STOP METHODS ---
    // --- 3. MODIFY THE START METHOD TO CHECK THE TOGGLE STATE ---
    func start(userWeightKg: Double) {
        guard !isRecording else { return }
        
        // ... (reset metrics, start timer, etc.) ...
        self.userWeight = userWeightKg
        
        resetRecordingMetrics()
        configureForRecording() // Switch to high-accuracy
        
        // Ensure UI timer is running
        startUiUpdateTimer()
        
        startDate = Date()
        startRecordingTimer() // Start the 1-second timer for duration/calories
        isRecording = true
        
        // --- THIS IS THE CRITICAL CHECK ---
        // Only start observing heart rate if the feature is enabled in settings.
        if appSettings.isHealthKitEnabled {
            healthKitService.startObservingHeartRate { [weak self] newHeartRate in
                self?.heartRate = newHeartRate
            }
        }
    }
    
    
    // This method now only stops the timer
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // --- MODIFIED ---
    // This function now stops the recording and returns the generated ride,
    // but does not save it.
    func stop() -> BikeRide? {
        guard isRecording else { return nil }
        
        // Stop observing heart rate
        healthKitService.stopObservingHeartRate()
        configureForIdle() // Switch back to low-power
        
        stopRecordingTimer() // Stop the 1-second timer
        
        // We leave the uiUpdateTimer running for the idle gauge
        // stopUiUpdateTimer() // <-- DO NOT STOP THIS
        
        let ride = generateBikeRide()
        
        isRecording = false
        resetRecordingMetrics()
        
        return ride
    }

    // --- MODIFY THE RESET METHOD ---
    private func resetRecordingMetrics() {
        distance = 0
        duration = 0
        avgSpeed = 0
        maxSpeed = 0
        calories = 0
        heartRate = 0 // Reset heart rate
        startDate = nil
        route.removeAll()
    }

    private func generateBikeRide() -> BikeRide? {
        guard let start = startDate, duration > 0 else { return nil }

        // --- MODIFIED ---
        // Creates RideLocation objects using the preserved timestamp from each point in the route.
        let rideLocations = route.map {
            RideLocation(timestamp: $0.timestamp, lat: $0.coordinate.latitude, lon: $0.coordinate.longitude, speed: $0.speed)
        }

        return BikeRide(
            startTime: start,
            endTime: Date(),
            totalDistance: distance,
            avgSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            elevationGain: 0, // Placeholder
            calories: calories,
            notes: nil,
            locations: rideLocations
        )
    }

    nonisolated private func metForSpeed(_ speed: Double) -> Double {
        let kmh = speed * 3.6
        switch kmh {
            case ..<10: return 4.0
            case 10..<14: return 6.0
            case 14..<20: return 8.0
            default: return 10.0
        }
    }

    // This is the 1-second timer for duration/calories/avgSpeed
    private func startRecordingTimer() {
        stopRecordingTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard let start = self.startDate else { return }
                self.duration = Date().timeIntervalSince(start)
                if self.duration > 0 {
                    self.avgSpeed = self.distance / self.duration
                }
                // --- MODIFIED ---
                // The calorie calculation now uses the userWeight property.
                // We use lastKnownSpeed for a more accurate MET value
                let kcal = self.metForSpeed(self.lastKnownSpeed) * self.userWeight * (self.duration / 3600)
                self.calories = Int(kcal)
            }
        }
        if let timer = self.recordingTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLoc = locations.last else { return }

        // Discard stale or low-quality samples
        let age = -newLoc.timestamp.timeIntervalSinceNow
        if age > 3 { return } // older than 3 seconds
        if newLoc.horizontalAccuracy < 0 || newLoc.horizontalAccuracy > 50 { return } // poor accuracy

        // Compute non-negative speed
        let clampedSpeed = max(0, newLoc.speed)

        // --- 5. UPDATE THE LATCH, NOT THE PUBLISHED PROPERTY ---
        // This is cheap and does NOT trigger a UI update.
        self.lastKnownSpeed = clampedSpeed
        // currentSpeed = clampedSpeed // <-- REMOVED

        // If we're not recording, don't update route/distance
        guard isRecording else { return }
        
        maxSpeed = max(maxSpeed, clampedSpeed)

        if let last = route.last {
            let delta = newLoc.distance(from: last)
            // Throttle: only append and accumulate distance when moved at least 5 meters
            if delta >= 5 {
                distance += delta
                route.append(newLoc)
            }
        } else {
            // First point of the recording
            route.append(newLoc)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // --- 6. UPDATE THE LATCH, NOT THE PUBLISHED PROPERTY ---
        self.lastKnownHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        // self.heading = ... // <-- REMOVED
    }
}

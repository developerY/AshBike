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

@Observable
final class RideSessionManager: NSObject, CLLocationManagerDelegate {
    // Live-tracked properties (always on)
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

    private let locationManager = CLLocationManager()
    private var startDate: Date?
    private var timer: Timer?
    
    // This requires access to the HealthKitService from the environment
    private var healthKitService = HealthKitService()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Start tracking live data immediately
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    // --- MODIFIED ---
    // The start method now accepts the user's weight.
    // --- MODIFY THE START AND STOP METHODS ---
    func start(userWeightKg: Double) {
        guard !isRecording else { return }
        
        // Store the user's weight for the new ride
        self.userWeight = userWeightKg
        
        resetRecordingMetrics()
        
        startDate = Date()
        startTimer()
        isRecording = true

        // Start observing heart rate
        healthKitService.startObservingHeartRate { [weak self] newHeartRate in
            self?.heartRate = newHeartRate
        }
    }
    
    
    // This method now only stops the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // --- MODIFIED ---
    // This function now stops the recording and returns the generated ride,
    // but does not save it.
    func stop() -> BikeRide? {
        guard isRecording else { return nil }
        
        // Stop observing heart rate
        healthKitService.stopObservingHeartRate()
        
        stopTimer()
        
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

    private func metForSpeed(_ speed: Double) -> Double {
        let kmh = speed * 3.6
        switch kmh {
            case ..<10: return 4.0
            case 10..<14: return 6.0
            case 14..<20: return 8.0
            default: return 10.0
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            self.duration = Date().timeIntervalSince(start)
            if self.duration > 0 {
                self.avgSpeed = self.distance / self.duration
            }
            // --- MODIFIED ---
            // The calorie calculation now uses the userWeight property.
            let kcal = self.metForSpeed(self.currentSpeed) * self.userWeight * (self.duration / 3600)
            self.calories = Int(kcal)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLoc = locations.last else { return }
        
        // Always update the current speed
        currentSpeed = max(0, newLoc.speed)
        
        // Only update recording metrics if a ride is in progress
        if isRecording {
            maxSpeed = max(maxSpeed, currentSpeed)
            if let last = route.last {
                distance += newLoc.distance(from: last)
            }
            // Append the full CLLocation object.
            route.append(newLoc)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Always update the heading
        self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}

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
    
    // Recorded properties (only tracked during a ride)
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var calories: Int = 0
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // State management
    var isRecording = false
    var weight: Double = 72
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var startDate: Date?
    private var timer: Timer?

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

    // Call this to begin recording a ride
    func start() {
        guard !isRecording else { return } // Prevent starting a new ride if one is active
        // Reset all recording metrics for a new ride
        distance = 0
        duration = 0
        avgSpeed = 0
        maxSpeed = 0
        calories = 0
        routeCoordinates.removeAll()
        lastLocation = nil
        
        startDate = Date()
        startTimer()
        isRecording = true
    }

    // This method now only stops the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // This function stops the recording and saves the ride
    func stopAndSave(context: ModelContext) {
        guard isRecording else { return } // Prevent saving if not recording
        
        stopTimer()
        
        if let ride = generateBikeRide() {
            context.insert(ride)
            try? context.save()
        }
        
        isRecording = false
        resetRecordingMetrics()
    }
    
    // Resets only the properties related to a recorded ride
    private func resetRecordingMetrics() {
        distance = 0
        duration = 0
        avgSpeed = 0
        maxSpeed = 0
        calories = 0
        startDate = nil
        lastLocation = nil
        routeCoordinates.removeAll()
    }

    private func generateBikeRide() -> BikeRide? {
        guard let start = startDate, duration > 0 else { return nil }

        return BikeRide(
            startTime: start,
            endTime: Date(),
            totalDistance: distance,
            avgSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            elevationGain: 0, // Placeholder
            calories: calories,
            notes: nil,
            locations: routeCoordinates.map {
                RideLocation(timestamp: Date(), lat: $0.latitude, lon: $0.longitude)
            }
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
        stopTimer() // Ensure no previous timer is running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            self.duration = Date().timeIntervalSince(start)
            if self.duration > 0 {
                self.avgSpeed = self.distance / self.duration
            }
            let kcal = self.metForSpeed(self.currentSpeed) * self.weight * (self.duration / 3600)
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
            if let last = lastLocation {
                distance += newLoc.distance(from: last)
            }
            lastLocation = newLoc
            routeCoordinates.append(newLoc.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Always update the heading
        self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}

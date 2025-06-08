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
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var currentSpeed: Double = 0
    var calories: Int = 0
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var heading: CLLocationDirection = 0
    
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
    }

    func start() {
        // Reset all metrics for a new ride
        distance = 0
        duration = 0
        avgSpeed = 0
        maxSpeed = 0
        currentSpeed = 0
        calories = 0
        routeCoordinates.removeAll()
        lastLocation = nil
        
        startDate = Date()
        startTimer()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func pause() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        timer?.invalidate()
    }
    
    // The existing stop function is renamed to a more descriptive 'reset'
    func reset() {
        pause()
        startDate = nil
    }
    
    // NEW: This function stops the ride and saves it to SwiftData
    func stopAndSave(context: ModelContext) {
        pause() // Stop timers and location updates
        
        guard let ride = generateBikeRide() else {
            reset() // Reset even if we can't save
            return
        }
        
        context.insert(ride)
        try? context.save() // It's good practice to handle potential save errors
        
        reset() // Reset the session for the next ride
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
        timer?.invalidate()
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLoc = locations.last else { return }
        currentSpeed = max(0, newLoc.speed)
        maxSpeed = max(maxSpeed, currentSpeed)
        if let last = lastLocation {
            distance += newLoc.distance(from: last)
        }
        lastLocation = newLoc
        routeCoordinates.append(newLoc.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}

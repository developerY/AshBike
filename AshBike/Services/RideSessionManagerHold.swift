//
//  RideSessionManager.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
// Services/RideSessionManager.swift
import Foundation
import CoreLocation
import Observation
import SwiftData
import SwiftUI  // for DateComponentsFormatter if you put formatting here

@Observable
@MainActor
final class RideSessionManagerHold: NSObject, CLLocationManagerDelegate {
    // Exposed metrics (meters, seconds, m/s, m/s, bpm, kcal)
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var currentSpeed: Double = 0
    var heartRate: Int? = nil      // hook into HealthKit similarly
    var calories: Int = 0          // stub, you can calculate off METs + weight
    
    var weight: Double = 72
    private let met: Double = 8.0

    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var startDate: Date?
    private var timer: Timer?
    
    /// The GPS trace so far
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        super.init()
        self.modelContext = modelContext
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Call when the user taps “Start”
    func start() {
        distance = 0
        duration = 0
        avgSpeed = 0
        maxSpeed = 0
        currentSpeed = 0
        lastLocation = nil
        startDate = Date()
        startTimer()
        locationManager.startUpdatingLocation()
        // TODO: start heart‐rate & calorie tracking via HealthKit
    }
    
    /// Call when the user taps “Pause”
    func pause() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    /// Call when the user taps “Stop”
    func stop() {
        pause()
        // TODO: finalize HealthKit samples, save ride record
    }
    
    @MainActor
    func stopAndSaveRide() {
        pause()

        guard let start = startDate else { return }

        let newRide = BikeRide(
            startTime: start,
            endTime: Date(),
            totalDistance: distance,
            avgSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            elevationGain: 0, // add real elevation gain if you track it
            calories: calories,
            notes: nil,
            locations: routeCoordinates.map {
                RideLocation(timestamp: Date(), lat: $0.latitude, lon: $0.longitude)
            }
        )

        modelContext?.insert(newRide)

        do {
            try modelContext?.save()
        } catch {
            print("Error saving ride: \(error)")
        }
    }
    
    
    // Inside RideSessionManager

    /// Return an approximate MET value based on currentSpeed (m/s)
    private static func metForSpeed(_ speed: Double) -> Double {
        let kmh = speed * 3.6
        switch kmh {
        case ..<10:
            return 4.0     // light effort (<10 km/h)
        case 10..<14:
            return 6.0     // moderate (<14 km/h)
        case 14..<20:
            return 8.0     // brisk (<20 km/h)
        default:
            return 10.0    // very vigorous (20+ km/h)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let start = self.startDate else { return }
            
            // update duration & average speed
            self.duration = Date().timeIntervalSince(start)
            if self.duration > 0 {
                self.avgSpeed = self.distance / self.duration
            }

            // dynamic MET from speed
            let met = RideSessionManagerHold.metForSpeed(self.currentSpeed)
            let hours = self.duration / 3600
            let kcal = met * self.weight * hours
            self.calories = Int(kcal)
        }
    }
    
    // MARK: – CLLocationManagerDelegate
    
    func locationManager(
      _ manager: CLLocationManager,
      didUpdateLocations locations: [CLLocation]
    ) {
        guard let newLoc = locations.last else { return }
        // speed in m/s
        let spd = max(0, newLoc.speed)
        currentSpeed = spd
        maxSpeed = max(maxSpeed, spd)
        
        if let last = lastLocation {
            let delta = newLoc.distance(from: last)
            distance += delta
        }
        lastLocation = newLoc
        
        
        // **Append the new point**
        routeCoordinates.append(newLoc.coordinate)
    }
    
    func locationManager(
      _ manager: CLLocationManager,
      didFailWithError error: Error
    ) {
        print("Location error:", error)
    }
}


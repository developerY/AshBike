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
import SwiftUI  // for DateComponentsFormatter if you put formatting here

@Observable
final class RideSessionManager: NSObject, CLLocationManagerDelegate {
    // Exposed metrics (meters, seconds, m/s, m/s, bpm, kcal)
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var currentSpeed: Double = 0
    var heartRate: Int? = nil      // hook into HealthKit similarly
    var calories: Int = 0          // stub, you can calculate off METs + weight
    
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
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let start = self.startDate else { return }
            self.duration = Date().timeIntervalSince(start)
            if self.duration > 0 {
                self.avgSpeed = self.distance / self.duration
            }
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
    }
    
    func locationManager(
      _ manager: CLLocationManager,
      didFailWithError error: Error
    ) {
        print("Location error:", error)
    }
}


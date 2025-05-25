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
import SwiftUI  // for DateComponentsFormatter if you put formatting here

@Observable
final class RideSessionManager: NSObject, CLLocationManagerDelegate {
    var distance: Double = 0
    var duration: TimeInterval = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var currentSpeed: Double = 0
    var calories: Int = 0
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
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
        distance = 0; duration = 0; avgSpeed = 0; maxSpeed = 0; currentSpeed = 0; calories = 0
        routeCoordinates.removeAll()
        lastLocation = nil
        startDate = Date()
        startTimer()
        locationManager.startUpdatingLocation()
    }

    func pause() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
    }

    func stop() {
        pause()
    }
    
    @MainActor
    func stopAndPersistRide(using store: RideStore) async {
        stop()
        guard let ride = generateBikeRide() else { return }
        do {
            try await store.saveRide(ride)
        } catch {
            print("Save failed:", error)
        }
    }


    func generateBikeRide() -> BikeRide? {
        guard let start = startDate else { return nil }

        return BikeRide(
            startTime: start,
            endTime: Date(),
            totalDistance: distance,
            avgSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            elevationGain: 0,
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
            self.avgSpeed = self.distance / max(self.duration, 1)
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
}


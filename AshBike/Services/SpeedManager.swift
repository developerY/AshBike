//
//  SpeedManager.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// SpeedManager.swift
import Foundation
import CoreLocation
import SwiftUI

@Observable
class SpeedManager: NSObject, CLLocationManagerDelegate {
  /// Current speed in meters per second
  var speed: Double = 0

  private let locationManager = CLLocationManager()

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.activityType = .fitness
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let last = locations.last else { return }
    // CLLocation.speed is in m/s; negative means “invalid”
    if last.speed >= 0 {
      speed = last.speed
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    print("Location error:", error)
  }
}


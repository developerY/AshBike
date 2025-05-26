//
//  Untitled.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import Foundation
import CoreLocation

func makeRandomBikeRide(
  duration: TimeInterval = 3600,   // 1h
  points:   Int           = 20,    // GPS fixes
  weightKg: Double        = 70
) -> BikeRide {
  let now       = Date()
  let startTime = now.addingTimeInterval(-duration)
  let endTime   = now

  // spread timestamps
  let dt = duration / Double(max(points - 1, 1))
  let stamps = (0..<points).map { i in
    startTime.addingTimeInterval(Double(i) * dt)
  }

  // generate random points
  let locs = stamps.map { RideLocation.random(at: $0) }

  // total distance
  let dist = zip(locs, locs.dropFirst()).reduce(0) { sum, pair in
    let (a, b) = pair
    let ca = CLLocation(latitude: a.latitude,  longitude: a.longitude)
    let cb = CLLocation(latitude: b.latitude,  longitude: b.longitude)
    return sum + ca.distance(from: cb)
  }

  // speeds
  let speeds   = locs.compactMap { $0.speed }
  let avgSpd   = dist / duration
  let maxSpd   = speeds.max() ?? avgSpd

  // calories @ MET=8
  let hrs      = duration / 3600
  let calories = Int(8 * weightKg * hrs)

  return BikeRide(
    startTime:     startTime,
    endTime:       endTime,
    totalDistance: dist,
    avgSpeed:      avgSpd,
    maxSpeed:      maxSpd,
    elevationGain: 0,
    calories:      calories,
    notes:         "🛠 debug ride",
    locations:     locs
  )
}


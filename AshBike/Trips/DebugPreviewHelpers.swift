//
//  Untitled.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import Foundation
import CoreLocation

func makeRandomBikeRideOrig(
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


// 20 minutes ago
let startPoint = RideLocation.random(at: Date().addingTimeInterval(-1200))
// 10 minutes ago
let earlierPoint = RideLocation.random(at: Date().addingTimeInterval(-600))
let nowPoint     = RideLocation.random()

// Sample GPS points
let sampleLocations: [RideLocation] = [
    nowPoint,
    earlierPoint,
    
]

// Instantiate a BikeRide
let bikeItem = BikeRide(
    startTime: .now.addingTimeInterval(-3600),     // 1 hour ago
    endTime:   .now,                               // now
    totalDistance: 25_000,                         // meters (25 km)
    avgSpeed:      6.94,                           // m/s (~25 km/h)
    maxSpeed:     12.5,                            // m/s (~45 km/h)
    elevationGain: 300,                            // meters climbed
    calories:      750,                            // kcal
    notes:         "Great loop through the park!",
    locations:     sampleLocations
)


extension RideLocation {
    /// 1) Completely random location with timestamp = now
    static func random() -> RideLocation {
        return .random(at: Date())
    }

    /// 2) Random location at a specific timestamp
    ///
    /// - Parameter timestamp: the Date to assign
    /// - Returns: a new RideLocation with random coords & speed
    static func random(at timestamp: Date) -> RideLocation {
        // Latitude between -90° and +90°
        let latitude  = Double.random(in: -90...90)
        // Longitude between -180° and +180°
        let longitude = Double.random(in: -180...180)
        // Speed in m/s, say 0–15 m/s (~0–54 km/h)
        let speed     = Double.random(in: 0...15)

        return RideLocation(
            timestamp: timestamp,
            lat: latitude,
            lon: longitude,
            speed: speed
        )
    }
}

/*
 random points to a specific area (e.g. around your home)
 let lat = Double.random(in: 37.33...37.35)
 let lon = Double.random(in: -122.05...-122.00)

 */


// A little helper to create random demo rides -- no args
func makeRandomBikeRide() -> BikeRide {
  let start = Date().addingTimeInterval(-Double.random(in: 600...3600))
  let end   = Date()
  let dist  = Double.random(in: 500...10_000)
  let avg   = dist / (end.timeIntervalSince(start))
  let max   = avg * Double.random(in: 1.1...1.5)
  return BikeRide(
    startTime: start,
    endTime:   end,
    totalDistance: dist,
    avgSpeed:      avg,
    maxSpeed:      max,
    elevationGain: Double.random(in: 0...200),
    calories:      Int(avg * 3.6 * 60 / 20), // totally made‐up formula
    notes:         nil,
    locations:     []
  )
}



/// Generate a completely random BikeRide for testing / previews
func makeRandomBikeRide(
  duration: TimeInterval = 3600,  // total ride time in seconds (1 h)
  pointCount: Int        = 20,    // number of GPS fixes
  weightKg: Double       = 70     // user weight for calories calc
) -> BikeRide {
  let now       = Date()
  let startTime = now.addingTimeInterval(-duration)
  let endTime   = now

  // 1) Spread timestamps evenly between start and end
  let interval = duration / Double(max(pointCount - 1, 1))
  let timestamps = (0..<pointCount).map { i in
    startTime.addingTimeInterval(Double(i) * interval)
  }

  // 2) Generate random locations at each timestamp
  let locations = timestamps.map(RideLocation.random(at:))

  // 3) Stub totalDistance as sum of random segments (0–500 m apart)
  let totalDistance = zip(locations, locations.dropFirst()).reduce(0) { sum, pair in
    let (a, b) = pair
    let coordA = CLLocation(latitude: a.latitude, longitude: a.longitude)
    let coordB = CLLocation(latitude: b.latitude, longitude: b.longitude)
    return sum + coordA.distance(from: coordB)
  }

  // 4) Compute avg & max speed from the segments (m/s)
  let speeds = locations.compactMap { $0.speed }
  let avgSpeed = totalDistance / duration
  let maxSpeed = speeds.max() ?? avgSpeed

  // 5) Simple calories: MET(=8) × weight(kg) × hours
  let hours   = duration / 3600
  let calories = Int(8.0 * weightKg * hours)

  // 6) Build and return
  return BikeRide(
    startTime:     startTime,
    endTime:       endTime,
    totalDistance: totalDistance,
    avgSpeed:      avgSpeed,
    maxSpeed:      maxSpeed,
    elevationGain: 0,
    calories:      calories,
    notes:         "Randomly generated ride",
    locations:     locations
  )
}

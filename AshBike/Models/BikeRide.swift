//
//  BikeRide.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import Foundation
import SwiftData

@Model
public class BikeRide: Identifiable {
    //@Attribute(.unique) public var id: UUID = .init()
    @Attribute(.unique) public var id: UUID

    
    /// When the ride started
    public var startTime: Date
    
    /// When the ride ended
    public var endTime: Date
    
    /// Total distance in meters
    public var totalDistance: Double
    
    /// Average speed over the ride in m/s
    public var avgSpeed: Double
    
    /// Maximum speed reached in m/s
    public var maxSpeed: Double
    
    /// Total elevation gain in meters
    public var elevationGain: Double
    
    /// Calories burned
    public var calories: Int
    
    /// Optional rider notes
    public var notes: String?
    
    /// The sequence of recorded GPS points
    var locations: [RideLocation]
    
    init(
        startTime: Date = .now,
        endTime: Date = .now,
        totalDistance: Double = 0,
        avgSpeed: Double = 0,
        maxSpeed: Double = 0,
        elevationGain: Double = 0,
        calories: Int = 0,
        notes: String? = nil,
        locations: [RideLocation] = []
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.totalDistance = totalDistance
        self.avgSpeed = avgSpeed
        self.maxSpeed = maxSpeed
        self.elevationGain = elevationGain
        self.calories = calories
        self.notes = notes
        self.locations = locations
    }
    
    /// Computed duration in seconds
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}


// MARK: – somewhere in your file
extension BikeRide: Hashable {
  public static func == (lhs: BikeRide, rhs: BikeRide) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}


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
    @Attribute(.unique) public var id: UUID
    
    public var startTime: Date
    public var endTime: Date
    public var totalDistance: Double
    public var avgSpeed: Double
    public var maxSpeed: Double
    public var elevationGain: Double
    public var calories: Int
    public var notes: String?
    // --- MODIFY THIS LINE ---
    @Relationship(deleteRule: .cascade, inverse: \RideLocation.ride)
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
        isSyncedToHealthKit: Bool = false, // Default to false
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
    
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

extension BikeRide: Hashable {
  public static func == (lhs: BikeRide, rhs: BikeRide) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}


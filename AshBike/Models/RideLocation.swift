//
//  RideLocation.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import SwiftData
import Foundation

@Model
class RideLocation {
  //@Attribute(.unique) var id: UUID = .init()
  @Attribute(.unique) public var id: UUID

  var timestamp: Date
  var latitude: Double
  var longitude: Double
  var speed: Double?

  init(timestamp: Date, lat: Double, lon: Double, speed: Double? = nil) {
      self.id = UUID()
    self.timestamp = timestamp
    self.latitude = lat
    self.longitude = lon
    self.speed = speed
  }
}

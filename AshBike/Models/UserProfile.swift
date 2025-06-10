//
//  UserProfile.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/9/25.
//
import SwiftUI
import SwiftData
@Model
final class UserProfileOrig {
  @Attribute(.unique) var id: UUID // = .init()
  var name: String
  var heightCm: Double
  var weightKg: Double

  init(name: String = "Ash Monster",
       heightCm: Double = 171,
       weightKg: Double = 72)
  {
      self.id = UUID()
    self.name = name
    self.heightCm = heightCm
    self.weightKg = weightKg
  }
}

// MARK: — Profile Model (Existing)
@Model
final class UserAshBikeProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var heightCm: Double
    var weightKg: Double

    init(name: String = "Siamak", heightCm: Double = 180, weightKg: Double = 75) {
        self.name = name
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}

// MARK: — Profile Model (Existing)
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var heightCm: Double
    var weightKg: Double

    init(name: String = "Siamak", heightCm: Double = 180, weightKg: Double = 75) {
        self.name = name
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}

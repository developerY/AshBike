//
//  UserProfile.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/9/25.
//
import SwiftUI
import SwiftData

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

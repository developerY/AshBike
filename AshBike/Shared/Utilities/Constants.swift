//
//  Constants.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/17/25.
//
import Foundation

// A centralized place for constant values used throughout the app.
// Using a case-less enum creates a namespace and prevents instantiation.
enum Constants {

    // Nested enum for HealthKit-specific constants
    enum HealthKit {
        /// The key used to store our app's unique ride ID in HealthKit workout metadata.
        static let rideIdentifierKey = "com.ashbike.ride.id"
    }
    
    // You can add other constants here in the future, for example:
    // enum UserDefaultsKeys {
    //     static let isHealthKitEnabled = "isHealthKitEnabled"
    // }
}

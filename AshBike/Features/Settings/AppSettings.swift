//
//  AppSettings.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/16/25.
//
// MARK: - App Settings State Manager
import SwiftUI

@Observable
class AppSettings {
    // We use UserDefaults to persist these settings across app launches.
    var isHealthKitEnabled: Bool {
        didSet { UserDefaults.standard.set(isHealthKitEnabled, forKey: "isHealthKitEnabled") }
    }
    // These properties are for the beta hardware features.
    // They are set to 'false' by default.
    var isNFCEnabled: Bool = false
    var isQREnabled: Bool = false
    var isBLEEnabled: Bool = false


    init() {
        self.isHealthKitEnabled = UserDefaults.standard.bool(forKey: "isHealthKitEnabled")
        // We won't load the hardware settings from UserDefaults yet,
        // as they are in beta.
    }
}

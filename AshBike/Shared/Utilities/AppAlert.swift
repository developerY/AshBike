//
//  AppAlert.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/17/25.
//
// This struct can be added to any file that needs to show alerts.
// A simple struct to hold alert information.
// Conforming to Identifiable lets us use it with the .alert(item:) modifier.
import Foundation

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

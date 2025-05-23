//
//  Item.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

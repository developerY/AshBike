//
//  ColorSpeed.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/12/25.
//
import CoreGraphics // Still needed for CGFloat which is implicitly used in some SwiftUI contexts, but not directly for Color components in this solution.
import SwiftUI

extension Color {
    // A struct to hold RGBA components as Doubles
    struct RGBAComponents {
        var r, g, b, a: Double
    }

    // Converts a specific SwiftUI system Color to its approximate RGBAComponents.
    // This is a workaround for the lack of direct RGBA component access on SwiftUI.Color
    // without bridging to UIKit/AppKit. Add more cases if your gradient uses other colors.
    func toRGBAComponents() -> RGBAComponents {
        switch self {
        case .green: return RGBAComponents(r: 0.204, g: 0.843, b: 0.294, a: 1.0) // System green
        case .yellow: return RGBAComponents(r: 1.0, g: 0.843, b: 0.0, a: 1.0)    // System yellow
        case .orange: return RGBAComponents(r: 1.0, g: 0.584, b: 0.0, a: 1.0)   // System orange
        case .red: return RGBAComponents(r: 1.0, g: 0.231, b: 0.188, a: 1.0)     // System red
        default:
            // Fallback for any other color. For precise custom colors,
            // you'd typically need their exact RGBA values or a bridging mechanism.
            return RGBAComponents(r: 0.0, g: 0.0, b: 0.0, a: 1.0) // Default to black
        }
    }

    // Interpolates between two colors using their RGBA components.
    // This function now uses the RGBAComponents struct directly.
    static func interpolated(from startColor: Color, to endColor: Color, progress: Double) -> Color {
        let startComponents = startColor.toRGBAComponents()
        let endComponents = endColor.toRGBAComponents()

        let r = startComponents.r + (endComponents.r - startComponents.r) * progress
        let g = startComponents.g + (endComponents.g - startComponents.g) * progress
        let b = startComponents.b + (endComponents.b - startComponents.b) * progress
        let a = startComponents.a + (endComponents.a - startComponents.a) * progress

        return Color(red: r, green: g, blue: b, opacity: a)
    }

    // This function remains the same as it was in the previous solution,
    // it uses the interpolated(from:to:progress:) method.
    static func colorForSpeed(speed: Double, maxSpeed: Double, colors: [Color]) -> Color {
        guard maxSpeed > 0 else { return colors.first ?? .white }

        let normalizedSpeed = min(max(speed / maxSpeed, 0.0), 1.0)

        guard colors.count > 1 else { return colors.first ?? .white }

        let segmentCount = colors.count - 1
        let segmentIndex = Int(normalizedSpeed * Double(segmentCount))
        let segmentProgress = (normalizedSpeed * Double(segmentCount)).truncatingRemainder(dividingBy: 1.0)

        let startColor = colors[segmentIndex]
        let endColor = (segmentIndex + 1 < colors.count) ? colors[segmentIndex + 1] : colors[segmentIndex]

        return Color.interpolated(from: startColor, to: endColor, progress: segmentProgress)
    }
}

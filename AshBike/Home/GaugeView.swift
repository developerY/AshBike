//
//  GaugeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI

// GaugeView.swift
struct GaugeView: View {
    /// Current speed to display (0…maxSpeed)
    var speed: Double
    /// Maximum speed for full circle
    var maxSpeed: Double = 60

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let lineWidth = size * 0.1
            let radius = (size - lineWidth) / 2
            // Clamp percentage between 0 and 1
            let percent = min(max(speed / maxSpeed, 0), 1)

            ZStack {
                // Background track
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

                // Colored progress arc
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(-90))

                // Needle
                Rectangle()
                    .fill(Color.red)
                    // Make needle length equal to radius
                    .frame(width: 2, height: radius)
                    // Pivot around center
                    .offset(y: -radius / 2)
                    .rotationEffect(.degrees(percent * 360))

                // Center cap
                Circle()
                    .fill(Color.white)
                    .frame(width: lineWidth * 1.5, height: lineWidth * 1.5)

                // Speed label
                Text("\(Int(speed))")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GaugeView(speed: 0)
                .padding()
                .previewDisplayName("0 km/h")
                .previewLayout(.sizeThatFits)

            GaugeView(speed: 30)
                .padding()
                .previewDisplayName("30 km/h")
                .previewLayout(.sizeThatFits)

            GaugeView(speed: 60)
                .padding()
                .previewDisplayName("60 km/h")
                .previewLayout(.sizeThatFits)
        }
    }
}

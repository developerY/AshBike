//
//  GaugeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI

struct GaugeView: View {
    var speed: Double
    var heading: Double
    var maxSpeed: Double = 60
    
    // Define the angle range for the gauge
    private let startAngle = Angle(degrees: -225)
    private let endAngle = Angle(degrees: 45)

    var body: some View {
        ZStack {
            // Background Arc
            GaugeArc()
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .fill(Color.gray.opacity(0.4))

            // Gradient Progress Arc
            GaugeArc()
                .trim(from: 0, to: speed / maxSpeed)
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        center: .center,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                )

            // Ticks and Labels
            TicksAndLabels(maxSpeed: maxSpeed)
            
            // Needle
            Needle(speed: speed, maxSpeed: maxSpeed)
                .fill(Color.red)
                .shadow(radius: 2)

            // Center Display
            VStack {
                Text(String(format: "%.0f", speed))
                    .font(.system(size: 60, weight: .bold))
                + Text(" km/h")
                    .font(.system(size: 20, weight: .semibold))
                
                Text(headingString(from: heading))
                    .font(.system(size: 24, weight: .medium))
                    .padding(8)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func headingString(from direction: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((direction + 11.25) / 22.5) % 16
        return String(format: "%.0f° %@", direction, directions[index])
    }
}

// Custom Shape for the Gauge Arc
struct GaugeArc: Shape {
    private let startAngle = Angle(degrees: -225)
    private let endAngle = Angle(degrees: 45)

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return p
    }
}

// View for Needle
struct Needle: Shape {
    var speed: Double
    var maxSpeed: Double
    
    private let startAngle = Angle(degrees: -225)
    private let totalAngle = Angle(degrees: 270)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.9

        let speedRatio = speed / maxSpeed
        let angle = startAngle + (totalAngle * speedRatio)

        let needleBase = CGPoint(
            x: center.x - 10,
            y: center.y
        )
        
        let needleTip = CGPoint(
            x: center.x + radius,
            y: center.y
        )

        path.move(to: needleBase)
        path.addLine(to: needleTip)
        path.addLine(to: CGPoint(x: center.x + 10, y: center.y))
        
        // Apply rotation transform
        return path.applying(CGAffineTransform(translationX: -center.x, y: -center.y))
                   .applying(CGAffineTransform(rotationAngle: CGFloat(angle.radians)))
                   .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}


// View for Ticks and Labels
struct TicksAndLabels: View {
    var maxSpeed: Double
    private let tickCount = 7 // 0, 10, 20, 30, 40, 50, 60
    
    private let startAngle = Angle(degrees: -225)
    private let totalAngle = Angle(degrees: 270)

    var body: some View {
        ZStack {
            ForEach(0..<tickCount) { i in
                let value = Double(i) * (maxSpeed / Double(tickCount - 1))
                let angle = startAngle + (totalAngle * (value / maxSpeed))

                VStack {
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: 10)
                    Text(String(format: "%.0f", value))
                        .font(.caption)
                }
                .rotationEffect(angle - .degrees(90))
                .offset(y: -120) // Adjust this value based on your gauge size
                .rotationEffect(angle)
            }
        }
    }
}


struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        GaugeView(speed: 45, heading: 210)
            .padding()
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}

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
    var onMapButtonTapped: () -> Void // Action to show the map

    // Define the angle range for the gauge
    private let startAngle = Angle(degrees: 135)
    private let endAngle = Angle(degrees: 45)

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let speedProgress = min(speed / maxSpeed, 1.0)
            let strokeStyle = StrokeStyle(lineWidth: radius * 0.15, lineCap: .round)

            ZStack {
                // MARK: - Layer 1: Background & Ticks
                GaugeArc()
                    .stroke(style: strokeStyle)
                    .fill(Color.gray.opacity(0.3))

                TicksAndLabels(center: center, radius: radius)

                // MARK: - Layer 2: Progress Arc
                GaugeArc()
                    .trim(from: 0.0, to: min(speedProgress, 0.333))
                    .stroke(Color.green, style: strokeStyle)
                GaugeArc()
                    .trim(from: 0.333, to: min(speedProgress, 0.666))
                    .stroke(Color.yellow, style: strokeStyle)
                GaugeArc()
                    .trim(from: 0.666, to: min(speedProgress, 0.833))
                    .stroke(Color.orange, style: strokeStyle)
                GaugeArc()
                    .trim(from: 0.833, to: speedProgress)
                    .stroke(Color.red, style: strokeStyle)

                // MARK: - Layer 3: Center Text Display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", speed))
                            .font(.system(size: radius * 0.5, weight: .bold))
                        Text("km/h")
                            .font(.system(size: radius * 0.15, weight: .semibold))
                    }
                    
                    Text(headingString(from: heading))
                        .font(.system(size: radius * 0.18, weight: .medium))
                        .padding(8)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .offset(y: radius * 0.1)

                // MARK: - Layer 4: Needle
                needlePath(for: speed, in: center, radius: radius)
                    .fill(Color.red)
                    .shadow(radius: 2)
                
                // MARK: - Layer 5: Pivot Point
                Circle()
                    .fill(Color.white)
                    .frame(width: radius * 0.1, height: radius * 0.1)
                
                // MARK: - Layer 6: Map Icon Button
                // This VStack/HStack with Spacers will push the button to the bottom-right corner.
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onMapButtonTapped) {
                            Image(systemName: "map.fill")
                                .font(.title2)
                                .padding()
                                .background(.thinMaterial)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding([.bottom, .trailing]) // Apply padding to keep it from the edges
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func needlePath(for speed: Double, in center: CGPoint, radius: CGFloat) -> Path {
        let totalAngle = Angle(degrees: 270)
        let progress = min(speed / maxSpeed, 1.0)
        let angle = startAngle + (totalAngle * progress)
        let pointerLength = radius * 0.9
        let baseWidth: CGFloat = 10

        var path = Path()
        path.move(to: CGPoint(x: 0, y: -baseWidth / 2))
        path.addLine(to: CGPoint(x: 0, y: baseWidth / 2))
        path.addLine(to: CGPoint(x: pointerLength, y: 0))
        path.closeSubpath()
        
        return path.applying(CGAffineTransform(rotationAngle: CGFloat(angle.radians)))
                   .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }

    private func headingString(from direction: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((direction + 11.25) / 22.5) & 15
        return String(format: "%.0f° %@", direction, directions[index])
    }
}

private struct GaugeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        p.addArc(center: center,
                 radius: radius,
                 startAngle: Angle(degrees: 135),
                 endAngle: Angle(degrees: 45),
                 clockwise: false)
        
        return p
    }
}

private struct TicksAndLabels: View {
    var center: CGPoint
    var radius: CGFloat
    let maxSpeed: Double = 60
    private let tickCount = 7

    var body: some View {
        ZStack {
            ForEach(0..<tickCount) { i in
                let value = Double(i) * (maxSpeed / Double(tickCount - 1))
                let angle = angleForValue(value)
                
                let tickLabelRadius = radius * 0.75
                let xPos = center.x + tickLabelRadius * cos(CGFloat(angle.radians))
                let yPos = center.y + tickLabelRadius * sin(CGFloat(angle.radians))

                let tickMarkRadius = radius * 0.9
                let xTickPos = center.x + tickMarkRadius * cos(CGFloat(angle.radians))
                let yTickPos = center.y + tickMarkRadius * sin(CGFloat(angle.radians))
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: 10)
                    .position(x: xTickPos, y: yTickPos)
                    .rotationEffect(angle + .degrees(90))

                Text(String(format: "%.0f", value))
                    .font(.caption.bold())
                    .position(x: xPos, y: yPos)
            }
        }
    }
    
    private func angleForValue(_ value: Double) -> Angle {
        let startAngle = Angle(degrees: 135)
        let totalAngle = Angle(degrees: 270)
        let progress = value / maxSpeed
        return startAngle + (totalAngle * progress)
    }
}

/*struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        GaugeView(speed: 45, heading: 0, onMapButtonTapped: { print("Map tapped") })
            .frame(width: 300, height: 300)
            .padding()
            .background(Color.gray)
            .previewLayout(.sizeThatFits)
    }
}*/

import Playgrounds

#Playground {
    print("hi")
}

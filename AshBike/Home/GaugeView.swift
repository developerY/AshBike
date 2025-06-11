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

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Layer 1: 3D Glass Background & Ticks
                GaugeBackgroundView(radius: radius)
                TicksAndLabelsView(center: center, radius: radius, maxSpeed: maxSpeed)

                // Layer 2: Glowing Progress Arc
                GlowingArcView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 3: Center Text Display
                CenterTextView(radius: radius, speed: speed, heading: heading)

                // Layer 4: Needle
                NeedleView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 5: Map Icon Button
                MapButton(action: onMapButtonTapped)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}


// MARK: - Sub-components for GaugeView

private struct GaugeBackgroundView: View {
    let radius: CGFloat
    
    var body: some View {
        // Base of the gauge
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.6)]),
                    center: .center,
                    startRadius: radius * 0.8,
                    endRadius: radius
                )
            )
        // Inner shadow for depth
        Circle()
            .stroke(Color.black.opacity(0.5), lineWidth: 2)
            .blur(radius: 2)
            .offset(x: 1, y: 1)
            .mask(Circle().stroke(lineWidth: 4))
            
        // Glassy highlight
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: radius * 2, height: radius * 2)
    }
}

private struct TicksAndLabelsView: View {
    let center: CGPoint
    let radius: CGFloat
    let maxSpeed: Double
    private let tickCount = 7

    var body: some View {
        ZStack {
            ForEach(0..<tickCount) { i in
                let value = Double(i) * (maxSpeed / Double(tickCount - 1))
                let angle = angleForValue(value)
                
                // Tick Marks
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 10)
                    .position(x: center.x + (radius * 0.9) * cos(CGFloat(angle.radians)),
                              y: center.y + (radius * 0.9) * sin(CGFloat(angle.radians)))
                    .rotationEffect(angle + .degrees(90))

                // Tick Labels
                Text(String(format: "%.0f", value))
                    .font(.system(size: radius * 0.1, weight: .bold))
                    .foregroundStyle(.white)
                    .position(x: center.x + (radius * 0.75) * cos(CGFloat(angle.radians)),
                              y: center.y + (radius * 0.75) * sin(CGFloat(angle.radians)))
            }
        }
    }
    
    private func angleForValue(_ value: Double) -> Angle {
        .degrees(135) + .degrees(270 * (value / maxSpeed))
    }
}

private struct GlowingArcView: View {
    let radius: CGFloat
    let speed: Double
    let maxSpeed: Double
    
    private var progress: Double { min(speed / maxSpeed, 1.0) }
    private var strokeStyle: StrokeStyle { StrokeStyle(lineWidth: radius * 0.15, lineCap: .round) }
    
    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.green, .yellow, .red]),
            center: .center,
            startAngle: .degrees(135),
            endAngle: .degrees(135 + 270)
        )
    }

    var body: some View {
        // Background track for the glow
        GaugeArcShape()
            .stroke(Color.black.opacity(0.5), style: strokeStyle)
            .blur(radius: 2)
        
        // The glowing progress bar
        GaugeArcShape()
            .trim(from: 0.0, to: progress)
            .stroke(gradient, style: strokeStyle)
            .shadow(color: .green.opacity(0.5), radius: CGFloat(progress * 15)) // Glow effect
            .shadow(color: .yellow.opacity(progress > 0.5 ? 0.7 : 0), radius: CGFloat(progress * 15))
            .shadow(color: .red.opacity(progress > 0.8 ? 0.9 : 0), radius: CGFloat(progress * 15))
    }
}

private struct CenterTextView: View {
    let radius: CGFloat
    let speed: Double
    let heading: Double
    
    var body: some View {
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
                .background(Color.blue.opacity(0.7))
                .cornerRadius(8)
        }
        .foregroundStyle(.white)
        .shadow(radius: 2)
        .offset(y: radius * 0.1)
    }
    
    private func headingString(from direction: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((direction + 11.25) / 22.5) & 15
        return String(format: "%.0f° %@", direction, directions[index])
    }
}

private struct NeedleView: View {
    let radius: CGFloat
    let speed: Double
    let maxSpeed: Double
    
    private var angle: Angle { .degrees(135) + .degrees(270 * (speed / maxSpeed)) }
    
    var body: some View {
        // Needle
        Capsule()
            .trim(from: 0.5, to: 1)
            .stroke(
                LinearGradient(gradient: Gradient(colors: [.red, .red.opacity(0.5)]), startPoint: .top, endPoint: .bottom),
                lineWidth: 4
            )
            .frame(width: radius * 1.6, height: radius * 1.6)
            .rotationEffect(angle)
            .shadow(color: .red, radius: 5)
        
        // Pivot point
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.white, .gray]),
                    center: .center, startRadius: 0, endRadius: radius * 0.05
                )
            )
            .frame(width: radius * 0.1, height: radius * 0.1)
            .shadow(radius: 1)
    }
}

private struct MapButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "map.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial)
                        .foregroundStyle(.primary)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .padding()
            }
        }
    }
}

// MARK: - Reusable Arc Shape

private struct GaugeArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(135),
                 endAngle: .degrees(45),
                 clockwise: false)
        
        return p
    }
}


// MARK: - Preview

struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        GaugeView(speed: 45, heading: 270, onMapButtonTapped: { print("Map tapped") })
            .frame(width: 300, height: 300)
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            .previewLayout(.sizeThatFits)
    }
}

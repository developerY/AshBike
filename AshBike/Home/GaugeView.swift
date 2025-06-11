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
                // Layer 1: Dark background to make the glass effect pop
                Circle()
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 5, y: 5)

                // Layer 2: The new "Liquid Glass" Speedometer Arc
                LiquidGlassArcView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 3: Ticks and Labels, now more subtle
                TicksAndLabelsView(center: center, radius: radius, maxSpeed: maxSpeed)

                // Layer 4: Center Text Display
                CenterTextView(radius: radius, speed: speed, heading: heading)

                // Layer 5: Needle, redesigned to float above the glass
                NeedleView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 6: Map Icon Button
                MapButton(action: onMapButtonTapped)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}


// MARK: - Sub-components for GaugeView

private struct LiquidGlassArcView: View {
    let radius: CGFloat
    let speed: Double
    let maxSpeed: Double
    
    private var progress: Double { min(speed / maxSpeed, 1.0) }
    private var strokeStyle: StrokeStyle { StrokeStyle(lineWidth: radius * 0.2, lineCap: .round) }

    var body: some View {
        ZStack {
            // 1. Base Frosted Glass Track
            GaugeArcShape()
                .stroke(style: strokeStyle)
                .foregroundStyle(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 5, y: 5) // Outer shadow for depth

            // 2. Inner Bevel Highlight
            GaugeArcShape()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: radius * 0.2, lineCap: .round)
                )
                .mask(GaugeArcShape().stroke(style: strokeStyle))
                .blur(radius: 1)

            // 3. Internal Illumination that "lights up" the glass
            let gradient = AngularGradient(
                gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                center: .center,
                startAngle: .degrees(135), // Corresponds to the start of the arc
                endAngle: .degrees(405)  // Corresponds to the end of the arc (135 + 270)
            )

            GaugeArcShape()
                .stroke(gradient, style: strokeStyle)
                .mask(
                    GaugeArcShape()
                        .trim(from: 0, to: progress)
                        .stroke(style: strokeStyle)
                )
                .blur(radius: 15) // Soft, diffused glow
                .shadow(color: .white.opacity(0.4), radius: CGFloat(progress * 15)) // A neutral white glow to avoid color clashes
                .blendMode(.plusLighter) // Makes the light "add" to the glass below
        }
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
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1, height: 8)
                    .position(x: center.x + (radius * 0.95) * cos(CGFloat(angle.radians)),
                              y: center.y + (radius * 0.95) * sin(CGFloat(angle.radians)))
                    .rotationEffect(angle + .degrees(90))

                // Tick Labels
                Text(String(format: "%.0f", value))
                    .font(.system(size: radius * 0.09, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .position(x: center.x + (radius * 0.8) * cos(CGFloat(angle.radians)),
                              y: center.y + (radius * 0.8) * sin(CGFloat(angle.radians)))
            }
        }
    }
    
    private func angleForValue(_ value: Double) -> Angle {
        .degrees(135) + .degrees(270 * (value / maxSpeed))
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
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.black.opacity(0.3))
                .cornerRadius(12)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
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
            .stroke(.white, lineWidth: 3)
            .frame(width: radius * 1.8, height: radius * 1.8)
            .rotationEffect(angle)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 4)

        // Pivot point
        Circle()
            .fill(.white)
            .frame(width: radius * 0.15, height: radius * 0.15)
            .shadow(radius: 2)
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
                        .background(.ultraThinMaterial)
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
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .previewLayout(.sizeThatFits)
    }
}

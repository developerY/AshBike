//
//  GaugeView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI

struct GaugeView: View, Equatable {
    var speed: Double
    var heading: Double
    var maxSpeed: Double = 60
    var onMapButtonTapped: () -> Void // Action to show the map

    static func == (lhs: GaugeView, rhs: GaugeView) -> Bool {
        lhs.speed == rhs.speed &&
        lhs.heading == rhs.heading &&
        lhs.maxSpeed == rhs.maxSpeed
    }

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Layer 1: The new "Blue Frosted Glass" Background
                Circle()
                    .foregroundStyle(.thinMaterial)
                    .background(.blue.opacity(0.3))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 10)


                // Layer 2: The "Liquid Glass" Speedometer Arc
                LiquidGlassArcView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 3: Ticks and Labels
                TicksAndLabelsView(center: center, radius: radius, maxSpeed: maxSpeed)

                // Layer 4: Needle
                NeedleView(radius: radius, speed: speed, maxSpeed: maxSpeed)

                // Layer 5: Center Text Display (now on top of the needle)
                CenterTextView(radius: radius, speed: speed, heading: heading, maxSpeed: maxSpeed) // Pass maxSpeed here

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
    private var glassStrokeStyle: StrokeStyle { StrokeStyle(lineWidth: radius * 0.22, lineCap: .round) }
    private var colorStrokeStyle: StrokeStyle { StrokeStyle(lineWidth: radius * 0.18, lineCap: .round) }


    var body: some View {
        ZStack {
            // 1. Base Frosted Glass Track with a more pronounced 3D effect
            GaugeArcShape()
                .stroke(style: glassStrokeStyle)
                .foregroundStyle(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 5, y: 5)
                .overlay {
                    // Inner shadow for a "pressed-in" look
                    GaugeArcShape()
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                        .blur(radius: 2)
                        .offset(x: 1, y: 1)
                        .mask(GaugeArcShape().stroke(style: glassStrokeStyle))
                    // Top-down highlight for a glossy finish
                    GaugeArcShape()
                        .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 3)
                        .blur(radius: 2)
                        .mask(GaugeArcShape().stroke(style: glassStrokeStyle))
                }


            // 2. Define the illumination gradient
            let gradient = AngularGradient(
                gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                center: .center,
                startAngle: .degrees(135),
                endAngle: .degrees(405)
            )
            
            // 3. Create the masked colored portion of the arc
            let coloredPortion = GaugeArcShape()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: colorStrokeStyle) // Use thinner style for the color

            // 4. Draw the soft glow layer underneath
            coloredPortion
                .blur(radius: 20)
                .opacity(0.8)
                .blendMode(.screen) // Screen blend mode gives a brighter, more colorful glow

            // 5. Draw the crisp color layer on top
            coloredPortion
                .overlay {
                    // Add a glossy highlight to the colored part itself
                    GaugeArcShape()
                        .stroke(LinearGradient(colors: [.white.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .blur(radius: 1)
                        .mask(coloredPortion)
                }
        }
    }
}


private struct TicksAndLabelsView: View {
    let center: CGPoint
    let radius: CGFloat
    let maxSpeed: Double
    private let tickCount = 7
    
    // 1. Create a helper struct for the tick data
    private struct TickData: Identifiable {
        let id: Int
        let value: Double
        let angle: Angle
    }
    
    // 2. Pre-compute the data to simplify the ForEach loop
    private var tickData: [TickData] {
        (0..<tickCount).map { i in
            let value = Double(i) * (maxSpeed / Double(tickCount - 1))
            let angle = angleForValue(value)
            return TickData(id: i, value: value, angle: angle)
        }
    }

    var body: some View {
        ZStack {
            // 3. The ForEach is now much simpler
            ForEach(tickData) { data in
                tickMark(angle: data.angle)
                tickLabel(value: data.value, angle: data.angle)
            }
        }
    }
    
    // 4. Create a @ViewBuilder for the tick mark
    @ViewBuilder
    private func tickMark(angle: Angle) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.7))
            .frame(width: 2, height: 10)
            .position(x: center.x + (radius * 0.9) * cos(CGFloat(angle.radians)),
                      y: center.y + (radius * 0.9) * sin(CGFloat(angle.radians)))
            .rotationEffect(angle + .degrees(90))
    }
        
    // 5. Create a @ViewBuilder for the tick label
    @ViewBuilder
    private func tickLabel(value: Double, angle: Angle) -> some View {
        Text(String(format: "%.0f", value))
            .font(.system(size: radius * 0.1, weight: .bold))
            .foregroundStyle(.black.opacity(0.8))
            .position(x: center.x + (radius * 0.78) * cos(CGFloat(angle.radians)),
                      y: center.y + (radius * 0.78) * sin(CGFloat(angle.radians)))
    }


    private func angleForValue(_ value: Double) -> Angle {
        .degrees(135) + .degrees(270 * (value / maxSpeed))
    }
}

private func headingString(from direction: Double) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let index = Int((direction + 11.25) / 22.5) & 15
    return String(format: "%.0f° %@", direction, directions[index])
}

private struct CenterTextView: View {
    let radius: CGFloat
    let speed: Double
    let heading: Double
    let maxSpeed: Double // Add this new property

    // Define the same colors used in LiquidGlassArcView's gradient for consistent matching
    private var speedColor: Color {
        let colors: [Color] = [.green, .yellow, .orange, .red] // Matches LiquidGlassArcView
        return Color.colorForSpeed(speed: speed, maxSpeed: maxSpeed, colors: colors)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", speed))
                    .font(.system(size: radius * 0.6, weight: .bold))
                    .foregroundStyle(speedColor) // Apply the dynamic color here
                Text("km/h")
                    .font(.system(size: radius * 0.18, weight: .semibold))
                    .foregroundStyle(speedColor) // Apply to unit as well for consistency
            }
            Text(headingString(from: heading))
                .font(.system(size: radius * 0.18, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.black.opacity(0.3))
                .cornerRadius(12)
        }
        // Remove .foregroundStyle(.white) from this VStack, as it's now applied directly to the Text views
        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
    }

}

private struct NeedleView: View {
    let radius: CGFloat
    let speed: Double
    let maxSpeed: Double
    
    // ** THE FIX IS HERE **
    // The speed is now clamped to the maxSpeed, preventing the needle from
    // spinning past the end of the dial.
    private var angle: Angle {
        let clampedSpeed = min(speed, maxSpeed)
        return .degrees(135) + .degrees(270 * (clampedSpeed / maxSpeed))
    }

    var body: some View {
        ZStack {
            // Main Pointer part (the arrow shape)
            PointerShape()
                .frame(width: radius * 0.08, height: radius * 0.9)
                .offset(y: -radius * 0.45)
                .foregroundStyle(.primary) // Change this from .ultraThinMaterial to .black
            
                // Remove the white highlight overlay as it's intended for frosted glass look
                .overlay(
                    PointerShape()
                        .stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                )
                
                .rotationEffect(angle + .degrees(90))
                .shadow(color: .black.opacity(0.6), radius: 5, y: 5) // Adjust shadow for better visibility on black

            // Pivot point (the circle at the base of the needle)
            Circle()
                .fill(.secondary) // Change this from .background to .black
                .frame(width: radius * 0.2, height: radius * 0.2)
                .shadow(radius: 3)
                .overlay(
                    // Change the stroke color for contrast against a black background
                    Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// Custom shape for the new pointer
private struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Tip of the pointer
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Bottom-right corner
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Bottom-left corner
            path.closeSubpath()
        }
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
        GaugeView(speed: 25, heading: 270, onMapButtonTapped: { print("Map tapped") })
            .frame(width: 300, height: 300)
            .padding()
            .background(Color.gray.opacity(0.2)) // A neutral background for the preview
            .previewLayout(.sizeThatFits)
    }
}


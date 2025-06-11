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
                // Layer 1: The new "Blue Frosted Glass" Background
                Circle()
                    .foregroundStyle(.thinMaterial)
                    .background(.blue.opacity(0.3))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 10)


                // Layer 2: The "Liquid Glass" Speedometer Arc
                LiquidGlassArcView(radius: radius, speed: speed, maxSpeed: maxSpeed)
                
                // Layer 3: Ticks and Labels
                TicksAndLabelsView(center: center, radius: radius, maxSpeed: maxSpeed, currentSpeed: speed)

                // Layer 4: Center Text Display
                CenterTextView(radius: radius, speed: speed, heading: heading)

                // Layer 5: Needle
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
    let currentSpeed: Double
    private let tickCount = 7

    var body: some View {
        ZStack {
            ForEach(0..<tickCount) { i in
                let value = Double(i) * (maxSpeed / Double(tickCount - 1))
                let angle = angleForValue(value)
                
                // Tick Marks as 3D Glass Capsules
                let isTickActive = currentSpeed >= value
                
                ZStack {
                    // Base capsule
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .background(.blue.opacity(0.3))
                        .clipShape(Capsule())

                    // Color fill that matches the main gradient
                    let gradient = AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    )
                    
                    if isTickActive {
                        Capsule()
                            .fill(gradient)
                            .opacity(0.8)
                            .blendMode(.screen)
                    }

                    // Highlight
                    Capsule()
                        .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                }
                .frame(width: 4, height: 12)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .position(x: center.x + (radius * 0.95) * cos(CGFloat(angle.radians)),
                          y: center.y + (radius * 0.95) * sin(CGFloat(angle.radians)))
                .rotationEffect(angle + .degrees(90))


                // Tick Labels
                Text(String(format: "%.0f", value))
                    .font(.system(size: radius * 0.09, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
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
    private var speedGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            center: .center,
            startAngle: .degrees(135),
            endAngle: .degrees(405)
        )
    }

    var body: some View {
        ZStack {
            // New "Frosted Glass" Pointer
            PointerShape()
                .frame(width: radius * 0.1, height: radius)
                .offset(y: -radius / 2) // ** FIX 1: Offset the pointer so the base is at the center
                .foregroundStyle(.ultraThinMaterial)
                .overlay(
                    PointerShape()
                        .foregroundStyle(speedGradient)
                        .blendMode(.plusLighter)
                )
                .overlay(
                    PointerShape()
                        .stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                )
                .rotationEffect(angle - .degrees(90)) // ** FIX 2: Correct the rotation angle
                .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
            
            // Pivot point
            Circle()
                .fill(.background)
                .frame(width: radius * 0.2, height: radius * 0.2)
                .shadow(radius: 3)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// Custom shape for the new pointer
private struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.midX, y: rect.maxY),
                control: CGPoint(x: rect.midX + rect.width * 0.5, y: rect.height * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.midX, y: rect.minY),
                control: CGPoint(x: rect.midX - rect.width * 0.5, y: rect.height * 0.5)
            )
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
        GaugeView(speed: 45, heading: 270, onMapButtonTapped: { print("Map tapped") })
            .frame(width: 300, height: 300)
            .padding()
            .background(Color.gray.opacity(0.2)) // A neutral background for the preview
            .previewLayout(.sizeThatFits)
    }
}

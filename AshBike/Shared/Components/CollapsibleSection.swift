//
//  Untitled.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
// CollapsibleSection.swift
import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // A button acts as the tappable header for the section
            Button(action: {
                // Toggle the expansion state with a smooth animation
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    // This is our single, rotating chevron
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundStyle(.primary) // Ensures text and chevron are visible
                .padding() // Give the button a larger, comfortable tap area
            }
            .buttonStyle(.plain) // Use plain style to avoid default button chrome

            // Conditionally show the content view with a transition
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal)
                    
                    content()
                        .padding([.horizontal, .bottom])
                        .padding(.top, 8)
                }
                .transition(.opacity)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    // Use a stateful preview to test the binding
    struct CollapsiblePreview: View {
        @State private var isExpanded1 = true
        @State private var isExpanded2 = false

        var body: some View {
            VStack(spacing: 16) {
                CollapsibleSection(
                    title: "Expanded Section",
                    isExpanded: $isExpanded1
                ) {
                    Text("This is the content of the section that is visible by default.")
                        .padding()
                }
                
                CollapsibleSection(
                    title: "Collapsed Section",
                    isExpanded: $isExpanded2
                ) {
                    Text("This content is hidden by default. Tap the header to see it.")
                        .padding()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    return CollapsiblePreview()
}

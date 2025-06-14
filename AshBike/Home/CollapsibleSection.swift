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

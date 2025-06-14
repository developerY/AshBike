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
    DisclosureGroup(isExpanded: $isExpanded) {
      // The expandable content
      content()
        .padding(.top, 8)
    } label: {
      // A custom label with a rotating chevron
      HStack {
        Text(title)
          .font(.subheadline.bold())
        Spacer()
        Image(systemName: "chevron.right")
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
      }
    }
    // Set the color for our custom chevron
    .accentColor(.secondary)
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(8)
    // Animate the change when isExpanded toggles
    .animation(.easeInOut(duration: 0.2), value: isExpanded)
  }
}

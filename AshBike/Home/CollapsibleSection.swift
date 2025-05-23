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
      content()
    } label: {
      Text(title)
        .font(.subheadline.bold())
    }
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(8)
  }
}

//
//  ProfileEditorView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/16/25.
//
import SwiftUI
// MARK: — ProfileEditorView (Updated to include a Save button)
struct ProfileEditorView: View {
    @Bindable var profile: UserProfile
    @Binding var isEditing: Bool
    
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack {
            TextField("Name", text: $profile.name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                TextField("Height (cm)", value: $profile.heightCm, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Weight (kg)", value: $profile.weightKg, format: .number)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel", role: .cancel) {
                    // Optional: Add logic to revert changes if needed
                    isEditing = false
                }
                Spacer()
                Button("Save") {
                    try? context.save()
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
    }
}


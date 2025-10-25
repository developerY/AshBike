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
    
    // --- ADD STATE FOR THE ALERT ---
    @State private var appAlert: AppAlert?

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
                // --- MODIFY THE SAVE BUTTON'S ACTION ---
                Button("Save") {
                    do {
                        try context.save()
                        isEditing = false
                    } catch {
                        appAlert = AppAlert(title: "Save Failed", message: "Your profile could not be saved. Please try again.")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
        // --- ADD THIS MODIFIER TO THE VSTACK ---
        .alert(item: $appAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview("ProfileEditorView") {
    struct PreviewHost: View {
        @State private var isEditing = true
        @State private var profile = UserProfile(name: "Alex Rider", heightCm: 178, weightKg: 72)
        var body: some View {
            ProfileEditorView(profile: profile, isEditing: $isEditing)
                .padding()
        }
    }
    return PreviewHost()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .background(Color(.systemBackground))
}

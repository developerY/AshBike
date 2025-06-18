//
//  SettingsView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import SwiftUI
import SwiftData
import HealthKit

// MARK: — SettingsView
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    
    @Environment(RideDataManager.self) private var rideDataManager
    
    // --- THIS IS THE FIX ---
    // Change @State to @Environment to receive the shared instance
    // instead of creating a new one.
    // This part is now CORRECT. You are successfully receiving the shared object.
    // @State private var appSettings = AppSettings()
    @Environment(AppSettings.self) private var appSettings
    
    // --- MODIFIED ---
    // Services are now correctly received from the environment.
    @Environment(HealthKitService.self) private var healthKitService

    // This determines if AshBike-specific hardware has been detected.
    @State private var isAshBikeHardwareDetected = true

    // State to control UI modes
    @State private var isEditingProfile = false
    @State private var connectivityExpanded = true
    @State private var ashbikeExpanded = true
    
    // Alert properties
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // --- PROFILE SECTION (NOW A TRUE INLINE EDITOR) ---
                Section {
                    if let profile = profiles.first {
                        if isEditingProfile {
                            ProfileEditorView(profile: profile, isEditing: $isEditingProfile)
                        } else {
                            profileCard(for: profile)
                        }
                    } else {
                        // Show a loading spinner during the initial check.
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }

                // --- APP PREFERENCES & ABOUT ---
                Section("App Settings") {
                    DisclosureGroup("About") {
                        Text("AshBike v1.0")
                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    }
                }

                // --- GENERAL CONNECTIVITY (For all users) ---
                Section {
                    DisclosureGroup(isExpanded: $connectivityExpanded) {
                        
                        // --- THIS IS THE MANUAL BINDING FIX ---
                        // We will create the Binding<Bool> for the Toggle manually
                        // to bypass the compiler error with the '$' syntax.
                        Toggle(isOn: Binding(
                            get: {
                                // How the Toggle gets its value
                                appSettings.isHealthKitEnabled
                            },
                            set: { isEnabled in
                                // What the Toggle does when its value changes
                                appSettings.isHealthKitEnabled = isEnabled
                                handleHealthKitToggle(isEnabled: isEnabled)
                            }
                        )) {
                            Label("HealthKit Sync", systemImage: "heart.text.square")
                        }
                        // The .onChange modifier is no longer needed as the logic
                        // is now handled inside the 'set' block of the binding.
                        
                    } label: {
                        Label("App Connectivity", systemImage: "dot.radiowaves.left.and.right")
                    }
                }
                
                // --- ASHBIKE HARDWARE SECTION (Conditional & Disabled for Beta) ---
                if isAshBikeHardwareDetected {
                    Section {
                        DisclosureGroup(isExpanded: $ashbikeExpanded) {
                            Group {
                                Toggle(isOn: .constant(false)) {
                                    Label("NFC Scanning", systemImage: "nfc.tag.fill")
                                }
                                Toggle(isOn: .constant(false)) {
                                     Label("QR Scanner", systemImage: "qrcode.viewfinder")
                                }
                                Toggle(isOn: .constant(false)) {
                                     Label("Bluetooth (BLE)", systemImage: "bolt.horizontal.circle")
                                }
                            }
                            .disabled(true)
                        } label: {
                            Label("AshBike Hardware", systemImage: "bicycle.circle")
                        }
                    } header: {
                        Text("E-Bike Features")
                    }
                }
                
                // --- DATA MANAGEMENT ---
                Section("Data") {
                    // --- WITH THIS NEW VERSION ---
                    Button("Delete All Rides", role: .destructive) {
                        Task {
                            do {
                                try await rideDataManager.deleteAllRides()
                                showAlert(title: "Success", message: "All ride data has been deleted.")
                            } catch {
                                showAlert(title: "Error", message: "Could not delete all rides. Please try again.")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if profiles.isEmpty {
                    let defaultProfile = UserProfile()
                    context.insert(defaultProfile)
                    try? context.save()
                }
            }
        }
    }
    
    // --- View Components ---
    @ViewBuilder
    private func profileCard(for profile: UserProfile) -> some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable().frame(width: 50, height: 50)
                .foregroundStyle(.blue.gradient)
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                Text("Height: \(Int(profile.heightCm)) cm | Weight: \(Int(profile.weightKg)) kg")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            // The edit button now toggles the `isEditingProfile` state.
            Button {
                isEditingProfile = true
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
    
    // --- Logic ---
    private func handleHealthKitToggle(isEnabled: Bool) {
        if isEnabled {
            healthKitService.requestAuthorization { success, error in
                if success {
                    showAlert(title: "HealthKit Enabled", message: "This app can now sync with Apple Health.")
                } else {
                    appSettings.isHealthKitEnabled = false // Revert toggle on failure
                    showAlert(title: "Authorization Failed", message: "Could not authorize HealthKit. Please check your settings in the Health app.")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}

// MARK: — Preview
#Preview {
    let config = ModelConfiguration(schema: Schema([UserProfile.self, BikeRide.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([UserProfile.self]), configurations: [config])
    let appSettings = AppSettings()
    // We no longer need to insert a profile for the preview,
    // as the view's .onAppear will handle it.
    
    return SettingsView()
        .modelContainer(container)
        .environment(HealthKitService()) // Add service to preview environment
        .environment(appSettings) // Add AppSettings to preview
}

//
//  SettingsAshBike.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 6/10/25.
//
import SwiftUI
import SwiftData
import HealthKit



// MARK: - App Settings State Manager
@Observable
class AppAshBikeSettings {
    // We use UserDefaults to persist these settings across app launches.
    var isHealthKitEnabled: Bool {
        didSet { UserDefaults.standard.set(isHealthKitEnabled, forKey: "isHealthKitEnabled") }
    }

    init() {
        self.isHealthKitEnabled = UserDefaults.standard.bool(forKey: "isHealthKitEnabled")
    }
}


// MARK: — SettingsView
struct SettingsAshBikeView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    
    // State for the settings toggles and services
    @State private var appSettings = AppSettings()
    @State private var healthKitService = HealthKitService()

    @State private var showProfileEditor = false
    @State private var connectivityExpanded = true
    
    // Alert properties
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // --- PROFILE SECTION ---
                Section {
                    if let profile = profiles.first {
                        profileCard(for: profile)
                    } else {
                        Button("Create Profile") {
                            context.insert(UserProfile())
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

                // --- CONNECTIVITY ---
                Section {
                    DisclosureGroup(isExpanded: $connectivityExpanded) {
                        // HealthKit Toggle
                        Toggle(isOn: $appSettings.isHealthKitEnabled) {
                            Label("HealthKit Sync", systemImage: "heart.text.square")
                        }
                        .onChange(of: appSettings.isHealthKitEnabled) { _, isEnabled in
                            handleHealthKitToggle(isEnabled: isEnabled)
                        }
                    } label: {
                        Label("Connectivity", systemImage: "dot.radiowaves.left.and.right")
                    }
                }
                
                // --- DATA MANAGEMENT ---
                Section("Data") {
                    Button("Delete All Rides", role: .destructive) {
                        // Add confirmation alert before deleting
                        try? context.delete(model: BikeRide.self)
                        showAlert(title: "Success", message: "All ride data has been deleted.")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showProfileEditor) {
                // Ensure we pass a non-optional profile to the editor
                if let profile = profiles.first {
                    ProfileEditorView(profile: profile)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
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
            VStack {
                Text(profile.name)
                    .font(.headline)
                Text("Height: \(Int(profile.heightCm)) cm | Weight: \(Int(profile.weightKg)) kg")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showProfileEditor = true } label: {
                Image(systemName: "pencil")
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
                    showAlert(title: "HealthKit Enabled", message: "AshBike can now sync with Apple Health.")
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
    // Create an in-memory container and add a sample profile for the preview
    let config = ModelConfiguration(schema: Schema([UserProfile.self, BikeRide.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([UserProfile.self]), configurations: [config])
    container.mainContext.insert(UserProfile())
    
    return SettingsAshBikeView()
        .modelContainer(container)
}


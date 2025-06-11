//
//  SettingsView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import SwiftUI
import SwiftData
import HealthKit

// MARK: - App Settings State Manager
@Observable
class AppSettings {
    // We use UserDefaults to persist these settings across app launches.
    var isHealthKitEnabled: Bool {
        didSet { UserDefaults.standard.set(isHealthKitEnabled, forKey: "isHealthKitEnabled") }
    }
    // These properties are for the beta hardware features.
    // They are set to 'false' by default.
    var isNFCEnabled: Bool = false
    var isQREnabled: Bool = false
    var isBLEEnabled: Bool = false


    init() {
        self.isHealthKitEnabled = UserDefaults.standard.bool(forKey: "isHealthKitEnabled")
        // We won't load the hardware settings from UserDefaults yet,
        // as they are in beta.
    }
}


// MARK: — SettingsView
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    
    // State for the settings toggles and services
    @State private var appSettings = AppSettings()
    @State private var healthKitService = HealthKitService()

    // ** This is the key for the conditional UI **
    // In a real app, this would be determined by a BLE handshake or other hardware check.
    // We set it to 'true' here so you can see the AshBike-specific settings.
    @State private var isAshBikeHardwareDetected = true

    // State to control the expanded/collapsed sections
    @State private var profileExpanded = false
    @State private var connectivityExpanded = true
    @State private var ashbikeExpanded = true
    
    // Alert properties
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // --- PROFILE SECTION (NOW INLINE & EXPANDABLE) ---
                Section {
                    if let profile = profiles.first {
                        // The entire profile section is now a DisclosureGroup
                        DisclosureGroup(isExpanded: $profileExpanded) {
                            // The editing fields are now directly inside the group
                            ProfileEditorView(profile: profile)
                        } label: {
                            // The label shows the user's current data
                            profileCard(for: profile)
                        }
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

                // --- GENERAL CONNECTIVITY (For all users) ---
                Section {
                    DisclosureGroup(isExpanded: $connectivityExpanded) {
                        // HealthKit Toggle (for everyone)
                        Toggle(isOn: $appSettings.isHealthKitEnabled) {
                            Label("HealthKit Sync", systemImage: "heart.text.square")
                        }
                        .onChange(of: appSettings.isHealthKitEnabled) { _, isEnabled in
                            handleHealthKitToggle(isEnabled: isEnabled)
                        }
                    } label: {
                        Label("App Connectivity", systemImage: "dot.radiowaves.left.and.right")
                    }
                }
                
                // --- ASHBIKE HARDWARE SECTION (Conditional) ---
                if isAshBikeHardwareDetected {
                    Section {
                        DisclosureGroup(isExpanded: $ashbikeExpanded) {
                            // This Group allows us to disable all the toggles at once.
                            Group {
                                // The bindings are now to constant 'false' values,
                                // which forces the toggles to the 'off' position.
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
                            // The .disabled modifier grays out the toggles.
                            .disabled(true)
                        } label: {
                            Label("AshBike Hardware", systemImage: "bicycle.circle")
                        }
                    } header: {
                        Text("E-Bike Features") // Section header
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
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                Text("Height: \(Int(profile.heightCm)) cm | Weight: \(Int(profile.weightKg)) kg")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
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

// MARK: — ProfileEditorView (Simplified for inline use)
struct ProfileEditorView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        // These are the fields that appear when the profile section is expanded.
        TextField("Name", text: $profile.name)
        HStack {
            Text("Height (cm)")
            Spacer()
            TextField("cm", value: $profile.heightCm, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
        HStack {
            Text("Weight (kg)")
            Spacer()
            TextField("kg", value: $profile.weightKg, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: — Preview
#Preview {
    let config = ModelConfiguration(schema: Schema([UserProfile.self, BikeRide.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([UserProfile.self]), configurations: [config])
    container.mainContext.insert(UserProfile())
    
    return SettingsView()
        .modelContainer(container)
}

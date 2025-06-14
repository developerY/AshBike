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
                    Button("Delete All Rides", role: .destructive) {
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

// MARK: — Preview
#Preview {
    let config = ModelConfiguration(schema: Schema([UserProfile.self, BikeRide.self]), isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([UserProfile.self]), configurations: [config])
    // We no longer need to insert a profile for the preview,
    // as the view's .onAppear will handle it.
    
    return SettingsView()
        .modelContainer(container)
}

//
//  SettingsView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import SwiftUI
import SwiftData
//if you’re using a helper lib - import SFIcons

// MARK: — Profile model

@Model
final class UserProfile {
  @Attribute(.unique) var id: UUID // = .init()
  var name: String
  var heightCm: Double
  var weightKg: Double

  init(name: String = "Ash Monster",
       heightCm: Double = 171,
       weightKg: Double = 72)
  {
      self.id = UUID()
    self.name = name
    self.heightCm = heightCm
    self.weightKg = weightKg
  }
}

// MARK: — SettingsView

struct SettingsView: View {
  @Environment(\.modelContext) private var context
  @Query private var profiles: [UserProfile]

  @State private var showProfileEditor = false
  @State private var connectivityExpanded = true
  @State private var bikeExpanded = false

  var body: some View {
    NavigationStack {
      Form {
        // ─── PROFILE CARD ─────────────────────────
        if let profile = profiles.first {
          HStack {
            Image(systemName: "person.circle.fill")
              .resizable().frame(width: 50, height: 50)
              .foregroundStyle(.blue.gradient)
            VStack(alignment: .leading) {
              Text(profile.name)
                .font(.headline)
              Text("Height: \(Int(profile.heightCm)) cm Weight: \(Int(profile.weightKg)) kg")
                .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showProfileEditor = true }
            label: {
              Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
          }
          .padding(.vertical, 4)
        } else {
          // no profile yet → create one
          Button("Create Profile") {
            let p = UserProfile()
            context.insert(p)
          }
        }

        // ─── APP PREFERENCES & ABOUT ───────────────
        Section("App Settings") {
          DisclosureGroup("App Preferences") {
            Toggle("Dark Mode Override", isOn: .constant(false))
            // … add your preference toggles here …
          }
          DisclosureGroup("About") {
            Text("AshBike v1.0")
            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
          }
        }

        // ─── CONNECTIVITY ──────────────────────────
        Section {
          DisclosureGroup(isExpanded: $connectivityExpanded) {
            // HealthKit
            HStack {
              Image(systemName: "heart.text.square")
              Toggle("HealthKit Sync", isOn: .constant(true))
            }
            // NFC
            HStack {
              Image(systemName: "nfc")
              Toggle("NFC Scanning", isOn: .constant(false))
            }
            // QR
            HStack {
              Image(systemName: "qrcode.viewfinder")
              Toggle("QR Scanner", isOn: .constant(true))
            }
            // BLE
            HStack {
              Image(systemName: "bolt.horizontal.circle")
              Toggle("Bluetooth (BLE)", isOn: .constant(true))
            }
          } label: {
            Label("Connectivity", systemImage: "dot.radiowaves.left.and.right")
          }
        }

        // ─── BIKE SETTINGS ─────────────────────────
        Section {
          DisclosureGroup(isExpanded: $bikeExpanded) {
            Slider(value: .constant(50), in: 0...100) {
              Label("Assist Level", systemImage: "speedometer")
            }
            // … other bike-specific settings …
          } label: {
            Label("Bike Settings", systemImage: "wrench.fill")
          }
        }
      }
      .navigationTitle("Settings")
      .sheet(isPresented: $showProfileEditor) {
        ProfileEditorView(profile: profiles.first!)
          .modelContainer(context.container)
      }
    }
  }
}

// MARK: — ProfileEditorView

struct ProfileEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var profile: UserProfile

  var body: some View {
    NavigationStack {
      Form {
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
      .navigationTitle("Edit Profile")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

// MARK: — Preview

// MARK: – Preview Container

@MainActor
private var previewContainer: ModelContainer = {
  // 1) Build in-memory config
  let cfg = ModelConfiguration(
    schema: Schema([UserProfile.self]),
    isStoredInMemoryOnly: true
  )

  // 2) Initialize the container
  let mc = try! ModelContainer(
    for: Schema([UserProfile.self]),
    configurations: [cfg]
  )

  // 3) Seed it with demo data
  let demoProfiles: [UserProfile] = [
    UserProfile(name: "Alice"),
    UserProfile(name: "Bob"),
    UserProfile(name: "Celia"),
  ]

  for p in demoProfiles {
    mc.mainContext.insert(p)
  }

  return mc
}()

// MARK: – Preview

#Preview {
  SettingsView()
    .modelContainer(previewContainer)
}

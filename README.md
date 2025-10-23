````markdown
# AshBike

**A native iOS 17+ cycling companion app**
Built with Swift 6, SwiftUI, SwiftData, HealthKit, MapKit, ARKit & modern Apple frameworks.

[Test Flight](https://testflight.apple.com/join/an8TYkQc)
---

## 🚴‍♀️ Overview

AshBike helps you track, review and sync your bike rides:

- **Live Ride**: speed gauge, compass, metrics (distance, duration, calories, heart rate)
- **Trip History**: browse, delete and sync past rides with HealthKit
- **Ride Details**: map polyline, speed-color gradient, elevation chart, notes
- **Settings & Services**: profile, HealthKit permissions, NFC/QR/BLE
[Article](https://zoewave.medium.com/apple-x-os-26-25587ca4b46b)
---

## 📦 Requirements

- macOS Sonoma (14.4+)
- Xcode 16.4+
- iOS 17+ simulator or device
- Swift 6

---

## ⚙️ Installation

1. **Clone the repo**
   ```bash
   git clone https://github.com/your-org/AshBike.git
   cd AshBike
````

2. **Open the workspace**

   ```bash
   open AshBike.xcworkspace
   ```

3. **Build & Run**

   * Select the **AshBike** scheme
   * ⌘B to build, ⌘R to run on simulator or device

---

## 🗂️ File Structure

```
AshBike.xcodeproj
AshBike/
├── AshBikeApp.swift        # @main entry point
├── ContentView.swift       # Root SwiftUI view
├── Models/                 # SwiftData @Model classes (Active Record)
│   ├ BikeRide.swift
│   └ RideLocation.swift
├── Services/               # Injected singletons & helpers
│   ├ HealthKitService.swift
│   └ LocationService.swift
├── Views/                  # SwiftUI screens
│   ├ HomeView.swift
│   ├ TripsListView.swift
│   └ RideDetailView.swift
└── Utilities/              # Extensions & helpers
    └ Date+Formatting.swift

Assets.xcassets
AshBikeTests/
AshBikeUITests/
```

---

## 🔧 Architecture

* **Modules**

  * `Models` (SwiftData): Active-Record `@Model` classes
  * `Services` (HealthKit, CoreMotion, MapKit/ARKit)
  * `Views` (SwiftUI screens)
  * `Utilities` (formatters, bindings)

* **Data Flow**

  * Live data (CoreMotion & location) → SwiftData models
  * Persist rides automatically to local store
  * Sync rides to HealthKit via `HealthKitService`

* **State Management**

  * `@Model` + `@Query` + `@Bindable` (iOS 17+ macros)
  * Minimal or no separate ViewModels for simple CRUD
  * Create custom service classes for complex workflows

---

## 🚀 Usage

1. **Start a Ride**

   * Tap **Start**
   * Watch speed gauge, compass & live metrics
2. **Stop a Ride**

   * Tap **Stop**
   * Add optional notes
   * Ride is saved automatically
3. **Browse Trips**

   * Go to **Trips** tab
   * Swipe to delete or tap the sync icon to push to HealthKit
4. **View Details**

   * Tap any ride to see map, elevation chart & notes

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m "Add feature"`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and write tests for new functionality.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

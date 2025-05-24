Here’s the complete rundown of your project’s tech stack, platforms, frameworks and conventions:

---

## 🛠️ Tools & Platforms

* **Xcode 16** (no older “New Group” flows)
* **macOS Sonoma 14.4+** for development
* **iOS 17+** (simulator & devices)

## 📝 Language & Compiler

* **Swift 6**
* **Swift Structured Concurrency** (`async`/`await`)

## 🖥️ UI & State

* **SwiftUI** (iOS 17+ native)
* **SF Symbols** for icons
* **Observation** macros (`@Observable`, `@Bindable`)
* **`@State`-owned** `@Observable` objects (no more `@StateObject`/`@Published`)

## 💾 Data & Persistence

* **SwiftData** (`@Model` classes + automatic history/versioning)
* **Active-Record pattern** via `@Query`, `@Bindable`—minimal or no ViewModels for CRUD

## 📦 Dependency Management

* **Swift Package Manager**

  * **Domain**, **Data**, **HealthKitIntegration**, **Map**, **UI** modules
* **Real on‐disk folders only** (blue in Finder)
* **No Xcode folder-references** (blue icons) or un-backed virtual groups

## 🔍 Testing

* **XCTest** for unit tests
* **Swift Testing** conventions

## 📊 Charts & Visualization

* **Swift Charts** for elevation / metric graphs

## 🌍 Location & Motion

* **CoreLocation** (`CLLocationManager`)
* **CoreMotion** for speed, compass, etc.
* **GPX** route simulation in Simulator (Features → Location)

## 🗺️ Maps & AR

* **MapKit** (`MKMapView`, polylines, custom renderer)
* **ARKit** (e.g. helmet-cam preview overlay)

## 🏥 Health & Fitness

* **HealthKit** integration

  * `HealthKitManager` for permissions & sample insertion
  * `SyncRideUseCase` via `HKWorkoutBuilder`
* **Info.plist** keys for all platforms:

  * `NSLocationWhenInUseUsageDescription` (iOS & visionOS)
  * `NSLocationAlwaysAndWhenInUseUsageDescription` (macOS)
  * `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`

---

With this in place, you’re set to build a rock-solid, multi-module AshBike app in Xcode 16 using the very latest Apple frameworks and Swift language features.


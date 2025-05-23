Here’s a Swift 6 / iOS 17+–focused cheat-sheet for all your SwiftUI property-wrapper needs—no legacy wrappers, just the new, compiler-built macros:

---

## Property Wrappers: Old vs. New

| **Old (iOS 16)**              | **New (iOS 17+, Swift 6+)**        | **When to Use**                                              |
| ----------------------------- | ---------------------------------- | ------------------------------------------------------------ |
| `ObservableObject`            | ➡️ **`@observable`**               | Any class whose `var` props you want auto-track and publish. |
| `@StateObject`                | ➡️ **`@State`**                    | View-owned model: lifecycle tied to the view.                |
| `@ObservedObject` (read-only) | ➡️ *(no wrapper)*                  | Pull in an `@observable` model for read-only display.        |
| `@ObservedObject` (mutable)   | ➡️ **`@Bindable`**                 | Two-way binding into an `@observable` model.                 |
| `@EnvironmentObject`          | ➡️ **`@Environment(MyType.self)`** | Inject shared singletons or services.                        |

---

### 1. Defining an Observable Model

```swift
import SwiftUI

@observable       // replaces ObservableObject
class BikeRide {
  var distance: Double         // auto-published
  var notes: String?           // auto-published
  
  init(distance: Double, notes: String? = nil) {
    self.distance = distance
    self.notes = notes
  }
}
```

### 2. View-Owned State

Use `@State` to own one of these models in your view:

```swift
struct RideEditorView: View {
  @State private var ride = BikeRide(distance: 0)

  var body: some View {
    Form {
      Slider(value: $ride.distance, in: 0...100)
      TextField("Notes", text: $ride.notes.bound)
    }
  }
}
```

* **Why**: `@State` keeps the model alive as long as the view is alive, and persists across view reloads.

### 3. Read-Only Display

If a parent hands you a model and you only need to read its properties:

```swift
struct RideSummaryView: View {
  let ride: BikeRide          // no wrapper needed
  var body: some View {
    Text("\(ride.distance, format: .number) km")
  }
}
```

* **Why**: SwiftUI will automatically observe changes to `ride.distance` and re-render.

### 4. Two-Way Binding

When a child view must edit a parent’s model:

```swift
struct RideDetailView: View {
  @Bindable var ride: BikeRide   // replaces @ObservedObject for mutation

  var body: some View {
    VStack {
      TextField("Notes", text: $ride.notes.bound)
      Button("Reset") { ride.distance = 0 }
    }
  }
}
```

* **Why**: `@Bindable` wires up `@observable`’s setters & getters directly into `$` bindings.

### 5. Injected Services

For cross-app singletons (e.g. a HealthKit manager):

```swift
@main
struct AshBikeApp: App {
  @StateObject private var health = HealthKitManager.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(HealthKitManager.self, health)
    }
  }
}

struct ContentView: View {
  @Environment(HealthKitManager.self) private var health

  var body: some View { /* use health */ }
}
```

* **Why**: `@Environment(Service.self)` replaces the brittle `@EnvironmentObject`.

---

## Quick Guidelines

1. **One model = one wrapper**

   * If the view *owns* it → `@State`
   * If the view *reads* a shared/parent model → no wrapper
   * If the view *mutates* a passed-in model → `@Bindable`

2. **Avoid `ObservableObject` & `@Published`**
   – With Swift 6 you no longer need to mark each property—`@observable` does it for you.

3. **Preferred folder layout**

   * `Models/` → all your `@observable` classes
   * `Views/` → your SwiftUI screens
   * `Components/` → reusable UI bits
   * `Services/` → singletons injected via `@Environment`

4. **Use `.bound` for optionals**

   * The `.bound` helper smoothly converts `String?` to `String` bindings.

5. **Testing tip**

   * You can instantiate and modify `@observable` classes in XCTest directly—no longer need to drive tests through Combine.

---

By adopting these new wrappers in iOS 17+ and Swift 6, you get zero-boilerplate reactivity, crystal-clear ownership semantics, and rock-solid compile-time safety.


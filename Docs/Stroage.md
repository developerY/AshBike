# Active Record, ViewModel, and SwiftData: A Quick Guide

This guide contrasts two common UI-architecture patterns when using Apple’s SwiftData framework: the **Active Record** pattern 
(leveraging SwiftData’s built-in observability) and the classic **ViewModel** pattern. You’ll learn how each integrates with 
`@Model`, `@Query`, and `@Bindable`, and when to choose one over the other.

---

## 1. Active Record Pattern with SwiftData

SwiftData’s `@Model` types are automatically observable and change-driven. By combining `@Query` and `@Bindable`, 
you can treat your models like Active Records—CRUD operations happen directly on the model, and your SwiftUI views update themselves.

### Model Definition

```swift
import SwiftData

@Model
class BikeRide {
  @Attribute(.unique) var id = UUID()
  var startTime: Date
  var endTime: Date
  var totalDistance: Double
  var notes: String?

  init(startTime: Date, endTime: Date, totalDistance: Double, notes: String? = nil) {
    self.startTime = startTime
    self.endTime = endTime
    self.totalDistance = totalDistance
    self.notes = notes
  }
}
```

### Fetching & Display

```swift
struct TripsListView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \.startTime, order: .forward) private var rides: [BikeRide]

  var body: some View {
    List {
      ForEach(rides) { ride in
        Text("\(ride.totalDistance / 1000, format: .number) km")
      }
      .onDelete { offsets in
        offsets.forEach { context.delete(rides[$0]) }
        try? context.save()
      }
    }
  }
}
```

### Editing In-Place

```swift
struct RideDetailView: View {
  @Bindable var ride: BikeRide    // SwiftData makes @Model bindable

  var body: some View {
    Form {
      DatePicker("Start", selection: $ride.startTime)
      TextField("Notes", text: $ride.notes.bound)
      // …
    }
    .toolbar {
      Button("Save") { try? ride.modelContext?.save() }
    }
  }
}
```

### Pros & Cons

| Pros                                               | Cons                                               |
| -------------------------------------------------- | -------------------------------------------------- |
| • Zero extra glue code: your models drive the UI   | • All persistence logic lives in your views        |
| • Automatic change notifications and batch updates | • Harder to encapsulate complex business workflows |
| • Very little boilerplate for simple CRUD          | • Less separation between storage and presentation |

---

## 2. ViewModel Pattern with SwiftData

In more complex apps—especially when you need computed state, background syncing, or multi-model transactions—a thin ViewModel layer can help encapsulate business logic, transformations, and side-effects.

### Model Definition

(same as above)

### ViewModel Example

```swift
import Foundation
import SwiftData
import Combine

@MainActor
class TripsViewModel: ObservableObject {
  @Published var rides: [BikeRide] = []

  private let context: ModelContext

  init(context: ModelContext = .shared) {
    self.context = context
    fetchRides()
  }

  func fetchRides() {
    let descriptor = FetchDescriptor<BikeRide>(sortBy: \.startTime, order: .forward)
    rides = context.fetch(descriptor)
  }

  func delete(_ ride: BikeRide) {
    context.delete(ride)
    try? context.save()
    fetchRides()
  }
}
```

### View Harnessing the ViewModel

```swift
struct TripsView: View {
  @StateObject private var vm = TripsViewModel()

  var body: some View {
    List {
      ForEach(vm.rides) { ride in
        Text("\(ride.totalDistance / 1000, format: .number) km")
      }
      .onDelete { idx in idx.map { vm.delete(vm.rides[$0]) } }
    }
    .onAppear(perform: vm.fetchRides)
  }
}
```

### Pros & Cons

| Pros                                                            | Cons                                                            |
| --------------------------------------------------------------- | --------------------------------------------------------------- |
| • Clear separation of presentation vs. persistence logic        | • More boilerplate (`@Published`, `fetch`, mappings, etc.)      |
| • Easy to inject mocks for testing                              | • Potential sync bugs if VM and model get out of date           |
| • Best for complex business workflows (batch, sync, validation) | • Views no longer update for ad-hoc model changes automatically |

---

## 3. When to Choose Which

| Scenario                                        | Recommended Pattern |
| ----------------------------------------------- | ------------------- |
| Simple CRUD, direct model binding               | **Active Record**   |
| Lightweight app, few inter-model relations      | Active Record       |
| Complex workflows, background syncing, batching | **ViewModel**       |
| Need custom transformations or computed state   | ViewModel           |
| Strict testability and mocking                  | ViewModel           |

---

### Migration Tips

* **From ViewModel → Active Record**:
  • Replace `@Published` arrays with `@Query`.
  • Pass `@Bindable var model` into your views.
  • Move delete/insert logic into modelContext calls.

* **From Active Record → ViewModel**:
  • Introduce an ObservableObject that holds `@Query` data.
  • Expose only the properties the view needs.
  • Encapsulate side-effects (e.g. save(), delete()) in the VM.

---

SwiftData gives you the flexibility to pick the right level of indirection for your app’s complexity. For most straightforward data-driven screens, lean into **Active Record**. When your logic grows richer, extract a thin **ViewModel** to keep your codebase maintainable, testable, and clear.


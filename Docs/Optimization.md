# AshBike Pre-Ship Performance Plan

This document outlines the performance and optimization analysis plan to be executed before shipping. The goal is to profile critical user flows, identify bottlenecks, and gather graphs and reports to verify the app is performant and efficient.

All deliverables (screenshots, reports) should be collected and checked into a subfolder here.

## Phase 1: SwiftUI View Rendering

This phase identifies which views are re-rendering unnecessarily.

* **Tool**: SwiftUI View Updates (Debug View Hierarchy)
* **Action**:
    1.  Run the app in the simulator or on a device.
    2.  Open the "Debug View Hierarchy" and select "Show View Updates."
    3.  Interact with the app, especially the `HomeView` during a live ride.
* **Analysis**:
    * Watch for flashing colored borders, which indicate a view `body` re-computation.
    * **Goal**: Confirm that only the necessary views (e.g., `GaugeView`, `LiveMetricsView`) are updating when live data changes.
* **Deliverable**: `ViewUpdates.png`

---

## Phase 2: CPU, Memory, and Disk I/O (Instruments)

This phase uses Xcode Instruments on a **Release build** (`Product > Profile`).

### 1. CPU Hot Spots

* **Tool**: **Time Profiler** instrument.
* **Action**:
    1.  Start profiling.
    2.  Execute a "critical path" user flow:
        * App cold launch.
        * Start a new ride.
        * Run for 30 seconds.
        * Stop the ride.
        * Navigate to the "Rides" tab.
        * Scroll the `RideListView`.
        * Open the `RideDetailView`.
        * Delete the ride.
* **Analysis**:
    * Check the "Call Tree" (bottom-up) for your app's functions that use the most CPU.
    * **Goal**: Ensure no single function in `RideSessionManager` or a view's computed property is dominating the CPU.
* **Deliverable**: `TimeProfiler.png`

### 2. Memory Leaks & Allocations

* **Tool**: **Leaks** and **Allocations** instruments.
* **Action**:
    1.  Start profiling.
    2.  Perform the same critical path flow (Section 2.1) **three times in a row** within the same session.
* **Analysis**:
    * **Leaks**: Check for any red entries in the Leaks instrument.
    * **Allocations**: Observe the graph. Memory should rise and fall, returning to a stable baseline after navigation. A constantly climbing baseline indicates a memory growth issue.
* **Deliverable**: `Allocations.png` (showing stable baseline), `Leaks.png` (showing "0 Leaks").

### 3. SwiftData & Disk I/O

* **Tool**: **SwiftData** instrument.
* **Action**:
    1.  Profile the "Stop Ride" and "Delete Ride" actions.
    2.  Observe the save/delete operations from the `RideDataManager` and `RideStore`.
* **Analysis**:
    * **Goal**: Confirm that database writes are fast and handled on a background thread (as your `RideStore` actor is designed to do). Check for any unexpected or excessive data fetching.
* **Deliverable**: `SwiftData.png`

---

## Phase 3: App Vitals (On-Device)

This must be performed on a **physical device, unplugged** from Xcode.

* **Tool**: **Energy Log** instrument.
* **Action**:
    1.  Profile with the Energy Log instrument.
    2.  Start a ride and let the app run for 5-10 minutes.
    3.  Test with both the screen on and the screen off.
* **Analysis**:
    * Observe the "Energy Impact" level.
    * **Goal**: Confirm that energy use drops significantly when the ride is *not* recording, validating the `configureForIdle()` logic.
* **Deliverable**: `EnergyLog.png`

---

## Phase 4: App Size

* **Tool**: Xcode Archive Organizer
* **Action**:
    1.  Create an Archive (`Product > Archive`).
    2.  In the Organizer, select the archive and click "Distribute App."
    3.  Choose "Ad Hoc" and select "All compatible device variants" for thinning.
    4.  Export and locate the `App Thinning Size Report.txt`.
* **Analysis**:
    * Review the download and install size for different devices.
    * **Goal**: Ensure no assets are unexpectedly large and the total app size is reasonable.
* **Deliverable**: `AppThinningReport.txt`

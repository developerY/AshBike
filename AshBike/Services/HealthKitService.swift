//
//  HealthKitService.swift
//  AshBike
//
//  Created by Gemini
//
import Foundation
import HealthKit
import CoreLocation
import Observation


@Observable
class HealthKitService {
    
    private let healthStore = HKHealthStore()
    // defined in Shared/Utilities/Constants.swift
    //private let rideIdentifierKey = "com.ashbike.ride.id" // Metadata key
    
    // --- ADD THIS PROPERTY TO MANAGE THE OBSERVER QUERY ---
    private var heartRateQuery: HKObserverQuery?
    
    // --- MODIFY THIS SET TO REQUEST HEART RATE PERMISSION ---
    private var readDataTypes: Set<HKObjectType> {
        return [
            HKObjectType.workoutType(),
            // Add Heart Rate
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
    }
    
    private var writeDataTypes: Set<HKSampleType> {
        return [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
            HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes, completion: completion)
    }
    
    // --- ADD THE FOLLOWING TWO FUNCTIONS TO THE CLASS ---

     /// Starts a long-running query that observes for new heart rate samples.
     func startObservingHeartRate(completion: @escaping (Double) -> Void) {
         let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
         
         // If a query is already active, stop it before starting a new one.
         if let heartRateQuery = heartRateQuery {
             healthStore.stop(heartRateQuery)
         }

         // Create a new observer query.
         heartRateQuery = HKObserverQuery(
             sampleType: heartRateType,
             predicate: nil
         ) { [weak self] (query, completionHandler, error) in
             guard error == nil else { return }
             
             // When new data is available, fetch the most recent sample.
             self?.fetchLatestHeartRateSample(completion: { sample in
                 guard let sample = sample else { return }
                 
                 // Get the heart rate in Beats Per Minute (BPM)
                 let heartRate = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                 
                 // Pass the new value to the completion handler on the main thread
                 DispatchQueue.main.async {
                     completion(heartRate)
                 }
             })
             
             // Mark the query as complete to receive new updates.
             completionHandler()
         }
         
         // Execute the query.
         healthStore.execute(heartRateQuery!)
     }

     /// Stops the active heart rate observer query.
     func stopObservingHeartRate() {
         if let heartRateQuery = heartRateQuery {
             healthStore.stop(heartRateQuery)
             self.heartRateQuery = nil
         }
     }
     
     /// Fetches the single most recent heart rate sample from HealthKit.
     private func fetchLatestHeartRateSample(completion: @escaping (HKQuantitySample?) -> Void) {
         let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
         let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
         
         let query = HKSampleQuery(
             sampleType: heartRateType,
             predicate: nil,
             limit: 1,
             sortDescriptors: [sortDescriptor]
         ) { (query, samples, error) in
             completion(samples?.first as? HKQuantitySample)
         }
         
         healthStore.execute(query)
     }

    
    // This function is no longer the primary method, but we can leave it.
    func checkIfRideIsSynced(ride: BikeRide, completion: @escaping (Bool) -> Void) {
        // Note: This would also need to be updated to the new query logic if used.
        fetchSyncStatus(for: [ride]) { syncedIDs in
            completion(!syncedIDs.isEmpty)
        }
    }
    
    // ** FIX #1: THE QUERY **
    // The query now targets the specific sample type where we store the metadata.
    func fetchSyncStatus(for rides: [BikeRide], completion: @escaping (Set<UUID>) -> Void) {
        let rideIDs = rides.map { $0.id.uuidString }
        guard !rideIDs.isEmpty else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForObjects(withMetadataKey: Constants.HealthKit.rideIdentifierKey, allowedValues: rideIDs)

        // Query for the Active Energy samples that contain our metadata.
        let query = HKSampleQuery(
            sampleType: HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { (query, samples, error) in
            guard let syncedSamples = samples, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // Extract the original UUIDs from the sample metadata
            let syncedIDs = syncedSamples.compactMap { sample -> UUID? in
                if let idString = sample.metadata?[Constants.HealthKit.rideIdentifierKey] as? String {
                    return UUID(uuidString: idString)
                }
                return nil
            }
            
            DispatchQueue.main.async {
                completion(Set(syncedIDs))
            }
        }
        healthStore.execute(query)
    }

    // ** FIX #2: THE SAVE **
    // The metadata is now attached to the energy sample.
    func save(bikeRide: BikeRide, completion: @escaping (Bool, Error?) -> Void) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

        builder.beginCollection(withStart: bikeRide.startTime) { success, error in
            guard success else { completion(false, error); return }
        }

        let locations = bikeRide.locations.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        if !locations.isEmpty {
            routeBuilder.insertRouteData(locations) { success, error in
                if !success { print("Error saving workout route: \(error?.localizedDescription ?? "Unknown")") }
            }
        }

        // Attach our unique ride ID to the metadata of a sample that will always exist.
        let metadata: [String: Any] = [Constants.HealthKit.rideIdentifierKey: bikeRide.id.uuidString]

        let totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(bikeRide.calories))
        let energySample = HKCumulativeQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            quantity: totalEnergyBurned,
            start: bikeRide.startTime,
            end: bikeRide.endTime,
            metadata: metadata // Metadata is attached here
        )

        let totalDistance = HKQuantity(unit: .meter(), doubleValue: bikeRide.totalDistance)
        let distanceSample = HKCumulativeQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            quantity: totalDistance,
            start: bikeRide.startTime,
            end: bikeRide.endTime
        )

        builder.add([energySample, distanceSample]) { success, error in
            guard success else { completion(false, error); return }
        }

        builder.endCollection(withEnd: bikeRide.endTime) { success, error in
            guard success else { completion(false, error); return }

            builder.finishWorkout(completion: { (workout, error) in
                guard let workout = workout else {
                    completion(false, error)
                    return
                }

                if !locations.isEmpty {
                    // The route doesn't need the metadata, as it's now on the energy sample.
                    routeBuilder.finishRoute(with: workout, metadata: nil) { (route, error) in
                        completion(error == nil, error)
                    }
                } else {
                    // If there's no route, the workout is saved successfully.
                    completion(true, nil)
                }
            })
        }
    }
}

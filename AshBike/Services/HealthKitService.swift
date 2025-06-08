//
//  HealthKitService.swift
//  AshBike
//
//  Created by Gemini
//
import Foundation
import HealthKit
import CoreLocation

class HealthKitService {
    
    private let healthStore = HKHealthStore()
    
    /// The specific data types we want to read from or write to HealthKit.
    private var readDataTypes: Set<HKObjectType> {
        return [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute() // Permission to read routes
        ]
    }
    
    private var writeDataTypes: Set<HKSampleType> {
        return [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(), // Permission to write routes
            HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
            HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
    }
    
    /// Requests authorization from the user to access HealthKit data.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.ashbike.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes, completion: completion)
    }
    
    /// Saves a completed bike ride to HealthKit using the modern HKWorkoutBuilder.
    func save(bikeRide: BikeRide, completion: @escaping (Bool, Error?) -> Void) {
        // 1. Create a workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        
        // 2. Create the workout builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        // 3. Create builders for the route and the workout itself
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        
        // 4. Start the builders
        builder.beginCollection(withStart: bikeRide.startTime) { (success, error) in
            guard success else {
                completion(false, error)
                return
            }
        }
        
        // 5. Add the location data to the route builder
        let locations = bikeRide.locations.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }
        
        routeBuilder.insertRouteData(locations) { (success, error) in
            guard success else {
                // If route fails, we can still try to save the workout
                print("Error saving workout route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
        
        // 6. Add samples for calories and distance
        let totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(bikeRide.calories))
        let energySample = HKCumulativeQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, quantity: totalEnergyBurned, start: bikeRide.startTime, end: bikeRide.endTime)
        
        let totalDistance = HKQuantity(unit: .meter(), doubleValue: bikeRide.totalDistance)
        let distanceSample = HKCumulativeQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .distanceCycling)!, quantity: totalDistance, start: bikeRide.startTime, end: bikeRide.endTime)
        
        builder.add([energySample, distanceSample]) { (success, error) in
            guard success else {
                completion(false, error)
                return
            }
        }
        
        // 7. Finalize and save everything
        builder.endCollection(withEnd: bikeRide.endTime) { (success, error) in
            guard success else {
                completion(false, error)
                return
            }
            
            builder.finishWorkout(completion: { (workout, error) in
                guard let workout = workout else {
                    completion(false, error)
                    return
                }
                
                // Add the saved route to the workout
                routeBuilder.finishRoute(with: workout, metadata: nil) { (route, error) in
                    if let error = error {
                        print("Error associating route with workout: \(error.localizedDescription)")
                    }
                    // Complete successfully even if route association fails
                    completion(true, nil)
                }
            })
        }
    }
}

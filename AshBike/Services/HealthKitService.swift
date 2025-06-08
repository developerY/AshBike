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
    private let rideIdentifierKey = "com.ashbike.ride.id" // Metadata key
    
    private var readDataTypes: Set<HKObjectType> {
        return [HKObjectType.workoutType()]
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
    
    // NEW: Function to check sync status
    func checkIfRideIsSynced(ride: BikeRide, completion: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForObjects(withMetadataKey: rideIdentifierKey, allowedValues: [ride.id.uuidString])
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                completion(samples?.first != nil)
            }
        }
        healthStore.execute(query)
    }

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
        routeBuilder.insertRouteData(locations) { success, error in
            if !success { print("Error saving workout route: \(error?.localizedDescription ?? "Unknown")") }
        }
        
        let totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(bikeRide.calories))
        let energySample = HKCumulativeQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, quantity: totalEnergyBurned, start: bikeRide.startTime, end: bikeRide.endTime)
        
        let totalDistance = HKQuantity(unit: .meter(), doubleValue: bikeRide.totalDistance)
        let distanceSample = HKCumulativeQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .distanceCycling)!, quantity: totalDistance, start: bikeRide.startTime, end: bikeRide.endTime)
        
        builder.add([energySample, distanceSample]) { success, error in
            guard success else { completion(false, error); return }
        }
        
        builder.endCollection(withEnd: bikeRide.endTime) { success, error in
            guard success else { completion(false, error); return }
            
            // Add our unique ride ID to the workout metadata
            let metadata = [self.rideIdentifierKey: bikeRide.id.uuidString]
            
            builder.finishWorkout(completion: { (workout, error) in
                guard let workout = workout else { completion(false, error); return }
                
                routeBuilder.finishRoute(with: workout, metadata: metadata) { (route, error) in
                    completion(error == nil, error)
                }
            })
        }
    }
}

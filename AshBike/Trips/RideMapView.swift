//
//  RideMapView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftUI
import MapKit

struct RideMapView: View {
    let route: [CLLocationCoordinate2D]
    
    // The map's region is calculated once and stored in state.
    @State private var region: MKCoordinateRegion

    init(route: [CLLocationCoordinate2D]) {
        self.route = route
        self._region = State(initialValue: RideMapView.region(for: route))
    }

    var body: some View {
        // If the route is empty, show a helpful message instead of a map at (0,0).
        if route.isEmpty {
            ContentUnavailableView {
                Label("No Route Data", systemImage: "map.circle")
            } description: {
                Text("This ride does not have any GPS location data to display.")
            }
        } else {
            // Use the calculated region to set the map's initial position.
            Map(initialPosition: .region(region)) {
                // Draw the polyline for the route if it has at least 2 points.
                if route.count > 1 {
                    MapPolyline(coordinates: route)
                        .stroke(.blue, lineWidth: 4)
                }
            }
        }
    }

    /// Calculates a map region that fits all the given coordinates.
    static func region(for route: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        // Handle empty or single-point routes gracefully.
        guard let first = route.first else {
            return MKCoordinateRegion() // An empty region.
        }
        
        if route.count == 1 {
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        // Find the minimum and maximum latitude and longitude to create a bounding box.
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for point in route {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        // Calculate the center and span for the region.
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.4, // Add 40% padding for better visuals
            longitudeDelta: (maxLon - minLon) * 1.4 // Add 40% padding
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

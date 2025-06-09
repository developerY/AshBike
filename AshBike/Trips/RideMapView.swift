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
        // If the route is empty, show a helpful message.
        if route.isEmpty {
            ContentUnavailableView {
                Label("No Route Data", systemImage: "map.circle")
            } description: {
                Text("This ride does not have any GPS location data to display.")
            }
        } else {
            // Use the calculated region to set the map's initial position.
            Map(initialPosition: .region(region)) {
                // This loop draws the route as individual segments (1->2, 2->3, etc.)
                // which bypasses rendering bugs and creates a single, continuous path.
                if route.count > 1 {
                    ForEach(0..<route.count - 1, id: \.self) { i in
                        // Create a two-point array for each segment of the ride
                        let segment = [route[i], route[i+1]]
                        MapPolyline(coordinates: segment)
                            .stroke(.blue, lineWidth: 4)
                    }
                }
            }
        }
    }

    /// Calculates a map region that fits all the given coordinates.
    static func region(for route: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = route.first else {
            return MKCoordinateRegion()
        }
        
        if route.count == 1 {
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        // Find the bounding box that contains the entire route.
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude

        for point in route {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        // Create a region with a bit of padding.
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.4,
            longitudeDelta: (maxLon - minLon) * 1.4
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}


// The CLLocationCoordinate2D type needs to be Hashable to be used in a ForEach loop.
// This extension adds that conformance.
extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

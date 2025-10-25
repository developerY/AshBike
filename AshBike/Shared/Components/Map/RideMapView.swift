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

    // --- 1. CHANGE STATE VARIABLE ---
    // Change from MKCoordinateRegion to MapCameraPosition
    // Initialize centered on a default location or the first point.
    @State private var cameraPosition: MapCameraPosition
    
    // --- NEW: Computed property for the single polyline ---
    private var routePolyline: MapPolyline? {
        guard route.count > 1 else { return nil }
        return MapPolyline(coordinates: route)
    }

    init(route: [CLLocationCoordinate2D]) {
        self.route = route
        
        // --- 2. UPDATE INITIALIZER ---
        // Initialize cameraPosition. Center on the first point if available,
        // otherwise use a default region. Add a sensible span/zoom.
        let initialCenter = route.first ?? CLLocationCoordinate2D(latitude: 37.331705, longitude: -122.030237) // Default to Cupertino
        let initialRegion = MKCoordinateRegion(
            center: initialCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Adjust zoom level as needed
        )
        self._cameraPosition = State(initialValue: .region(initialRegion))
    }

    var body: some View {
        if route.isEmpty {
            ContentUnavailableView {
                Label("No Route Data", systemImage: "map.circle")
            } description: {
                Text("This ride does not have any GPS location data to display.")
            }
        } else {
            // --- 3. BIND MAP TO CAMERA POSITION ---
            // Use Map(position:) instead of Map(initialPosition:)
            Map(position: $cameraPosition) {
                // Drawing the polyline remains the same
                if route.count > 1 {
                    ForEach(0..<route.count - 1, id: \.self) { i in
                        let segment = [route[i], route[i+1]]
                        MapPolyline(coordinates: segment)
                            .stroke(.blue, lineWidth: 4)
                    }
                }
                
                // Optional: Add a marker for the current (last) position
                if let lastCoordinate = route.last {
                   Marker("Current", coordinate: lastCoordinate)
                }
            }
            // --- 4. ADD ONCHANGE MODIFIER ---
            // Update the camera position whenever the route changes
            .onChange(of: route) {
                // Center the map on the last coordinate
                if let lastCoordinate = route.last {
                    withAnimation { // Smoothly animate the camera movement
                        // Keep the same span (zoom level) but change the center
                        let currentSpan = cameraPosition.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        cameraPosition = .region(MKCoordinateRegion(center: lastCoordinate, span: currentSpan))
                    }
                }
            }
        }
    }
    
    // The static region calculation function is no longer needed for centering,
    // but you might keep it if you need to calculate a bounding box elsewhere.
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

struct RideMapView_Previews: PreviewProvider {
    static var sampleRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3349, longitude: -122.0090),
        .init(latitude: 37.3350, longitude: -122.0091),
        .init(latitude: 37.3351, longitude: -122.0092)
    ]

    static var previews: some View {
        RideMapView(route: sampleRoute)
            .frame(height: 200)
            .previewLayout(.sizeThatFits)
    }
}

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
    let showUserLocation: Bool
    @State private var cameraPosition: MapCameraPosition

    private var routePolyline: MapPolyline? {
        guard route.count > 1 else { return nil }
        return MapPolyline(coordinates: route)
    }

    private struct RouteSnapshot: Equatable {
        let count: Int
        let lastLat: CLLocationDegrees?
        let lastLon: CLLocationDegrees?
    }

    private var routeSnapshot: RouteSnapshot {
        RouteSnapshot(
            count: route.count,
            lastLat: route.last?.latitude,
            lastLon: route.last?.longitude
        )
    }

    init(route: [CLLocationCoordinate2D], showUserLocation: Bool = true) {
        self.route = route
        self.showUserLocation = showUserLocation

        // --- THIS IS THE FIX ---
        let initialRegion: MKCoordinateRegion
        if !showUserLocation {
            // Calculate bounding region for the *entire* route
            initialRegion = RideMapView.region(for: route) // Use static helper
        } else {
            // Existing behavior for live view (center on first point initially)
            let initialCenter = route.first ?? CLLocationCoordinate2D(latitude: 37.331705, longitude: -122.030237)
            initialRegion = MKCoordinateRegion(
                center: initialCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        self._cameraPosition = State(initialValue: .region(initialRegion))
        // --- END FIX ---
    }

    var body: some View {
        if route.isEmpty {
            ContentUnavailableView {
                Label("No Route Data", systemImage: "map.circle")
            } description: {
                Text("This ride does not have any GPS location data to display.")
            }
        } else {
            Map(position: $cameraPosition) {
                if let polyline = routePolyline {
                    polyline
                        .stroke(.blue, lineWidth: 4)
                }
                if showUserLocation {
                    UserAnnotation()
                }
            }
            .mapControls {
                if showUserLocation {
                    MapUserLocationButton()
                }
                MapCompass()
                MapScaleView()
            }
            .onChange(of: routeSnapshot) {
                // Only update camera for the live view
                if showUserLocation, let lastCoordinate = route.last {
                    withAnimation {
                        let currentSpan = cameraPosition.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        cameraPosition = .region(MKCoordinateRegion(center: lastCoordinate, span: currentSpan))
                    }
                }
                // No camera update needed here for the static detail view
            }
        }
    }
    
    // --- ADD BACK THE STATIC HELPER FUNCTION ---
    /// Calculates a map region that fits all the given coordinates.
    static func region(for route: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !route.isEmpty else {
            // Return a default region if the route is empty
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.331705, longitude: -122.030237), // Cupertino
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        if route.count == 1, let first = route.first {
            // If only one point, center on it with a small span
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        // Find the bounding box that contains the entire route.
        var minLat = route[0].latitude, maxLat = route[0].latitude
        var minLon = route[0].longitude, maxLon = route[0].longitude

        for point in route {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        // Calculate center and span with padding.
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        // Ensure span is not zero and add padding
        let latitudeDelta = max(abs(maxLat - minLat) * 1.4, 0.01) // Add minimum span
        let longitudeDelta = max(abs(maxLon - minLon) * 1.4, 0.01) // Add minimum span
        let span = MKCoordinateSpan(
            latitudeDelta: latitudeDelta,
            longitudeDelta: longitudeDelta
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

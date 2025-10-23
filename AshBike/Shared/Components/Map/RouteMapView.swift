//
//  RouteMapView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
// Views/RouteMapView.swift
import SwiftUI
import MapKit

struct RouteMapView: UIViewRepresentable {
    /// The path traveled so far
    var route: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Maintain a single polyline overlay to avoid re-adding everything on each update
        let poly = MKPolyline(coordinates: route, count: route.count)
        if let existing = context.coordinator.polyline {
            uiView.removeOverlay(existing)
        }
        context.coordinator.polyline = poly
        uiView.addOverlay(poly)

        // Center on the latest point
        if let last = route.last {
            uiView.setCenter(last, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: RouteMapView
        var polyline: MKPolyline?
        init(_ parent: RouteMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = .systemBlue
            r.lineWidth = 4
            return r
        }
    }
}

struct RouteMapView_Previews: PreviewProvider {
    static var sampleRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3349, longitude: -122.0090),
        .init(latitude: 37.3350, longitude: -122.0091),
        .init(latitude: 37.3351, longitude: -122.0092)
    ]

    static var previews: some View {
        RouteMapView(route: sampleRoute)
            .frame(height: 200)
            .previewLayout(.sizeThatFits)
    }
}


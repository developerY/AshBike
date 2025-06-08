//
//  RideMapView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/25/25.
//
import SwiftUI
import MapKit

// This view is now refactored to use the reliable UIViewRepresentable pattern,
// matching the technology of the working "Live Route" map in your app.
struct RideMapView: UIViewRepresentable {
    let route: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        // We are viewing a past ride, so we don't need to show the user's live location.
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Always clear any old overlays before drawing the new one.
        uiView.removeOverlays(uiView.overlays)
        
        if route.count > 1 {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            uiView.addOverlay(polyline)
            
            // This is the proper way to zoom the map to fit the entire route.
            // It calculates the bounding box of the line and adds some padding.
            uiView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                animated: true
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // The Coordinator handles rendering the blue line for our polyline.
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RideMapView

        init(_ parent: RideMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

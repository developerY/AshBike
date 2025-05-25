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

  private var region: MKCoordinateRegion {
    MKCoordinateRegion(
      center: route.last ?? .init(),
      span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
  }

  var body: some View {
    Map(position: .constant(.region(region))) {
      if route.count > 1 {
        MapPolyline(coordinates: route)
          .stroke(.blue, lineWidth: 3)
      }
    }
  }
}

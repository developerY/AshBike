//
//  HomeMapView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/24/25.
//
import SwiftUI
import MapKit
import CoreLocation

struct HomeMapView: View {
    @Binding var coords: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion
    
    init(route: Binding<[CLLocationCoordinate2D]>) {
        self._coords = route
        
        // start centered on the first fix (or 0,0)
        let start = route.wrappedValue.first
        ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        self._region = State(initialValue:
                                MKCoordinateRegion(
                                    center: start,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01,
                                                           longitudeDelta: 0.01)
                                )
        )
    }
    
    var body: some View {
        Text("hi")
        /*Map(
         coordinateRegion: $region,
         interactionModes: .all,
         showsUserLocation: true
         ) {
         // this closure is the “overlay” builder
         if coords.count > 1 {
         MapPolyline(coordinates: coords)
         .stroke(.blue, lineWidth: 4)
         }
         }
         .frame(height: 200)
         .cornerRadius(8)
         }*/
    }
    
}

struct HomeMapView_Previews: PreviewProvider {
  static let sample = [
    CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
    CLLocationCoordinate2D(latitude: 37.3350, longitude: -122.0091),
    CLLocationCoordinate2D(latitude: 37.3351, longitude: -122.0092),
  ]

  static var previews: some View {
    HomeMapView(route: .constant(sample))
      .previewLayout(.sizeThatFits)
  }
}


//
//  ContentView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .home

    enum Tab {
        case home, ride, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)

            RideLinksView()//RideView()      // or LiveRideView()
                .tabItem {
                    Label("Ride", systemImage: "bicycle")
                }
                .tag(Tab.ride)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .accentColor(.blue) // or your custom tint
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview in both light and dark mode, and on multiple devices
        Group {
            ContentView()
                .previewDisplayName("iPhone 15 Pro – Light")
                .previewDevice("iPhone 15 Pro")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone 15 Pro – Dark")
                .previewDevice("iPhone 15 Pro")
            
            ContentView()
                .previewDisplayName("iPad Air (5th gen)")
                .previewDevice("iPad Air (5th generation)")
        }
    }
}

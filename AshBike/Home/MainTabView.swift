//
//  MainTabView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/26/25.
//
import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .home

    enum Tab {
        case home, ride, settings
    }

    
    var body: some View {
        TabView {
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
            
            RideListView()
                .tabItem {
                    Label("Open", systemImage: "bicycle")
                }


            // 3rd tab
            Text("Settings Screen")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}


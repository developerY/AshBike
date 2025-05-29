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

            RideListView()
                .tabItem {
                    Label("Open", systemImage: "bicycle")
                }
                .tag(Tab.ride)

            // 3rd tab
            SettingsView()
            //Text("Settings Screen")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
}

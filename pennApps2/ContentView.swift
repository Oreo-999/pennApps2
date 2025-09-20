//
//  ContentView.swift
//  pennApps2
//
//  Created by Aryan Sharma on 9/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        TabView {
            MapTabView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            FeedView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Feed")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(themeManager.primaryColor)
    }
}

#Preview {
    ContentView()
}

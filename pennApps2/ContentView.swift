//
//  ContentView.swift
//  pennApps2
//
//  Created by Aryan Sharma on 9/20/25.
//

import SwiftUI

struct ContentView: View {
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
            
            // Placeholder for Profile tab
            VStack {
                Image(systemName: "person")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Profile Coming Soon!")
                    .font(.headline)
                Text("This will show your posts and settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .tabItem {
                Image(systemName: "person")
                Text("Profile")
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}

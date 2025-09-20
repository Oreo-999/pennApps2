//
//  pennApps2App.swift
//  pennApps2
//
//  Created by Aryan Sharma on 9/20/25.
//

import SwiftUI
import Firebase

@main
struct pennApps2App: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

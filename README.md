# Freebie

A community-driven iOS app that helps users discover and share free resources in their area. Built for PennApps 2025.

## Features

- Interactive map with real-time freebie locations
- Community reviews and ratings
- Smart filtering by category and distance
- Poop mode for bathroom reviews
- User profiles with contribution stats

## Built With

- SwiftUI
- Firebase Firestore
- Firebase Storage
- MapKit
- Core Location

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 26.0+
- Firebase project setup

### Installation

1. Clone the repository
2. Open `pennApps2.xcodeproj` in Xcode
3. Configure Firebase
   - Create a Firebase project
   - Add your iOS app to the project
   - Download `GoogleService-Info.plist` and add it to the project
   - Enable Firestore and Storage in Firebase Console
4. Build and run the project

## Project Structure

```
pennApps2/
├── Models/
│   ├── Freebie.swift
│   └── Review.swift
├── Views/
│   ├── MapTabView.swift
│   ├── FeedView.swift
│   ├── DetailView.swift
│   ├── ProfileView.swift
│   └── AddFreebieView.swift
├── Services/
│   ├── FirestoreService.swift
│   ├── LocationService.swift
│   ├── DeviceService.swift
│   └── ThemeManager.swift
└── Utils/
    └── Extensions/
```

## License

This project is licensed under the MIT License.

---

**Made for PennApps 2025**

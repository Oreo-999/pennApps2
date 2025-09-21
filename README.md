# Freebie

A gamified community-driven iOS app that helps users discover and share free resources in their area. Built for PennApps 2025.

## Features

### Core Functionality
- Interactive map with real-time freebie locations
- Community reviews and ratings system
- Smart filtering by category and distance
- Custom search radius with manual input
- Image upload and compression
- Location-based discovery

### Gamification System
- **Level System**: Users progress through levels (Newbie → Explorer → Hunter → Master → Legend → God)
- **XP & Achievements**: 8 different achievements with XP rewards
- **Progress Tracking**: Visual progress bars and completion status
- **User Titles**: Dynamic titles based on level and contribution
- **Achievement Gallery**: Detailed view of all achievements with progress

### Poop Mode
- **Bathroom Discovery**: Special mode for finding and rating bathrooms
- **Cleanliness Ratings**: 1-10 scale with dynamic brown visualization
- **Fun Popup Messages**: Randomized funny messages when toggling mode
- **Poop-themed UI**: Dynamic brown theming based on cleanliness ratings

### User Experience
- **Modern Glassmorphism UI**: Beautiful, minimal design with translucent materials
- **Smooth Animations**: Spring animations and smooth transitions
- **Navigation Integration**: Direct Apple Maps integration for directions
- **Profile Statistics**: Comprehensive user stats and contribution tracking
- **One Review Policy**: Users can only leave one review per freebie

## Built With

### Frontend
- **SwiftUI**: Modern iOS UI framework
- **MapKit**: Interactive maps and location services
- **Core Location**: GPS and location tracking
- **Combine**: Reactive programming framework

### Backend & Services
- **Firebase Firestore**: Real-time database
- **Firebase Storage**: Image storage and management
- **UserDefaults**: Local data persistence
- **NotificationCenter**: App-wide state management

### Design & UX
- **Glassmorphism**: Modern translucent UI design
- **Custom Animations**: Spring-based transitions
- **Haptic Feedback**: Tactile user interactions
- **Responsive Design**: Adaptive layouts for all devices

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

## Achievement System

Our gamification system includes 8 different achievements:

- **🎯 First Post** (50 XP): Post your first freebie
- **🏹 Freebie Hunter** (100 XP): Post 5 freebies  
- **🌟 Community Helper** (200 XP): Post 10 freebies
- **⭐ Review Master** (75 XP): Write 5 reviews
- **🚽 Bathroom Critic** (100 XP): Rate 3 bathrooms
- **❤️ Popular Poster** (150 XP): Get 10 upvotes
- **🔥 Viral Sensation** (300 XP): Get 50 upvotes
- **💩 Poop Mode Pro** (100 XP): Use poop mode 10 times

## Key Features in Detail

### Interactive Map
- Real-time freebie locations with custom pins
- Smooth panning and zooming without flickering
- Customizable search radius (1-50 miles)
- Location-based filtering and discovery

### Poop Mode
- Special bathroom discovery mode
- Cleanliness ratings with visual feedback
- Dynamic brown theming based on ratings
- Fun popup messages for engagement

### User Profiles
- Comprehensive statistics tracking
- Level progression system
- Achievement gallery with progress
- Contribution history and analytics

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

## Hackathon Impact

This project addresses real-world challenges through innovative technology:

- **Community Building**: Connects neighbors and builds local communities
- **Sustainability**: Promotes reuse and reduces waste
- **Accessibility**: Makes free resources easily discoverable
- **Gamification**: Encourages positive community engagement
- **Social Impact**: Helps people find what they need while reducing environmental impact

## Technical Highlights

- **Real-time Data**: Firebase Firestore for instant updates
- **Location Services**: Core Location and MapKit integration
- **Image Processing**: Automatic compression and optimization
- **State Management**: Combine framework for reactive programming
- **Modern UI**: SwiftUI with glassmorphism design patterns
- **Performance**: Optimized map rendering and smooth animations

## License

This project is licensed under the MIT License.

---

**Made for PennApps 2025** 🚀

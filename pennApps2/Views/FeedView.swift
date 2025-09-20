import SwiftUI
import CoreLocation
import FirebaseFirestore

struct FeedView: View {
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var locationService = LocationService()
    @State private var searchText = ""
    @State private var selectedCategory: Freebie.Category? = nil
    @State private var showingFilters = false
    @State private var searchRadius: Double = 5.0 // in miles
    @State private var customRadiusText = ""
    @StateObject private var themeManager = ThemeManager.shared
    
    var filteredAndSortedFreebies: [Freebie] {
        let filtered = firestoreService.freebies.filter { freebie in
            // Poop mode: only show bathrooms
            if themeManager.isPoopMode {
                guard freebie.category == .bathroom else { return false }
            }
            
            // Filter by search text
            let matchesSearch = searchText.isEmpty || 
                freebie.title.localizedCaseInsensitiveContains(searchText) ||
                freebie.description.localizedCaseInsensitiveContains(searchText)
            
            // Filter by category
            let matchesCategory = selectedCategory == nil || freebie.category == selectedCategory
            
            // Filter by distance (if user location available)
            var matchesDistance = true
            if let userLocation = locationService.currentLocation {
                let freebieLocation = CLLocation(
                    latitude: freebie.location.latitude,
                    longitude: freebie.location.longitude
                )
                let distance = userLocation.distance(from: freebieLocation) / 1609.34 // Convert to miles
                matchesDistance = distance <= searchRadius
            }
            
            return matchesSearch && matchesCategory && matchesDistance && freebie.isActive
        }
        
        // Sort by distance from user location
        return filtered.sorted { freebie1, freebie2 in
            guard let userLocation = locationService.currentLocation else {
                // If no user location, sort by creation date
                return freebie1.createdAt.dateValue() > freebie2.createdAt.dateValue()
            }
            
            let location1 = CLLocation(latitude: freebie1.location.latitude, longitude: freebie1.location.longitude)
            let location2 = CLLocation(latitude: freebie2.location.latitude, longitude: freebie2.location.longitude)
            
            let distance1 = userLocation.distance(from: location1)
            let distance2 = userLocation.distance(from: location2)
            
            return distance1 < distance2
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filter
                    VStack(spacing: 16) {
                        // Title and count
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Near Me")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("\(filteredAndSortedFreebies.count) freebies nearby")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Poop mode toggle
                            Button(action: {
                                themeManager.togglePoopMode()
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: themeManager.isPoopMode ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(themeManager.isPoopMode ? "Normal" : "Poop")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(themeManager.isPoopMode ? Color.brown : Color.orange)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Search bar
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                
                                TextField("Search freebies...", text: $searchText)
                                    .font(.system(size: 16))
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            // Filter button
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.blue)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                                    .overlay(
                                        Group {
                                            if selectedCategory != nil {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 8, height: 8)
                                                    .offset(x: 12, y: -12)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(Color(.systemGroupedBackground))
                    
                    // Filter panel
                    if showingFilters {
                        VStack(spacing: 20) {
                            // Search radius control
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Search Radius")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(searchRadius)) miles")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Text("1 mi")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $searchRadius, in: 1...50, step: 1)
                                        .accentColor(.blue)
                                    
                                    Text("50 mi")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Custom radius input
                                HStack {
                                    Text("Custom:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter miles", text: $customRadiusText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                    
                                    Button("Set") {
                                        if let radius = Double(customRadiusText), radius >= 1 && radius <= 50 {
                                            searchRadius = radius
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Category filter
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    ForEach(Freebie.Category.allCases, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = selectedCategory == category ? nil : category
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(category.emoji)
                                                    .font(.title2)
                                                
                                                Text(category.rawValue.capitalized)
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedCategory == category ? Color.blue : Color(.systemBackground))
                                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                    }
                    
                    // Feed content
                    if filteredAndSortedFreebies.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                Text("No freebies found")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Try adjusting your search or filters")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // Freebie cards
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredAndSortedFreebies) { freebie in
                                    FreebieCard(freebie: freebie, userLocation: locationService.currentLocation)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 100) // Space for tab bar
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            locationService.requestLocationPermission()
            locationService.startLocationUpdates()
            firestoreService.fetchFreebies()
        }
    }
}

struct FreebieCard: View {
    let freebie: Freebie
    let userLocation: CLLocation?
    @StateObject private var themeManager = ThemeManager.shared
    
    private var distance: String {
        guard let userLocation = userLocation else {
            return "Distance unknown"
        }
        
        let freebieLocation = CLLocation(
            latitude: freebie.location.latitude,
            longitude: freebie.location.longitude
        )
        
        let distanceInMiles = userLocation.distance(from: freebieLocation) / 1609.34
        
        if distanceInMiles < 1 {
            let distanceInFeet = distanceInMiles * 5280
            return String(format: "%.0f ft away", distanceInFeet)
        } else {
            return String(format: "%.1f mi away", distanceInMiles)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                if freebie.photoURL.hasPrefix("data:image") {
                    // Base64 image
                    if let data = Data(base64Encoded: freebie.photoURL.components(separatedBy: ",").last ?? ""),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        placeholderImage
                    }
                } else {
                    // URL image
                    AsyncImage(url: URL(string: freebie.photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderImage
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                // Category badge or poop visualization
                VStack {
                    HStack {
                        Spacer()
                        
                        if themeManager.isPoopMode && freebie.category == .bathroom {
                            // Poop mode: show poop based on cleanliness
                            PoopVisualization(cleanlinessRating: freebie.cleanlinessRating ?? 5.0)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                        } else {
                            // Normal mode: show category emoji
                            Text(freebie.category.emoji)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Title and distance
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(freebie.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", freebie.averageRating))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Description
                Text(freebie.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Stats and time
                HStack {
                    // Upvotes
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text("\(freebie.upvotes)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Time ago
                    Text(timeAgoString(from: freebie.createdAt.dateValue()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("No image")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    FeedView()
}

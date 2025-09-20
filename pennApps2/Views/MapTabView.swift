import SwiftUI
import MapKit
import FirebaseFirestore
import Combine

struct MapTabView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var deviceService = DeviceService()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var selectedFreebie: Freebie?
    @State private var showingBottomSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: Freebie.Category? = nil
    @State private var showingFilters = false
    @State private var showingAddFreebie = false
    @State private var searchRadius: Double = 5.0 // in miles
    @State private var customRadiusText = ""
    @State private var tokens: Set<AnyCancellable> = []
    @StateObject private var themeManager = ThemeManager.shared
    
    
    var filteredFreebies: [Freebie] {
        var filtered = firestoreService.freebies.filter { freebie in
            // Poop mode: only show bathrooms
            if themeManager.isPoopMode {
                guard freebie.category == .bathroom else { return false }
            }
            
            let matchesSearch = searchText.isEmpty || 
                freebie.title.localizedCaseInsensitiveContains(searchText) ||
                freebie.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || freebie.category == selectedCategory
            
            let matchesExpired = freebie.expiresAt.dateValue() > Date()
            
            // Distance filter
            var matchesDistance = true
            if let userLocation = locationService.currentLocation {
                let distance = locationService.calculateDistance(
                    from: userLocation,
                    to: freebie.location
                )
                let distanceInMiles = distance / 1609.34 // Convert meters to miles
                matchesDistance = distanceInMiles <= searchRadius
            }
            
            return matchesSearch && matchesCategory && matchesExpired && matchesDistance
        }
        
        // Sort by distance (closest first)
        if let userLocation = locationService.currentLocation {
            filtered.sort { freebie1, freebie2 in
                let distance1 = locationService.calculateDistance(from: userLocation, to: freebie1.location)
                let distance2 = locationService.calculateDistance(from: userLocation, to: freebie2.location)
                return distance1 < distance2
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ZStack {
            // Map with real data from Firestore
            Map(initialPosition: .region(region)) {
                // User location marker
                if let userLocation = locationService.currentLocation {
                    Annotation("Your Location", coordinate: userLocation.coordinate) {
                        UserLocationMarker()
                    }
                }
                
                // Freebie markers
                ForEach(filteredFreebies) { freebie in
                    Annotation(freebie.title, coordinate: CLLocationCoordinate2D(
                        latitude: freebie.location.latitude,
                        longitude: freebie.location.longitude
                    )) {
                        CustomMapPin(freebie: freebie) {
                            print("📌 Pin tapped for freebie: \(freebie.title) (ID: \(freebie.id ?? "nil"))")
                            
                            // Set selectedFreebie - this will automatically show the sheet
                            selectedFreebie = freebie
                            
                            print("📌 Set selectedFreebie to: \(freebie.title) - sheet will show automatically")
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
                .onAppear {
                    print("🗺️ MapTabView appeared - starting location setup")
                    observeCoordinateUpdates()
                    observeDeniedLocationAccess()
                    
                    // Request location permission first
                    locationService.requestLocationPermission()
                    
                    // Start location updates
                    locationService.startLocationUpdates()
                    
                    // Fetch freebies
                    firestoreService.fetchFreebies()
                    
                    // Check if we already have a location
                    if let userLocation = locationService.currentLocation {
                        print("📍 Found existing location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                        centerMapOnLocation(userLocation.coordinate)
                    } else {
                        print("📍 No existing location available, waiting for location updates...")
                        
                        // Try to get location after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if let userLocation = locationService.currentLocation {
                                print("📍 Found delayed location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                                centerMapOnLocation(userLocation.coordinate)
                            }
                        }
                    }
                }
            .onChange(of: firestoreService.freebies) { oldValue, newValue in
                print("🗺️ MapTabView: Freebies updated from \(oldValue.count) to \(newValue.count)")
                for (index, freebie) in newValue.enumerated() {
                    print("   \(index + 1). '\(freebie.title)' at \(freebie.location.latitude), \(freebie.location.longitude)")
                }
            }
            
            // Top overlay with gradient background
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                
                Spacer()
            }
            
            // Minimal Search and Filter UI
            VStack(spacing: 20) {
                // Clean header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free Near Me")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(filteredFreebies.count) freebies nearby")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // Minimal search bar
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
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                    
                    // Minimal filter button
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                Group {
                                    if selectedCategory != nil {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 12, y: -12)
                                    }
                                }
                            )
                    }
                }
                .padding(.horizontal, 24)
                
                // Simplified filter panel
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
                        }
                        
                        // Custom radius input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Radius")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("Enter miles", text: $customRadiusText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Button("Apply") {
                                    if let customRadius = Double(customRadiusText), customRadius >= 1 && customRadius <= 50 {
                                        searchRadius = customRadius
                                        customRadiusText = ""
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(customRadiusText.isEmpty)
                            }
                        }
                        
                        // Category filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // All categories chip
                            CategoryChip(
                                title: "All Categories",
                                emoji: "🌟",
                                isSelected: selectedCategory == nil,
                                color: .gray
                            ) {
                                selectedCategory = nil
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(Freebie.Category.allCases, id: \.self) { category in
                                    CategoryChip(
                                        title: category.rawValue.capitalized,
                                        emoji: category.emoji,
                                        isSelected: selectedCategory == category,
                                        color: Color(category.color)
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
            
            // Bottom sheet
            if showingBottomSheet, let freebie = selectedFreebie {
                BottomSheetView(freebie: freebie) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedFreebie = nil
                        showingBottomSheet = false
                    }
                }                 onDetailTap: {
                    selectedFreebie = freebie
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Clean floating action buttons
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Right side: Add freebie button (bottom right)
                    VStack(spacing: 16) {
                        // Refresh button
                        Button(action: refreshData) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Poop mode toggle button
                        Button(action: {
                            themeManager.togglePoopMode()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: themeManager.isPoopMode ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(themeManager.isPoopMode ? "Normal" : "Poop")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(themeManager.isPoopMode ? Color.brown : Color.orange)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add freebie button
                        Button(action: {
                            showingAddFreebie = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
            
            
            // Left side: Location button (bottom left)
            VStack {
                Spacer()
                
                HStack {
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 100)
            }
            
            // Loading indicator
            if firestoreService.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            Text("Loading freebies...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        .padding(.bottom, 200)
                        Spacer()
                    }
                }
            }
            
            // Empty state
            if !firestoreService.isLoading && filteredFreebies.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No freebies found")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Be the first to post a freebie!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {
                                showingAddFreebie = true
                            }) {
                                Text("Post Freebie")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .padding(.bottom, 200)
                        Spacer()
                    }
                }
            }
        }
        .sheet(item: $selectedFreebie) { freebie in
            DetailView(freebie: freebie)
                .onAppear {
                    print("📱 Opening detail view for freebie: \(freebie.title) (ID: \(freebie.id ?? "nil"))")
                }
        }
        .sheet(isPresented: $showingAddFreebie) {
            AddFreebieView()
        }
    }
    
    func observeCoordinateUpdates() {
        locationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("📍 Location coordinates publisher completed: \(completion)")
            } receiveValue: { coordinates in
                print("📍 Received new coordinates: \(coordinates.latitude), \(coordinates.longitude)")
                print("📍 Current map center: \(region.center.latitude), \(region.center.longitude)")
                print("📍 Centering map on user location...")
                
                centerMapOnLocation(coordinates)
                
                print("📍 Map centered at: \(coordinates.latitude), \(coordinates.longitude)")
            }
            .store(in: &tokens)
    }
    
    func centerMapOnLocation(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.5)) {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    func refreshData() {
        print("🔄 Refresh button tapped - refreshing database")
        firestoreService.fetchFreebies()
    }
    
    func centerOnUserLocation() {
        print("🎯 Center on user location button tapped")
        
        if let userLocation = locationService.currentLocation {
            print("📍 Centering on user location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            centerMapOnLocation(userLocation.coordinate)
        } else {
            print("📍 No user location available, requesting location...")
            locationService.requestLocationPermission()
            locationService.startLocationUpdates()
            
            // Try again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let userLocation = locationService.currentLocation {
                    print("📍 Found location after delay: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                    centerMapOnLocation(userLocation.coordinate)
                } else {
                    print("📍 Still no location available")
                }
            }
        }
    }
    
    func observeDeniedLocationAccess() {
        locationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Location access denied - user needs to enable in Settings")
            }
            .store(in: &tokens)
    }
}

struct CategoryChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? 
                LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomMapPin: View {
    let freebie: Freebie
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var isAnimating = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Pin shadow
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 30, height: 15)
                    .offset(y: 10)
                
                // Main pin
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color(freebie.category.color).opacity(0.3))
                        .frame(width: 70, height: 70)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.0 : 0.6)
                    
                    // Pin background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    // Category emoji or poop visualization
                    if themeManager.isPoopMode && freebie.category == .bathroom {
                        PoopVisualization(cleanlinessRating: freebie.cleanlinessRating ?? 5.0)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                    } else {
                        Text(freebie.category.emoji)
                            .font(.title2)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                    }
                    
                    // Upvote count badge
                    if freebie.upvotes > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(freebie.upvotes)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(10)
                                    .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                    }
                    
                    // Rating stars
                    if freebie.averageRating > 0 {
                        VStack {
                            Spacer()
                            HStack(spacing: 1) {
                                ForEach(0..<Int(freebie.averageRating), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                            }
                            .offset(y: 8)
                        }
                    }
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct BottomSheetView: View {
    let freebie: Freebie
    let onDismiss: () -> Void
    let onDetailTap: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 50, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                // Header with image and basic info
                HStack(alignment: .top, spacing: 16) {
                    // Image
                    AsyncImage(url: URL(string: freebie.photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .frame(width: 90, height: 90)
                    .cornerRadius(16)
                    .clipped()
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Title and category
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(freebie.category.emoji)
                                .font(.title)
                            
                            Text(freebie.category.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [Color(freebie.category.color), Color(freebie.category.color).opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Text(freebie.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        // Rating and upvotes
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(freebie.averageRating) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12))
                                }
                                Text("(\(freebie.reviewCount))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                Text("\(freebie.upvotes)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Description
                Text(freebie.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onDetailTap) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("View Details")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Upvote")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.1), Color.red.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color.white.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(25, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -10)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.height > 100 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDragging)
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


struct PoopVisualization: View {
    let cleanlinessRating: Double
    
    private var poopCount: Int {
        // More poop = dirtier bathroom (inverse of cleanliness)
        let dirtyLevel = 10 - cleanlinessRating
        return max(1, Int(dirtyLevel / 2)) // 1-5 poops
    }
    
    private var poopColor: Color {
        if cleanlinessRating <= 3 {
            return .brown
        } else if cleanlinessRating <= 6 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<poopCount, id: \.self) { index in
                Text("💩")
                    .font(.system(size: CGFloat(12 - (index * 2))))
                    .opacity(0.8 - (Double(index) * 0.1))
            }
        }
        .frame(width: 30, height: 30)
        .background(
            Circle()
                .fill(poopColor.opacity(0.3))
                .shadow(radius: 3)
        )
    }
}

struct UserLocationMarker: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0.0 : 0.6)
            
            // Inner pulsing ring
            Circle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 30, height: 30)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.0 : 0.8)
            
            // Center dot
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    MapTabView()
}

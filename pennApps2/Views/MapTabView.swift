import SwiftUI
import MapKit
import FirebaseFirestore
import Combine

struct MapTabView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var deviceService = DeviceService()
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var selectedFreebie: Freebie?
    @State private var showingBottomSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: Freebie.Category? = nil
    @State private var showingFilters = false
    @State private var showingPoopModePopup = false
    @State private var poopModeMessage = ""
    
    // Funny poop mode messages
    private let poopModeMessages = [
        "💩 Poop Mode Activated! 💩",
        "🚽 Time to find the throne! 👑",
        "🧻 Emergency bathroom locator ON! 🚨",
        "💩 Your poop radar is now active! 📡",
        "🚽 Bathroom hunter mode: ENGAGED! 🎯",
        "💩 The brown alert has been sounded! 🚨",
        "🚽 All systems go for bathroom finding! 🚀",
        "💩 Poop mode: Because nature calls! 📞",
        "🚽 Your personal bathroom GPS is online! 🛰️",
        "💩 The hunt for clean toilets begins! 🔍",
        "🚽 Bathroom mode: Maximum efficiency! ⚡",
        "💩 Poop detector: FULLY OPERATIONAL! 🤖"
    ]
    
    // Funny poop mode OFF messages
    private let poopModeOffMessages = [
        "👁️ Poop Mode Deactivated! 👁️",
        "🚽 Mission accomplished! 🎉",
        "🧻 Bathroom locator: STAND BY 🛑",
        "💩 Your poop radar is now offline! 📡",
        "🚽 Bathroom hunter mode: DISENGAGED! 🎯",
        "💩 The brown alert has been cleared! 🚨",
        "🚽 All systems returning to normal! 🚀",
        "💩 Poop mode: Mission complete! 📞",
        "🚽 Your personal bathroom GPS is offline! 🛰️",
        "💩 The hunt for clean toilets has ended! 🔍",
        "🚽 Bathroom mode: STANDING DOWN! ⚡",
        "💩 Poop detector: RETURNING TO BASE! 🤖"
    ]
    
    // Annotation data structure
    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let isUserLocation: Bool
        let freebie: Freebie?
    }
    
    // State variable for annotations to prevent flickering
    @State private var allAnnotations: [MapAnnotationItem] = []
    @State private var showingAddFreebie = false
    @State private var searchRadius: Double = 5.0 // in miles
    @State private var customRadiusText = ""
    @State private var isEditingRadius = false
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
    
    // Function to update annotations when data changes
    func updateAnnotations() {
        var annotations: [MapAnnotationItem] = []
        
        // Add user location annotation
        if let userLocation = locationService.currentLocation {
            annotations.append(MapAnnotationItem(
                coordinate: userLocation.coordinate,
                isUserLocation: true,
                freebie: nil
            ))
        }
        
        // Add freebie annotations
        for freebie in filteredFreebies {
            annotations.append(MapAnnotationItem(
                coordinate: CLLocationCoordinate2D(
                    latitude: freebie.location.latitude,
                    longitude: freebie.location.longitude
                ),
                isUserLocation: false,
                freebie: freebie
            ))
        }
        
        allAnnotations = annotations
    }
    
    var baseMap: some View {
        Map(coordinateRegion: $region, annotationItems: allAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                if annotation.isUserLocation {
                    UserLocationMarker()
                } else {
                    CustomMapPin(freebie: annotation.freebie!) {
                        print("📌 Pin tapped for freebie: \(annotation.freebie!.title) (ID: \(annotation.freebie!.id ?? "nil"))")
                        selectedFreebie = annotation.freebie!
                        print("📌 Set selectedFreebie to: \(annotation.freebie!.title) - sheet will show automatically")
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
        .mapControlVisibility(.hidden)
    }
    
    var mapView: some View {
        baseMap
            .onAppear {
                print("🗺️ MapTabView appeared - starting location setup")
                observeCoordinateUpdates()
                observeDeniedLocationAccess()
                locationService.requestLocationPermission()
                locationService.startLocationUpdates()
                firestoreService.fetchFreebies()
                updateAnnotations()
                
                if let userLocation = locationService.currentLocation {
                    print("📍 Found existing location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                    centerMapOnLocation(userLocation.coordinate)
                } else {
                    print("📍 No existing location available, waiting for location updates...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if let userLocation = locationService.currentLocation {
                            print("📍 Found delayed location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                            centerMapOnLocation(userLocation.coordinate)
                        }
                    }
                }
            }
            .onChange(of: firestoreService.freebies) { _, newValue in
                print("🗺️ MapTabView: Freebies updated to \(newValue.count)")
                for (index, freebie) in newValue.enumerated() {
                    print("   \(index + 1). '\(freebie.title)' at \(freebie.location.latitude), \(freebie.location.longitude)")
                }
                updateAnnotations()
            }
            .onChange(of: searchText) { _, _ in
                updateAnnotations()
            }
            .onChange(of: selectedCategory) { _, _ in
                updateAnnotations()
            }
            .onChange(of: searchRadius) { _, _ in
                updateAnnotations()
            }
            .onChange(of: themeManager.isPoopMode) { _, _ in
                updateAnnotations()
            }
    }
    
    var body: some View {
        ZStack {
            // Poop-themed background pattern
            if themeManager.isPoopMode {
                VStack {
                    ForEach(0..<12, id: \.self) { _ in
                        HStack {
                            ForEach(0..<8, id: \.self) { _ in
                                Text("💩")
                                    .font(.system(size: 8))
                                    .opacity(0.03)
                                    .rotationEffect(.degrees(Double.random(in: -15...15)))
                                    .offset(
                                        x: Double.random(in: -5...5),
                                        y: Double.random(in: -5...5)
                                    )
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.9),
                            Color(red: 0.95, green: 0.9, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )
            }
            
            // Map with real data from Firestore
            mapView
            
            // Minimal glassmorphism header
            VStack(spacing: 0) {
                // Subtle gradient overlay
                LinearGradient(
                    colors: [Color.black.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .ignoresSafeArea(edges: .top)
                
                Spacer()
            }
            
            // Minimal Search and Filter UI
            VStack(spacing: 16) {
                // Clean, minimal header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Near Me")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(filteredFreebies.count) nearby")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Modern search bar with glassmorphism
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search freebies...", text: $searchText)
                            .font(.system(size: 16, weight: .medium))
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = "" 
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Modern filter toggle
                    Button(action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingFilters.toggle() 
                        }
                    }) {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(showingFilters ? .blue : .primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                                
                                if isEditingRadius {
                                    HStack(spacing: 4) {
                                        TextField("", text: $customRadiusText)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 80)
                                        
                                        Text("mi")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Button("Done") {
                                            if let customRadius = Double(customRadiusText), customRadius >= 1 {
                                                searchRadius = customRadius
                                            }
                                            customRadiusText = ""
                                            isEditingRadius = false
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    Button(action: {
                                        if searchRadius.truncatingRemainder(dividingBy: 1) == 0 {
                                            customRadiusText = String(Int(searchRadius))
                                        } else {
                                            customRadiusText = String(searchRadius)
                                        }
                                        isEditingRadius = true
                                    }) {
                                        HStack(spacing: 2) {
                                            if searchRadius.truncatingRemainder(dividingBy: 1) == 0 {
                                                Text("\(Int(searchRadius))")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            } else {
                                                Text(String(format: "%.1f", searchRadius))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                            Text("miles")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            HStack {
                                Text("1 mi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: Binding(
                                    get: { min(searchRadius, 200) },
                                    set: { searchRadius = $0 }
                                ), in: 1...200, step: 1)
                                    .tint(.blue)
                                
                                Text("50+ mi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                            .fill(colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
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
            
            // Minimal floating action buttons
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Right side: Minimal floating buttons
                    VStack(spacing: 12) {
                        // Refresh button with glassmorphism
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                refreshData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Poop mode toggle with emoji
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                themeManager.togglePoopMode()
                                
                                // Show appropriate popup message
                                if themeManager.isPoopMode {
                                    showPoopModePopup()
                                } else {
                                    showPoopModeOffPopup()
                                }
                            }
                        }) {
                            Text(themeManager.isPoopMode ? "👁️" : "💩")
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Minimal add freebie button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingAddFreebie = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
            
            
            // Left side: Minimal location button
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            centerOnUserLocation()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .red.opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 40)
            }
            
            // Minimal loading indicator
            if firestoreService.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.0)
                                .tint(.blue)
                            Text("Loading...")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
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
        .overlay(
            // Poop mode popup
            Group {
                if showingPoopModePopup {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text(poopModeMessage)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.brown, Color.brown.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.3), lineWidth: 2)
                                )
                            
                            Spacer()
                        }
                        
                        Spacer()
                            .frame(height: 120)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
        )
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
                updateAnnotations()
                
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
    
    func showPoopModePopup() {
        // Select a random funny message
        poopModeMessage = poopModeMessages.randomElement() ?? poopModeMessages[0]
        
        // Show the popup with animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingPoopModePopup = true
        }
        
        // Hide the popup after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingPoopModePopup = false
            }
        }
    }
    
    func showPoopModeOffPopup() {
        // Select a random funny message for turning off
        poopModeMessage = poopModeOffMessages.randomElement() ?? poopModeOffMessages[0]
        
        // Show the popup with animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingPoopModePopup = true
        }
        
        // Hide the popup after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingPoopModePopup = false
            }
        }
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    } else {
                        if colorScheme == .dark {
                            LinearGradient(colors: [Color(.secondarySystemBackground)], startPoint: .leading, endPoint: .trailing)
                        } else {
                            LinearGradient(colors: [Color(.systemBackground)], startPoint: .leading, endPoint: .trailing)
                        }
                    }
                }
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
                    .frame(width: 20, height: 10)
                    .offset(y: 8)
                
                // Main pin
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color(freebie.category.color).opacity(0.3))
                        .frame(width: 45, height: 45)
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
                        .frame(width: 38, height: 38)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Category emoji or poop visualization
                    if themeManager.isPoopMode && freebie.category == .bathroom {
                        PoopVisualization(cleanlinessRating: freebie.cleanlinessRating ?? 5.0)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                    } else {
                        Text(freebie.category.emoji)
                            .font(.title3)
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
                                    .cornerRadius(8)
                                    .offset(x: 6, y: -6)
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
                            .offset(y: 6)
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
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    private var poopCount: Int {
        // More poop = dirtier bathroom (inverse of cleanliness)
        let dirtyLevel = 10 - cleanlinessRating
        return max(1, Int(dirtyLevel / 2)) // 1-5 poops
    }
    
    private var poopColor: Color {
        if cleanlinessRating <= 3 {
            return Color(red: 0.6, green: 0.3, blue: 0.1) // Dark brown for dirty
        } else if cleanlinessRating <= 6 {
            return Color(red: 0.8, green: 0.5, blue: 0.2) // Medium brown for average
        } else {
            return Color(red: 0.2, green: 0.7, blue: 0.3) // Green for clean
        }
    }
    
    private var glowColor: Color {
        if cleanlinessRating <= 3 {
            return Color(red: 0.8, green: 0.4, blue: 0.2) // Brown glow for dirty
        } else if cleanlinessRating <= 6 {
            return Color(red: 0.9, green: 0.6, blue: 0.3) // Orange glow for average
        } else {
            return Color(red: 0.3, green: 0.9, blue: 0.4) // Green glow for clean
        }
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(glowColor.opacity(0.4))
                .frame(width: 40, height: 40)
                .blur(radius: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            poopColor.opacity(0.8),
                            poopColor.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(poopColor.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: poopColor.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // Poop emojis
            VStack(spacing: 1) {
                ForEach(0..<poopCount, id: \.self) { index in
                    Text("💩")
                        .font(.system(size: CGFloat(10.0 - (Double(index) * 1.5))))
                        .opacity(0.9 - (Double(index) * 0.15))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .rotationEffect(.degrees(rotationAngle + Double(index * 10)))
                        .animation(
                            .easeInOut(duration: 1.5)
                            .delay(Double(index) * 0.2)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
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

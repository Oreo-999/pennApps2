import SwiftUI
import PhotosUI
import MapKit
import FirebaseFirestore

struct AddFreebieView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var deviceService = DeviceService()
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = Freebie.Category.food
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var selectedLocation: CLLocation?
    @State private var isUploading = false
    @State private var errorMessage = ""
    @State private var showingLocationAlert = false
    @State private var cleanlinessRating: Double = 5.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    photoSection
                    titleSection
                    descriptionSection
                    categorySection
                    cleanlinessRatingSection
                    locationSection
                    submitButton
                    
                    if !errorMessage.isEmpty {
                        errorSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("New Freebie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingLocationPicker) {
            MapLocationPickerView(
                selectedLocation: $selectedLocation,
                mapRegion: .constant(MKCoordinateRegion(
                    center: locationService.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            )
        }
        .alert("Location Required", isPresented: $showingLocationAlert) {
            Button("OK") { }
        } message: {
            Text("Please allow location access or select a custom location to post a freebie.")
        }
        .onAppear {
            locationService.requestLocationPermission()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Share Something Free")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Help others discover free items near you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                
                                Text("Add Photo")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Title")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("What are you giving away?", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Tell us more about this item...", text: $description, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .font(.body)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Freebie.Category.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 8) {
                            Text(category.emoji)
                                .font(.title2)
                            
                            Text(category.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if selectedCategory == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategory == category ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var cleanlinessRatingSection: some View {
        Group {
            if selectedCategory == .bathroom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cleanliness Rating")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("💩")
                                .font(.title2)
                            Text("Very Dirty")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(cleanlinessRating))/10")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(cleanlinessColor)
                            
                            Spacer()
                            
                            Text("Very Clean")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("✨")
                                .font(.title2)
                        }
                        
                        Slider(value: $cleanlinessRating, in: 1...10, step: 1)
                            .accentColor(cleanlinessColor)
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
    }
    
    private var cleanlinessColor: Color {
        if cleanlinessRating <= 3 {
            return .brown
        } else if cleanlinessRating <= 6 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showingLocationPicker = true
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let selectedLocation = selectedLocation {
                            Text("Custom Location Selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(selectedLocation.coordinate.latitude, specifier: "%.4f"), \(selectedLocation.coordinate.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let currentLocation = locationService.currentLocation {
                            Text("Current Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(currentLocation.coordinate.latitude, specifier: "%.4f"), \(currentLocation.coordinate.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Tap to choose a location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var submitButton: some View {
        Button(action: submitFreebie) {
            HStack {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isUploading ? "Posting..." : "Post Freebie")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUploading ? Color.gray : Color.blue)
            )
        }
        .disabled(isUploading || title.isEmpty || description.isEmpty || selectedImage == nil)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var errorSection: some View {
        Text(errorMessage)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
    }
    
    private func submitFreebie() {
        print("🎯 Starting freebie submission process...")
        
        guard let image = selectedImage,
              let location = selectedLocation ?? locationService.currentLocation else {
            print("❌ Missing required data for submission:")
            print("   - Image: \(selectedImage != nil ? "✅" : "❌")")
            print("   - Location: \((selectedLocation != nil || locationService.currentLocation != nil) ? "✅" : "❌")")
            
            if selectedLocation == nil && locationService.currentLocation == nil {
                showingLocationAlert = true
            } else {
                errorMessage = "Please select an image"
            }
            return
        }
        
        print("✅ All required data available:")
        print("   - Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("   - Title: '\(title)'")
        print("   - Description: '\(description)'")
        print("   - Category: \(selectedCategory)")
        
        isUploading = true
        errorMessage = ""
        
        // Convert image to data with very aggressive compression for Firestore
        guard let imageData = image.jpegData(compressionQuality: 0.1) else {
            print("❌ Failed to convert image to data")
            errorMessage = "Failed to process image"
            isUploading = false
            return
        }
        
        print("✅ Image converted to data successfully. Size: \(imageData.count) bytes")
        
        // Upload image to Firebase Storage
        print("📤 Starting image upload...")
        firestoreService.uploadImage(imageData) { url in
            DispatchQueue.main.async {
                guard let url = url else {
                    print("❌ Image upload failed")
                    print("   - Error message: \(firestoreService.errorMessage ?? "Unknown error")")
                    errorMessage = firestoreService.errorMessage ?? "Failed to upload image"
                    isUploading = false
                    return
                }
                
                print("✅ Image uploaded successfully!")
                print("📷 Image URL: \(url)")
                print("🏗️ Creating freebie object...")
                
                // Create freebie
                let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let freebie = Freebie(
                    title: title,
                    description: description,
                    category: selectedCategory,
                    location: geoPoint,
                    photoURL: url,
                    postedBy: deviceService.deviceId,
                    cleanlinessRating: selectedCategory == .bathroom ? cleanlinessRating : nil
                )
                
                print("💾 Adding freebie to database...")
                
                // Add to Firestore
                firestoreService.addFreebie(freebie) { success, errorMessage in
                    DispatchQueue.main.async {
                        if success {
                            print("🎉 Freebie submission completed successfully!")
                            // Reset uploading state
                            isUploading = false
                            
                            // Dismiss view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        } else {
                            print("❌ Freebie submission failed: \(errorMessage ?? "Unknown error")")
                            self.errorMessage = errorMessage ?? "Failed to save freebie"
                            isUploading = false
                        }
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

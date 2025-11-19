import SwiftUI
import FirebaseFirestore
import MapKit

struct DetailView: View {
    let freebie: Freebie
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var deviceService = DeviceService()
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var reviews: [Review] = []
    @State private var hasUpvoted = false
    @State private var upvoteChecked = false
    @State private var showingReviewSheet = false
    @State private var showingReportSheet = false
    @State private var newRating: Double = 5.0
    @State private var newReviewText = ""
    @State private var isSubmittingReview = false
    @State private var isUpvoting = false
    @State private var hasUserReviewed = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Minimal image header
                    if freebie.photoURL.hasPrefix("data:image") {
                        // Base64 image
                        if let data = Data(base64Encoded: freebie.photoURL.components(separatedBy: ",").last ?? ""),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
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
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Clean title and category
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(freebie.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
                                    Text(freebie.category.emoji)
                                        .font(.title3)
                                    
                                    Text(freebie.category.rawValue.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(freebie.category.color).opacity(0.2))
                                        )
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Minimal rating and interaction section
                        HStack(spacing: 20) {
                            // Rating section
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(freebie.averageRating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 14))
                                    }
                                    Text("(\(freebie.reviewCount))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: { showingReviewSheet = true }) {
                                    Text("Write Review")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            // Upvote section
                            VStack(alignment: .trailing, spacing: 6) {
                                Button(action: upvoteFreebie) {
                                    HStack(spacing: 6) {
                                        Image(systemName: hasUpvoted ? "heart.fill" : "heart")
                                            .foregroundColor(hasUpvoted ? .red : .secondary)
                                            .font(.system(size: 16))
                                        Text("\(freebie.upvotes)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(hasUpvoted ? .red : .primary)
                                    }
                                }
                                .disabled(isUpvoting || hasUpvoted || !upvoteChecked)
                                
                                if isUpvoting {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else if !upvoteChecked {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .foregroundColor(.secondary)
                                } else if hasUpvoted {
                                    Text("You upvoted this!")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Description
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(freebie.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Reviews section or Poop Score for bathrooms
                        if freebie.category == .bathroom {
                            // Poop Score section for bathrooms
                            VStack(alignment: .leading, spacing: 20) {
                                // Header with dramatic styling
                                HStack {
                                    Text("💩")
                                        .font(.title)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("POOP SCORE")
                                            .font(.headline)
                                            .fontWeight(.black)
                                            .foregroundColor(themeManager.getBrownText(for: freebie.cleanlinessRating))
                                            .tracking(2)
                                        
                                        Text("Bathroom Cleanliness Rating")
                                            .font(.caption)
                                            .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                }
                                
                                if let cleanlinessRating = freebie.cleanlinessRating {
                                    // Main score card with dramatic styling
                                    VStack(spacing: 20) {
                                        // Large poop visualization with glow
                                        ZStack {
                                            // Outer glow
                                            Circle()
                                                .fill(themeManager.getBrownBackground(for: freebie.cleanlinessRating))
                                                .frame(width: 140, height: 140)
                                                .blur(radius: 20)
                                            
                                            // Main visualization
                                            PoopVisualization(cleanlinessRating: cleanlinessRating)
                                                .scaleEffect(3.0)
                                                .frame(width: 100, height: 100)
                                                .background(
                                                    Circle()
                                                        .fill(Color.white)
                                                        .shadow(color: themeManager.primaryColor.opacity(0.5), radius: 15, x: 0, y: 8)
                                                )
                                        }
                                        
                                        // Score display with dramatic styling
                                        VStack(spacing: 12) {
                                            Text("CLEANLINESS RATING")
                                                .font(.caption)
                                                .fontWeight(.heavy)
                                                .foregroundColor(themeManager.secondaryTextColor)
                                                .tracking(2)
                                            
                                            HStack(spacing: 8) {
                                                Text("\(Int(cleanlinessRating))")
                                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                                    .foregroundColor(themeManager.primaryColor)
                                                
                                                Text("/10")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeManager.secondaryTextColor)
                                            }
                                            
                                            // Progress bar
                                            VStack(spacing: 8) {
                                                HStack {
                                                    Text("💩 DIRTY")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(themeManager.primaryColor)
                                                    
                                                    Spacer()
                                                    
                                                    Text("✨ CLEAN")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(themeManager.primaryColor)
                                                }
                                                
                                                GeometryReader { geometry in
                                                    ZStack(alignment: .leading) {
                                                        // Background track
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(themeManager.getBrownBackground(for: freebie.cleanlinessRating))
                                                            .frame(height: 16)
                                                        
                                                        // Progress fill with gradient
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color(red: 0.6, green: 0.3, blue: 0.1),
                                                                        Color(red: 0.8, green: 0.5, blue: 0.2),
                                                                        Color(red: 0.9, green: 0.7, blue: 0.4)
                                                                    ]),
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                            .frame(width: geometry.size.width * (cleanlinessRating / 10), height: 16)
                                                    }
                                                }
                                                .frame(height: 16)
                                            }
                                        }
                                        
                                        // Description with fun styling
                                        Text(getCleanlinessDescription(for: cleanlinessRating))
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.textColor)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 8)
                                    }
                                    .padding(24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(themeManager.cardGradient)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 2)
                                            )
                                            .shadow(color: themeManager.primaryColor.opacity(0.2), radius: 15, x: 0, y: 8)
                                    )
                                } else {
                                    // No rating available
                                    VStack(spacing: 16) {
                                        Text("❓")
                                            .font(.system(size: 60))
                                        
                                        Text("No Cleanliness Rating")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.primaryColor)
                                        
                                        Text("This bathroom hasn't been rated yet. Be the first to rate it!")
                                            .font(.body)
                                            .foregroundColor(themeManager.secondaryTextColor)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(themeManager.cardBackgroundColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 2)
                                            )
                                    )
                                }
                            }
                        } else {
                            // Normal reviews section for non-bathroom items
                            HStack {
                                Text("Reviews")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if !hasUserReviewed {
                                    Button("Add Review") {
                                        showingReviewSheet = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                } else {
                                    Text("Reviewed")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if reviews.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No reviews yet. Be the first to review!")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .italic()
                                    
                                    Text("Reviews array count: \(reviews.count)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Text("Reviews found: \(reviews.count)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                    ForEach(reviews) { review in
                                        ReviewCard(review: review)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(themeManager.getBrownBackground(for: freebie.cleanlinessRating))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Report") {
                        showingReportSheet = true
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: openInMaps) {
                        VStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Navigate")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("📱 DetailView appeared for freebie: \(freebie.title) (ID: \(freebie.id ?? "nil"))")
            loadReviews()
            checkUpvoteStatus()
        }
        .onChange(of: reviews) { _ in
            checkReviewStatus()
        }
        .sheet(isPresented: $showingReviewSheet) {
            ReviewSheetView(rating: $newRating, reviewText: $newReviewText, isSubmitting: $isSubmittingReview, onSubmit: submitReview)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportSheet(freebieId: freebie.id ?? "") {
                // Report submitted
            }
        }
    }
    
    private func getCleanlinessDescription(for rating: Double) -> String {
        switch rating {
        case 1...2:
            return "💩💩💩 Very dirty! Proceed with caution!"
        case 3...4:
            return "💩💩 Pretty dirty, might want to find another option"
        case 5...6:
            return "💩 Average cleanliness, usable but not great"
        case 7...8:
            return "✨ Pretty clean, should be fine to use"
        case 9...10:
            return "✨✨✨ Very clean! Highly recommended!"
        default:
            return "No rating available"
        }
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 300)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Image")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: freebie.location.latitude,
            longitude: freebie.location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = freebie.title
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func loadReviews() {
        guard let freebieId = freebie.id else { 
            print("❌ No freebie ID available for loading reviews - freebie: \(freebie.title)")
            print("❌ Freebie object: \(freebie)")
            return 
        }
        
        print("📖 Loading reviews for freebie: \(freebieId)")
        print("📖 Freebie details: title='\(freebie.title)', description='\(freebie.description)'")
        
        firestoreService.db.collection("reviews")
            .whereField("freebieId", isEqualTo: freebieId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error loading reviews for freebie \(freebieId): \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("❌ No snapshot returned from reviews query")
                    return
                }
                
                print("📖 Found \(snapshot.documents.count) review documents")
                print("📖 Snapshot metadata: \(snapshot.metadata)")
                
                // Debug: Print all document IDs first
                for doc in snapshot.documents {
                    print("📖 Document ID: \(doc.documentID), data: \(doc.data())")
                }
                
                let fetchedReviews = snapshot.documents.compactMap { doc -> Review? in
                    do {
                        let review = try doc.data(as: Review.self)
                        print("📖 Successfully loaded review: \(doc.documentID) - \(review.rating) stars - '\(review.reviewText)'")
                        var mutableReview = review
                        mutableReview.id = doc.documentID
                        return mutableReview
                    } catch {
                        print("❌ Error decoding review \(doc.documentID): \(error)")
                        print("❌ Raw document data: \(doc.data())")
                        return nil
                    }
                }
                .sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() } // Sort by newest first
                
                DispatchQueue.main.async {
                    self.reviews = fetchedReviews
                    print("📖 Updated reviews array with \(fetchedReviews.count) reviews")
                    print("📖 Current reviews state: \(self.reviews)")
                    
                    // Debug: Print each review
                    for (index, review) in fetchedReviews.enumerated() {
                        print("📖 Review \(index + 1): rating=\(review.rating), text='\(review.reviewText)', id=\(review.id ?? "nil")")
                    }
                }
            }
    }
    
    private func checkUpvoteStatus() {
        guard let freebieId = freebie.id else { return }
        
        print("🔍 Checking upvote status for freebie: \(freebieId)")
        
        // First check local storage as a quick check
        let upvoteKey = "upvoted_\(freebieId)_\(deviceService.deviceId)"
        let localUpvoted = UserDefaults.standard.bool(forKey: upvoteKey)
        
        if localUpvoted {
            print("🔍 Local storage shows already upvoted")
            hasUpvoted = true
            upvoteChecked = true
            return
        }
        
        // Then verify with database
        firestoreService.db.collection("upvotes")
            .whereField("freebieId", isEqualTo: freebieId)
            .whereField("deviceId", isEqualTo: deviceService.deviceId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error checking upvote status: \(error)")
                        self.upvoteChecked = true
                        return
                    }
                    
                    let dbUpvoted = !(snapshot?.documents.isEmpty ?? true)
                    self.hasUpvoted = dbUpvoted
                    self.upvoteChecked = true
                    
                    // Update local storage to match database
                    UserDefaults.standard.set(dbUpvoted, forKey: upvoteKey)
                    
                    print("🔍 Upvote status: \(self.hasUpvoted ? "Already upvoted" : "Not upvoted")")
                }
            }
    }
    
    private func checkReviewStatus() {
        hasUserReviewed = reviews.contains { review in
            review.reviewerId == deviceService.deviceId
        }
    }
    
    private func submitReview() {
        guard let freebieId = freebie.id else {
            print("❌ No freebie ID available for review")
            return
        }
        
        print("📝 Starting review submission for freebie: \(freebieId)")
        print("📝 Rating: \(newRating), Text: '\(newReviewText)'")
        
        isSubmittingReview = true
        
        let review = Review(
            freebieId: freebieId,
            rating: newRating,
            reviewText: newReviewText,
            reviewerId: deviceService.deviceId
        )
        
        print("📝 Review object created:")
        print("   - freebieId: \(freebieId)")
        print("   - rating: \(newRating)")
        print("   - reviewText: '\(newReviewText)'")
        print("   - reviewerId: \(deviceService.deviceId)")
        
        firestoreService.addReview(review) { success, error in
            DispatchQueue.main.async {
                self.isSubmittingReview = false
                
                if success {
                    print("✅ Review submitted successfully for freebie \(freebieId)")
                    self.newRating = 5.0
                    self.newReviewText = ""
                    
                    // Increment user's total reviews counter
                    let totalReviewsKey = "totalReviews_\(self.deviceService.deviceId)"
                    let currentTotal = UserDefaults.standard.integer(forKey: totalReviewsKey)
                    UserDefaults.standard.set(currentTotal + 1, forKey: totalReviewsKey)
                    
                    self.loadReviews() // Reload reviews to show the new one
                    self.showingReviewSheet = false
                } else {
                    print("❌ Error submitting review for freebie \(freebieId): \(error ?? "Unknown error")")
                }
            }
        }
    }
    
    private func upvoteFreebie() {
        guard !hasUpvoted else { 
            print("⚠️ Already upvoted this freebie")
            return 
        }
        
        guard let freebieId = freebie.id else {
            print("❌ No freebie ID available for upvoting")
            return
        }
        
        print("👍 Starting upvote for freebie: \(freebieId)")
        isUpvoting = true
        
        // Update upvote count in Firestore
        firestoreService.db.collection("freebies").document(freebieId)
            .updateData([
                "upvotes": FieldValue.increment(Int64(1))
            ]) { error in
                DispatchQueue.main.async {
                    self.isUpvoting = false
                    
                    if let error = error {
                        print("❌ Error upvoting freebie \(freebieId): \(error)")
                        print("❌ Error details: \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully upvoted freebie \(freebieId)")
                        self.hasUpvoted = true
                        
                        // Update local storage
                        let upvoteKey = "upvoted_\(freebieId)_\(self.deviceService.deviceId)"
                        UserDefaults.standard.set(true, forKey: upvoteKey)
                        
                        // Increment user's total upvotes counter
                        let totalUpvotesKey = "totalUpvotes_\(self.deviceService.deviceId)"
                        let currentTotal = UserDefaults.standard.integer(forKey: totalUpvotesKey)
                        UserDefaults.standard.set(currentTotal + 1, forKey: totalUpvotesKey)
                        
                        // Also track this upvote in a separate collection to prevent duplicates
                        self.trackUpvote(freebieId: freebieId)
                        
                        // Refresh the freebie data
                        self.firestoreService.fetchFreebies()
                    }
                }
            }
    }
    
    private func trackUpvote(freebieId: String) {
        let upvoteRecord = [
            "freebieId": freebieId,
            "deviceId": deviceService.deviceId,
            "timestamp": Timestamp()
        ] as [String : Any]
        
        firestoreService.db.collection("upvotes").addDocument(data: upvoteRecord) { error in
            if let error = error {
                print("❌ Error tracking upvote: \(error)")
            } else {
                print("✅ Upvote tracked successfully")
            }
        }
    }
    
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(review.createdAt.dateValue(), style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !review.reviewText.isEmpty {
                Text(review.reviewText)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ReviewSheet: View {
    let freebieId: String
    @Binding var rating: Double
    @Binding var reviewText: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Write a Review")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rating")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Button(action: {
                                rating = Double(index)
                            }) {
                                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text("\(Int(rating)) stars")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review (Optional)")
                        .font(.headline)
                    
                    TextField("Share your experience...", text: $reviewText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        onSubmit()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
}

struct ReportSheet: View {
    let freebieId: String
    let onReport: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var deviceService = DeviceService()
    @State private var selectedReason: ReportReason = .fake
    @State private var description = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Report Item")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reason")
                        .font(.headline)
                    
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedReason == reason ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Details (Optional)")
                        .font(.headline)
                    
                    TextField("Provide more information...", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let report = Report(
            freebieId: freebieId,
            reason: selectedReason,
            reporterId: deviceService.deviceId,
            description: description.isEmpty ? nil : description
        )
        
        firestoreService.addReport(report) { success, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if success {
                    print("✅ Report submitted successfully")
                    onReport()
                    dismiss()
                } else {
                    print("❌ Error submitting report: \(error ?? "Unknown error")")
                }
            }
        }
    }
}

struct ReviewSheetView: View {
    @Binding var rating: Double
    @Binding var reviewText: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Rating section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rating")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    HStack {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $rating, in: 1...5, step: 1)
                            .accentColor(themeManager.primaryColor)
                        
                        Text("5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.title2)
                        }
                        Spacer()
                        Text("\(Int(rating)) stars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Review text section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    TextField("Write your review here...", text: $reviewText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5...10)
                }
                
                Spacer()
                
                // Submit button
                Button(action: {
                    onSubmit()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "star.fill")
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Review")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSubmitting || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(isSubmitting || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding()
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DetailView(freebie: Freebie(
        title: "Free Pizza Slice",
        description: "Leftover pizza from our party, still warm!",
        category: .food,
        location: GeoPoint(latitude: 39.9526, longitude: -75.1652),
        photoURL: "https://example.com/pizza.jpg",
        postedBy: "device123"
    ))
}

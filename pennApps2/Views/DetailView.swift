import SwiftUI
import FirebaseFirestore

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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Parallax image header
                    if freebie.photoURL.hasPrefix("data:image") {
                        // Base64 image
                        if let data = Data(base64Encoded: freebie.photoURL.components(separatedBy: ",").last ?? ""),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
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
                        .frame(height: 300)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and category
                        HStack {
                            Text(freebie.category.emoji)
                                .font(.title)
                            
                            Text(freebie.category.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(freebie.category.color))
                                .cornerRadius(12)
                            
                            Spacer()
                        }
                        
                        Text(freebie.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Rating and upvotes with interactive buttons
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(freebie.averageRating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }
                                    Text("(\(freebie.reviewCount) reviews)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Button("Write Review") {
                                    showingReviewSheet = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: upvoteFreebie) {
                                    HStack(spacing: 4) {
                                        Image(systemName: hasUpvoted ? "heart.fill" : "heart")
                                            .foregroundColor(hasUpvoted ? .red : .gray)
                                        Text("\(freebie.upvotes) upvotes")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(hasUpvoted ? .red : .primary)
                                    }
                                }
                                .disabled(isUpvoting || hasUpvoted || !upvoteChecked)
                                
                                if isUpvoting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if !upvoteChecked {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .foregroundColor(.gray)
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
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Poop Score")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.getBrownText(for: freebie.cleanlinessRating))
                                    
                                    Spacer()
                                }
                                
                                if let cleanlinessRating = freebie.cleanlinessRating {
                                    VStack(spacing: 12) {
                                        // Poop visualization
                                        PoopVisualization(cleanlinessRating: cleanlinessRating)
                                            .scaleEffect(2.0)
                                        
                                        // Score display
                                        HStack {
                                            Text("Cleanliness Rating:")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.getBrownText(for: freebie.cleanlinessRating))
                                            
                                            Spacer()
                                            
                                            Text("\(Int(cleanlinessRating))/10")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.getBrownText(for: freebie.cleanlinessRating))
                                        }
                                        
                                        // Description
                                        Text(getCleanlinessDescription(for: cleanlinessRating))
                                            .font(.body)
                                            .foregroundColor(themeManager.getBrownText(for: freebie.cleanlinessRating))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.getBrownBackground(for: freebie.cleanlinessRating))
                                    )
                                } else {
                                    Text("No cleanliness rating available")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .italic()
                                }
                            }
                        } else {
                            // Normal reviews section for non-bathroom items
                            HStack {
                                Text("Reviews")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("Add Review") {
                                    showingReviewSheet = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Report") {
                        showingReportSheet = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            print("📱 DetailView appeared for freebie: \(freebie.title) (ID: \(freebie.id ?? "nil"))")
            loadReviews()
            checkUpvoteStatus()
        }
        .sheet(isPresented: $showingReviewSheet) {
            ReviewSheet(freebieId: freebie.id ?? "", rating: $newRating, reviewText: $newReviewText, isSubmitting: $isSubmittingReview) {
                submitReview()
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportSheet(freebieId: freebie.id ?? "") {
                // Report submitted
            }
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
                        var review = try doc.data(as: Review.self)
                        review.id = doc.documentID
                        print("📖 Successfully loaded review: \(doc.documentID) - \(review.rating) stars - '\(review.reviewText)'")
                        return review
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
        
        print("📝 Created review object, calling FirestoreService...")
        
        firestoreService.addReview(review) { success, error in
            DispatchQueue.main.async {
                self.isSubmittingReview = false
                
                if success {
                    print("✅ Review submitted successfully for freebie \(freebieId)")
                    self.showingReviewSheet = false
                    self.newRating = 5.0
                    self.newReviewText = ""
                    self.loadReviews() // Reload reviews
                } else {
                    print("❌ Error submitting review for freebie \(freebieId): \(error ?? "Unknown error")")
                }
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

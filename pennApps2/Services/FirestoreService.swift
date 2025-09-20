import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import Combine

class FirestoreService: ObservableObject {
    let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var freebies: [Freebie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let freebiesCollection = "freebies"
    
    init() {
        print("🔥 FirestoreService initialized")
        print("🔥 Database: \(db.app.name)")
        
        // Initialize Storage
        let storage = Storage.storage()
        print("🔥 Storage initialized: \(storage.app.name)")
        
        // Test database connection
        testDatabaseConnection()
    }
    
    func testDatabaseConnection() {
        print("🧪 Testing Firestore connection...")
        db.collection("test").document("connection").setData(["test": true]) { error in
            if let error = error {
                print("❌ Firestore connection failed: \(error)")
            } else {
                print("✅ Firestore connection successful")
            }
        }
    }
    
    func fetchFreebies() {
        print("📥 Fetching freebies from Firestore...")
        isLoading = true
        errorMessage = nil
        
        db.collection(freebiesCollection)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Error fetching freebies: \(error)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("📄 No documents found")
                        self?.freebies = []
                        return
                    }
                    
                    print("📄 Found \(documents.count) freebie documents")
                    
                    let fetchedFreebies = documents.compactMap { doc -> Freebie? in
                        do {
                            var freebie = try doc.data(as: Freebie.self)
                            freebie.id = doc.documentID
                            
                            // Check if expired
                            if freebie.expiresAt.dateValue() < Date() {
                                print("⏰ Freebie '\(freebie.title)' has expired")
                                return nil
                            }
                            
                            print("✅ Loaded freebie: '\(freebie.title)' (ID: \(doc.documentID)) at \(freebie.location.latitude), \(freebie.location.longitude)")
                            return freebie
                        } catch {
                            print("❌ Error decoding freebie \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("🎯 Successfully loaded \(fetchedFreebies.count) active freebies")
                    self?.freebies = fetchedFreebies
                }
            }
    }
    
    func addFreebie(_ freebie: Freebie, completion: @escaping (Bool, String?) -> Void) {
        print("💾 Adding freebie to database: '\(freebie.title)'")
        
        do {
            try db.collection(freebiesCollection).addDocument(from: freebie) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error adding freebie: \(error)")
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    print("✅ Freebie added successfully")
                    self?.fetchFreebies() // Refresh the list
                    completion(true, nil)
                }
            }
        } catch {
            print("❌ Error encoding freebie: \(error)")
            completion(false, error.localizedDescription)
        }
    }
    
    func uploadImage(_ imageData: Data, completion: @escaping (String?) -> Void) {
        print("🖼️ Processing image for Firestore storage...")
        print("Original image size: \(imageData.count) bytes")
        
        // Check if image is too large for Firestore (1MB limit)
        let maxSize = 700_000 // 700KB to be extra safe
        if imageData.count > maxSize {
            print("⚠️ Image too large for Firestore, compressing...")
            
            // Compress the image more aggressively
            guard let uiImage = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data")
                completion(nil)
                return
            }
            
            // First try compression
            let compressionLevels: [CGFloat] = [0.1, 0.05, 0.02, 0.01, 0.005]
            
            for compression in compressionLevels {
                if let compressedData = uiImage.jpegData(compressionQuality: compression) {
                    print("🔄 Trying compression level \(compression): \(compressedData.count) bytes")
                    
                    if compressedData.count <= maxSize {
                        print("✅ Image compressed successfully to \(compressedData.count) bytes")
                        let base64String = compressedData.base64EncodedString()
                        let dataURL = "data:image/jpeg;base64,\(base64String)"
                        print("📏 Final base64 length: \(base64String.count) characters")
                        
                        DispatchQueue.main.async {
                            completion(dataURL)
                        }
                        return
                    }
                }
            }
            
            // If compression didn't work, try resizing the image
            print("🔄 Compression failed, trying image resizing...")
            let targetSize = CGSize(width: 800, height: 600) // Smaller dimensions
            UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
            uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let resizedImage = resizedImage {
                // Try compression on the resized image
                for compression in compressionLevels {
                    if let finalData = resizedImage.jpegData(compressionQuality: compression) {
                        print("🔄 Trying resized image with compression \(compression): \(finalData.count) bytes")
                        
                        if finalData.count <= maxSize {
                            print("✅ Resized image compressed successfully to \(finalData.count) bytes")
                            let base64String = finalData.base64EncodedString()
                            let dataURL = "data:image/jpeg;base64,\(base64String)"
                            print("📏 Final base64 length: \(base64String.count) characters")
                            
                            DispatchQueue.main.async {
                                completion(dataURL)
                            }
                            return
                        }
                    }
                }
            }
            
            print("❌ Could not compress image small enough for Firestore")
            completion(nil)
            return
        }
        
        // Image is small enough, use as-is
        print("✅ Image size acceptable for Firestore")
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        print("📏 Base64 length: \(base64String.count) characters")
        
        DispatchQueue.main.async {
            completion(dataURL)
        }
    }
    
    func addReview(_ review: Review, completion: @escaping (Bool, String?) -> Void) {
        print("📝 Adding review for freebie: \(review.freebieId)")
        print("📝 Review details: rating=\(review.rating), text='\(review.reviewText)', reviewer=\(review.reviewerId)")
        
        do {
            try db.collection("reviews").addDocument(from: review) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error adding review: \(error)")
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    print("✅ Review added successfully")
                    self?.updateFreebieRating(freebieId: review.freebieId)
                    completion(true, nil)
                }
            }
        } catch {
            print("❌ Error encoding review: \(error)")
            completion(false, error.localizedDescription)
        }
    }
    
    
    private func updateFreebieRating(freebieId: String) {
        db.collection("reviews")
            .whereField("freebieId", isEqualTo: freebieId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                let ratings = documents.compactMap { doc -> Double? in
                    return doc.data()["rating"] as? Double
                }
                
                let averageRating = ratings.reduce(0, +) / Double(ratings.count)
                
                self?.db.collection(self?.freebiesCollection ?? "freebies")
                    .document(freebieId)
                    .updateData([
                        "averageRating": averageRating,
                        "reviewCount": ratings.count
                    ]) { error in
                        if let error = error {
                            print("❌ Error updating freebie rating: \(error)")
                        } else {
                            print("✅ Updated freebie rating: \(averageRating) (\(ratings.count) reviews)")
                            self?.fetchFreebies()
                        }
                    }
            }
    }
    
    func addReport(_ report: Report, completion: @escaping (Bool, String?) -> Void) {
        print("🚨 Adding report for freebie: \(report.freebieId)")
        
        do {
            try db.collection("reports").addDocument(from: report) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error adding report: \(error)")
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    print("✅ Report added successfully")
                    completion(true, nil)
                }
            }
        } catch {
            print("❌ Error encoding report: \(error)")
            completion(false, error.localizedDescription)
        }
    }
    
    func checkDatabaseContents() {
        print("🔍 Checking database contents...")
        
        db.collection(freebiesCollection).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error checking database: \(error)")
                return
            }
            
            print("📊 Database contains \(snapshot?.documents.count ?? 0) total documents")
            
            for doc in snapshot?.documents ?? [] {
                print("📄 Document: \(doc.documentID)")
                print("   Data: \(doc.data())")
            }
        }
    }
}

import Foundation
import FirebaseFirestore
import MapKit

struct Freebie: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: Category
    var location: GeoPoint
    var photoURL: String
    var postedBy: String // Device UID
    var createdAt: Timestamp
    var expiresAt: Timestamp
    var upvotes: Int
    var averageRating: Double
    var reviewCount: Int
    var isActive: Bool
    var cleanlinessRating: Double? // For bathroom category only
    
    enum Category: String, CaseIterable, Codable, Equatable {
        case food = "food"
        case event = "event"
        case stuff = "stuff"
        case service = "service"
        case water = "water"
        case bathroom = "bathroom"
        
        var emoji: String {
            switch self {
            case .food: return "🍕"
            case .event: return "🎉"
            case .stuff: return "📦"
            case .service: return "🔧"
            case .water: return "💧"
            case .bathroom: return "🚻"
            }
        }
        
        var color: String {
            switch self {
            case .food: return "orange"
            case .event: return "purple"
            case .stuff: return "blue"
            case .service: return "green"
            case .water: return "cyan"
            case .bathroom: return "brown"
            }
        }
    }
    
    init(title: String, description: String, category: Category, location: GeoPoint, photoURL: String, postedBy: String, expiresAt: Timestamp? = nil, cleanlinessRating: Double? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.photoURL = photoURL
        self.postedBy = postedBy
        self.createdAt = Timestamp()
        self.expiresAt = expiresAt ?? Timestamp(date: Date().addingTimeInterval(48 * 60 * 60)) // 48 hours default
        self.upvotes = 0
        self.averageRating = 0.0
        self.reviewCount = 0
        self.isActive = true
        self.cleanlinessRating = cleanlinessRating
    }
}

struct Review: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var freebieId: String
    var rating: Double // 1-5 stars
    var reviewText: String
    var reviewerId: String // Device UID
    var createdAt: Timestamp
    
    init(freebieId: String, rating: Double, reviewText: String, reviewerId: String) {
        self.freebieId = freebieId
        self.rating = rating
        self.reviewText = reviewText
        self.reviewerId = reviewerId
        self.createdAt = Timestamp()
    }
}

struct Report: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var freebieId: String
    var reason: ReportReason
    var reporterId: String // Device UID
    var createdAt: Timestamp
    var description: String?
    
    init(freebieId: String, reason: ReportReason, reporterId: String, description: String? = nil) {
        self.freebieId = freebieId
        self.reason = reason
        self.reporterId = reporterId
        self.description = description
        self.createdAt = Timestamp()
    }
}

enum ReportReason: String, CaseIterable, Codable, Equatable {
    case fake = "fake"
    case expired = "expired"
    case inappropriate = "inappropriate"
    
    var displayName: String {
        switch self {
        case .fake: return "Fake/Spam"
        case .expired: return "Expired"
        case .inappropriate: return "Inappropriate"
        }
    }
}

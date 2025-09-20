import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isPoopMode: Bool = false
    
    static let shared = ThemeManager()
    
    private init() {}
    
    func togglePoopMode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isPoopMode.toggle()
            NotificationCenter.default.post(
                name: NSNotification.Name("PoopModeChanged"),
                object: isPoopMode
            )
        }
    }
    
    // Theme colors
    var primaryColor: Color {
        isPoopMode ? Color.brown : Color.blue
    }
    
    var backgroundColor: Color {
        isPoopMode ? Color.brown.opacity(0.1) : Color(.systemGroupedBackground)
    }
    
    var cardBackgroundColor: Color {
        isPoopMode ? Color.brown.opacity(0.2) : Color(.systemBackground)
    }
    
    var textColor: Color {
        isPoopMode ? Color.brown : Color.primary
    }
    
    var secondaryTextColor: Color {
        isPoopMode ? Color.brown.opacity(0.7) : Color.secondary
    }
    
    // Get brown intensity based on cleanliness rating
    func getBrownIntensity(for cleanlinessRating: Double?) -> Double {
        guard let rating = cleanlinessRating else { return 0.0 }
        // More brown = dirtier (inverse of cleanliness)
        return (10 - rating) / 10.0
    }
    
    // Get background color with brown intensity
    func getBrownBackground(for cleanlinessRating: Double?) -> Color {
        let intensity = getBrownIntensity(for: cleanlinessRating)
        return Color.brown.opacity(intensity * 0.3 + 0.1)
    }
    
    // Get text color with brown intensity
    func getBrownText(for cleanlinessRating: Double?) -> Color {
        let intensity = getBrownIntensity(for: cleanlinessRating)
        return Color.brown.opacity(0.8 + (intensity * 0.2))
    }
}


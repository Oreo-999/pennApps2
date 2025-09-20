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
        isPoopMode ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.blue
    }
    
    var backgroundColor: Color {
        isPoopMode ? Color(red: 0.98, green: 0.95, blue: 0.9) : Color(.systemGroupedBackground)
    }
    
    var cardBackgroundColor: Color {
        isPoopMode ? Color(red: 0.95, green: 0.9, blue: 0.85) : Color(.systemBackground)
    }
    
    var textColor: Color {
        isPoopMode ? Color(red: 0.4, green: 0.25, blue: 0.1) : Color.primary
    }
    
    var secondaryTextColor: Color {
        isPoopMode ? Color(red: 0.5, green: 0.35, blue: 0.2) : Color.secondary
    }
    
    // Poop-themed gradients
    var poopGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.8, green: 0.6, blue: 0.3),
                Color(red: 0.6, green: 0.4, blue: 0.2),
                Color(red: 0.4, green: 0.25, blue: 0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.98, green: 0.95, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 0.85)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
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

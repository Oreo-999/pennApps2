import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var deviceService = DeviceService()
    @StateObject private var firestoreService = FirestoreService()
    
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDeleteAccount = false
    @State private var showingAchievements = false
    @State private var userStats = UserStats()
    @State private var userLevel = 1
    @State private var userXP = 0
    @State private var achievements: [Achievement] = []
    @State private var completedAchievements: Set<String> = []
    
    struct UserStats {
        var postedFreebies: Int = 0
        var totalUpvotes: Int = 0
        var totalReviews: Int = 0
        var bathroomsRated: Int = 0
    }
    
    struct Achievement: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let emoji: String
        let xpReward: Int
        let isCompleted: Bool
        let progress: Int
        let maxProgress: Int
    }
    
    // Computed properties for gamification
    private var xpNeededForNextLevel: Int {
        userLevel * 100 // Each level requires level * 100 XP
    }
    
    private var userTitle: String {
        switch userLevel {
        case 1...2: return "Freebie Newbie"
        case 3...5: return "Freebie Explorer"
        case 6...10: return "Freebie Hunter"
        case 11...15: return "Freebie Master"
        case 16...20: return "Freebie Legend"
        default: return "Freebie God"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Gamified Profile header
                        VStack(spacing: 16) {
                            // Level and XP display
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Level \(userLevel)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(userXP) XP")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { showingAchievements = true }) {
                                    Text("🏆")
                                        .font(.title2)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // XP Progress Bar
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Next Level")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(userXP)/\(xpNeededForNextLevel) XP")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: Double(userXP), total: Double(xpNeededForNextLevel))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .scaleEffect(y: 2)
                            }
                            .padding(.horizontal, 20)
                            
                            // Avatar with level ring
                            ZStack {
                                // Level ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                                    .frame(width: 90, height: 90)
                                
                                // Avatar
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Text("👤")
                                    .font(.system(size: 32))
                            }
                            
                            // User info with title
                            VStack(spacing: 4) {
                                Text(userTitle)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Community Member")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Stats section
                        VStack(spacing: 16) {
                            Text("Your Stats")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                StatCard(title: "Posted", value: "\(userStats.postedFreebies)", icon: "plus.circle.fill", color: .blue)
                                StatCard(title: "Upvotes", value: "\(userStats.totalUpvotes)", icon: "heart.fill", color: .red)
                                StatCard(title: "Reviews", value: "\(userStats.totalReviews)", icon: "star.fill", color: .yellow)
                                StatCard(title: "Bathrooms", value: "\(userStats.bathroomsRated)", icon: "toilet.fill", color: .brown)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Quick Achievements Preview
                        VStack(spacing: 16) {
                            HStack {
                                Text("Recent Achievements")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showingAchievements = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(achievements.prefix(5)) { achievement in
                                        AchievementCard(achievement: achievement)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Settings section
                        VStack(spacing: 16) {
                            Text("Settings")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                SettingsRow(icon: "info.circle", title: "About", subtitle: "App information", action: { showingAbout = true })
                                SettingsRow(icon: "lock.shield", title: "Privacy Policy", subtitle: "Data protection", action: { showingPrivacyPolicy = true })
                                SettingsRow(icon: "doc.text", title: "Terms of Service", subtitle: "Usage terms", action: { showingTermsOfService = true })
                                SettingsRow(icon: "trash", title: "Delete Account", subtitle: "Remove all data", action: { showingDeleteAccount = true }, isDestructive: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicySheet()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceSheet()
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This will permanently delete all your posted freebies, reviews, and account data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsSheet(achievements: achievements, userLevel: userLevel, userXP: userXP)
        }
        .onAppear {
            firestoreService.fetchFreebies()
            calculateUserStats()
            initializeAchievements()
            calculateLevelAndXP()
        }
        .onChange(of: firestoreService.freebies) { _ in
            calculateUserStats()
        }
    }
    
    private func calculateUserStats() {
        let deviceId = deviceService.deviceId
        
        // Calculate posted freebies
        userStats.postedFreebies = firestoreService.freebies.filter { $0.postedBy == deviceId }.count
        
        // Calculate bathrooms rated (freebies posted by user that are bathrooms with cleanliness ratings)
        userStats.bathroomsRated = firestoreService.freebies.filter { 
            $0.postedBy == deviceId && 
            $0.category == .bathroom && 
            $0.cleanlinessRating != nil 
        }.count
        
        // Calculate total upvotes from UserDefaults
        userStats.totalUpvotes = UserDefaults.standard.integer(forKey: "totalUpvotes_\(deviceId)")
        
        // Calculate total reviews from UserDefaults
        userStats.totalReviews = UserDefaults.standard.integer(forKey: "totalReviews_\(deviceId)")
    }
    
    private func initializeAchievements() {
        achievements = [
            Achievement(
                title: "First Post",
                description: "Post your first freebie",
                emoji: "🎯",
                xpReward: 50,
                isCompleted: userStats.postedFreebies >= 1,
                progress: min(userStats.postedFreebies, 1),
                maxProgress: 1
            ),
            Achievement(
                title: "Freebie Hunter",
                description: "Post 5 freebies",
                emoji: "🏹",
                xpReward: 100,
                isCompleted: userStats.postedFreebies >= 5,
                progress: min(userStats.postedFreebies, 5),
                maxProgress: 5
            ),
            Achievement(
                title: "Community Helper",
                description: "Post 10 freebies",
                emoji: "🌟",
                xpReward: 200,
                isCompleted: userStats.postedFreebies >= 10,
                progress: min(userStats.postedFreebies, 10),
                maxProgress: 10
            ),
            Achievement(
                title: "Review Master",
                description: "Write 5 reviews",
                emoji: "⭐",
                xpReward: 75,
                isCompleted: userStats.totalReviews >= 5,
                progress: min(userStats.totalReviews, 5),
                maxProgress: 5
            ),
            Achievement(
                title: "Bathroom Critic",
                description: "Rate 3 bathrooms",
                emoji: "🚽",
                xpReward: 100,
                isCompleted: userStats.bathroomsRated >= 3,
                progress: min(userStats.bathroomsRated, 3),
                maxProgress: 3
            ),
            Achievement(
                title: "Popular Poster",
                description: "Get 10 upvotes",
                emoji: "❤️",
                xpReward: 150,
                isCompleted: userStats.totalUpvotes >= 10,
                progress: min(userStats.totalUpvotes, 10),
                maxProgress: 10
            ),
            Achievement(
                title: "Viral Sensation",
                description: "Get 50 upvotes",
                emoji: "🔥",
                xpReward: 300,
                isCompleted: userStats.totalUpvotes >= 50,
                progress: min(userStats.totalUpvotes, 50),
                maxProgress: 50
            ),
            Achievement(
                title: "Poop Mode Pro",
                description: "Use poop mode 10 times",
                emoji: "💩",
                xpReward: 100,
                isCompleted: UserDefaults.standard.integer(forKey: "poopModeUsage_\(deviceService.deviceId)") >= 10,
                progress: min(UserDefaults.standard.integer(forKey: "poopModeUsage_\(deviceService.deviceId)"), 10),
                maxProgress: 10
            )
        ]
    }
    
    private func calculateLevelAndXP() {
        let totalXP = achievements.filter { $0.isCompleted }.reduce(0) { $0 + $1.xpReward }
        userXP = totalXP
        
        // Calculate level based on XP
        var level = 1
        var xpForLevel = 100
        var remainingXP = totalXP
        
        while remainingXP >= xpForLevel {
            remainingXP -= xpForLevel
            level += 1
            xpForLevel = level * 100
        }
        
        userLevel = level
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isPoopMode ? themeManager.primaryColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    var isDestructive: Bool = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeManager.isPoopMode ? themeManager.cardGradient : LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            
                            if themeManager.isPoopMode {
                                Text("💩")
                                    .font(.system(size: 32))
                            } else {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("Freebie Finder")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Freebie Finder helps you discover and share free stuff in your area. Whether it's leftover food, free events, or even bathroom locations with cleanliness ratings - find it all here!")
                            .font(.body)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineSpacing(4)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "map.fill", title: "Interactive Map", description: "See freebies near you on a real-time map")
                            FeatureRow(icon: "list.bullet", title: "Feed View", description: "Browse all available freebies in a list")
                            FeatureRow(icon: "plus.circle.fill", title: "Post Freebies", description: "Share free stuff with your community")
                            FeatureRow(icon: "heart.fill", title: "Upvote System", description: "Rate and review freebies")
                            FeatureRow(icon: "toilet.fill", title: "Poop Mode", description: "Special bathroom finder with cleanliness ratings")
                        }
                    }
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Credits")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Built for PennApps 2024 with SwiftUI and Firebase. Special thanks to all the freebie sharers and bathroom reviewers! 💩")
                            .font(.body)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineSpacing(4)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(
                            title: "Information We Collect",
                            content: "We collect your device ID, location data (with permission), and any content you post (photos, descriptions, ratings). We do not collect personal information like your name or email."
                        )
                        
                        PolicySection(
                            title: "How We Use Your Data",
                            content: "Your data is used to show freebies near you, display your posts to other users, and improve the app experience. Location data is only used to show nearby freebies."
                        )
                        
                        PolicySection(
                            title: "Data Storage",
                            content: "All data is stored securely on Firebase servers. Your posts and ratings are public to help other users find freebies."
                        )
                        
                        PolicySection(
                            title: "Your Rights",
                            content: "You can delete your account and all associated data at any time through the settings. You control what information you share."
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(
                            title: "Acceptable Use",
                            content: "Use the app responsibly. Don't post inappropriate content, spam, or false information. Be respectful to other users."
                        )
                        
                        PolicySection(
                            title: "Content Guidelines",
                            content: "Posts should be about genuinely free items or services. Bathroom ratings should be honest and helpful. No commercial advertising."
                        )
                        
                        PolicySection(
                            title: "User Responsibility",
                            content: "You're responsible for the content you post. Make sure items are actually free and safe before posting."
                        )
                        
                        PolicySection(
                            title: "App Availability",
                            content: "The app is provided as-is. We're not responsible for the quality or availability of posted freebies."
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(content)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineSpacing(4)
        }
    }
}

// Achievement Card Component
struct AchievementCard: View {
    let achievement: ProfileView.Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(achievement.emoji)
                    .font(.title2)
            }
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if !achievement.isCompleted {
                    Text("\(achievement.progress)/\(achievement.maxProgress)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("✓")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isCompleted ? Color.green.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Achievements Sheet
struct AchievementsSheet: View {
    let achievements: [ProfileView.Achievement]
    let userLevel: Int
    let userXP: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text("🏆")
                            .font(.system(size: 60))
                        
                        VStack(spacing: 8) {
                            Text("Level \(userLevel)")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("\(userXP) Total XP")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Achievements Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementDetailCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Detailed Achievement Card
struct AchievementDetailCard: View {
    let achievement: ProfileView.Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text(achievement.emoji)
                    .font(.title)
            }
            
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !achievement.isCompleted {
                    ProgressView(value: Double(achievement.progress), total: Double(achievement.maxProgress))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                    
                    Text("\(achievement.progress)/\(achievement.maxProgress)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Text("✓ Completed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("+\(achievement.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(achievement.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(achievement.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ProfileView()
}

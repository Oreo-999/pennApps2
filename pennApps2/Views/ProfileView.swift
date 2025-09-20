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
    @State private var userStats = UserStats()
    
    struct UserStats {
        var postedFreebies: Int = 0
        var totalUpvotes: Int = 0
        var totalReviews: Int = 0
        var bathroomsRated: Int = 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
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
                            
                            // User info
                            VStack(spacing: 4) {
                                Text("Freebie Finder")
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
        .onAppear {
            firestoreService.fetchFreebies()
            calculateUserStats()
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


#Preview {
    ProfileView()
}

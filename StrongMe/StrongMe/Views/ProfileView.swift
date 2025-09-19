import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(user: dataManager.currentUser) {
                        showingEditProfile = true
                    }
                    
                    // Stats Overview
                    StatsOverviewView(workouts: dataManager.workouts)
                    
                    // Quick Actions
                    QuickActionsView()
                    
                    // Settings Section
                    SettingsSectionView {
                        showingSettings = true
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(dataManager)
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User?
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                if let user = user, !user.name.isEmpty {
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(user?.name ?? "No Name")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(user?.email ?? "No Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let goals = user?.fitnessGoals, !goals.isEmpty {
                    Text(goals.first?.rawValue ?? "")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            
            // Edit Button
            Button(action: onEdit) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatsOverviewView: View {
    let workouts: [Workout]
    
    private var totalWorkouts: Int {
        workouts.count
    }
    
    private var totalSets: Int {
        workouts.flatMap { $0.exercises.flatMap { $0.sets } }.count
    }
    
    private var totalVolume: Double {
        workouts.flatMap { $0.exercises.flatMap { $0.sets } }
            .compactMap { set in
                guard let weight = set.weight, let reps = set.reps else { return nil }
                return weight * Double(reps)
            }
            .reduce(0, +)
    }
    
    private var averageWorkoutDuration: TimeInterval {
        guard !workouts.isEmpty else { return 0 }
        let totalDuration = workouts.compactMap { $0.duration }.reduce(0, +)
        return totalDuration / Double(workouts.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    icon: "list.bullet",
                    color: .green
                )
                
                StatCard(
                    title: "Volume",
                    value: "\(Int(totalVolume)) lbs",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Avg Duration",
                    value: formatDuration(averageWorkoutDuration),
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                QuickActionRow(
                    title: "Export Data",
                    subtitle: "Download your workout data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    // Export functionality
                }
                
                QuickActionRow(
                    title: "Import Data",
                    subtitle: "Import workouts from other apps",
                    icon: "square.and.arrow.down",
                    color: .green
                ) {
                    // Import functionality
                }
                
                QuickActionRow(
                    title: "Backup & Sync",
                    subtitle: "Keep your data safe",
                    icon: "icloud.fill",
                    color: .purple
                ) {
                    // Backup functionality
                }
            }
        }
    }
}

struct QuickActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSectionView: View {
    let onSettingsTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingsRow(
                    title: "General",
                    icon: "gear",
                    color: .gray
                ) {
                    onSettingsTap()
                }
                
                SettingsRow(
                    title: "Notifications",
                    icon: "bell",
                    color: .orange
                ) {
                    // Notifications settings
                }
                
                SettingsRow(
                    title: "Privacy",
                    icon: "lock",
                    color: .red
                ) {
                    // Privacy settings
                }
                
                SettingsRow(
                    title: "About",
                    icon: "info.circle",
                    color: .blue
                ) {
                    // About screen
                }
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder views
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Profile")
                    .font(.title)
                    .padding()
                
                Text("Profile editing functionality will be implemented here.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.title)
                    .padding()
                
                Text("Settings functionality will be implemented here.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
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

#Preview {
    ProfileView()
        .environmentObject(DataManager())
}

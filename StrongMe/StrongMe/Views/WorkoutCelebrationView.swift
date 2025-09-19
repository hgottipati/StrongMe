import SwiftUI

struct WorkoutCelebrationView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let onComplete: () -> Void
    @State private var workoutStreak: Int = 5
    @State private var weeklyWorkouts: Int = 2
    @State private var showingShareSheet = false
    
    private var totalVolume: Double {
        workout.exercises.flatMap { $0.sets }
            .compactMap { set in
                guard let weight = set.weight, let reps = set.reps else { return nil }
                return weight * Double(reps)
            }
            .reduce(0, +)
    }
    
    private var totalSets: Int {
        workout.exercises.flatMap { $0.sets }.count
    }
    
    private var workoutDuration: TimeInterval {
        Date().timeIntervalSince(workout.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Bar Spacer
            Color.clear
                .frame(height: 44)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Celebration Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("Good job!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "party.popper.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                        }
                        
                        Text("This is your \(workoutStreak)th workout")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Workout Summary Card
                    VStack(spacing: 24) {
                        // Muscle Groups Visualization
                        HStack(spacing: 40) {
                            // Front view
                            VStack(spacing: 8) {
                                ZStack {
                                    // Body outline
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 80, height: 120)
                                    
                                    // Highlighted muscle groups
                                    VStack(spacing: 4) {
                                        // Chest
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue)
                                            .frame(width: 40, height: 20)
                                        
                                        // Shoulders
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 16, height: 16)
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 16, height: 16)
                                        }
                                        
                                        // Arms
                                        HStack(spacing: 20) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue)
                                                .frame(width: 8, height: 30)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue)
                                                .frame(width: 8, height: 30)
                                        }
                                        
                                        // Abs
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue)
                                            .frame(width: 30, height: 15)
                                    }
                                }
                                
                                Text("Front")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Back view
                            VStack(spacing: 8) {
                                ZStack {
                                    // Body outline
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 80, height: 120)
                                    
                                    // Highlighted muscle groups
                                    VStack(spacing: 4) {
                                        // Upper back
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.7))
                                            .frame(width: 40, height: 20)
                                        
                                        // Shoulders
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color.blue.opacity(0.7))
                                                .frame(width: 16, height: 16)
                                            Circle()
                                                .fill(Color.blue.opacity(0.7))
                                                .frame(width: 16, height: 16)
                                        }
                                        
                                        // Arms
                                        HStack(spacing: 20) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.7))
                                                .frame(width: 8, height: 30)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.7))
                                                .frame(width: 8, height: 30)
                                        }
                                        
                                        // Lower back
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue.opacity(0.7))
                                            .frame(width: 30, height: 15)
                                    }
                                }
                                
                                Text("Back")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Weekly Progress
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                ForEach(["S", "S", "M", "T", "W", "T", "F"], id: \.self) { day in
                                    VStack(spacing: 4) {
                                        Text(day)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Circle()
                                            .fill(day == "T" || day == "F" ? Color.blue : Color.gray.opacity(0.3))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                    .opacity(day == "T" || day == "F" ? 1 : 0)
                                            )
                                    }
                                }
                            }
                            
                            Text("You worked out **\(weeklyWorkouts) times** in the last 7 days")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        
                        // App Branding
                        HStack {
                            Text("STRONGME")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("@user")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Share Section
                    VStack(spacing: 16) {
                        Text("Share workout - Tag @strongmeapp")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ShareButton(icon: "photo", title: "Background", color: .white)
                                ShareButton(icon: "camera", title: "Stories", color: .purple)
                                ShareButton(icon: "square.and.arrow.up", title: "More", color: .white)
                                ShareButton(icon: "link", title: "Workout Link", color: .white)
                                ShareButton(icon: "doc.on.doc", title: "Copy Text", color: .white)
                                ShareButton(icon: "x.circle", title: "Twitter", color: .black)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            
            // Done Button
            VStack {
                Button(action: {
                    // Call the completion callback to dismiss the entire workout flow
                    onComplete()
                }) {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 34) // Account for home indicator
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [workoutShareText])
        }
    }
    
    private var workoutShareText: String {
        return """
        Just completed my \(workout.name) workout! 💪
        
        Duration: \(formatDuration(workoutDuration))
        Volume: \(Int(totalVolume)) lbs
        Sets: \(totalSets)
        
        #StrongMe #Fitness #Workout
        """
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color == .white ? .black : .white)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    WorkoutCelebrationView(workout: Workout(
        name: "Monday Workout",
        exercises: [
            WorkoutExercise(
                exercise: Exercise(name: "Bench Press", category: .strength, muscleGroups: [.chest]),
                sets: [
                    Set(reps: 10, weight: 135, order: 1),
                    Set(reps: 8, weight: 155, order: 2)
                ],
                order: 0
            )
        ]
    ), onComplete: {
        print("Workout completed!")
    })
    .environmentObject(DataManager())
}

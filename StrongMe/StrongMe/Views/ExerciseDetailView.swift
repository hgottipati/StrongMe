import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isPlaying = false
    @State private var animationProgress: Double = 0
    
    private let tabs = ["Summary", "History", "How to", "Leaderboard"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Exercise Header
                ExerciseHeaderView(exercise: exercise)
                
                // Tab Navigation
                TabNavigationView(selectedTab: $selectedTab, tabs: tabs)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    SummaryTabView(exercise: exercise, isPlaying: $isPlaying, animationProgress: $animationProgress)
                        .tag(0)
                    
                    HistoryTabView(exercise: exercise)
                        .tag(1)
                    
                    HowToTabView(exercise: exercise)
                        .tag(2)
                    
                    LeaderboardTabView(exercise: exercise)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
        }
    }
}

struct ExerciseHeaderView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Primary: \(exercise.muscleGroups.first?.rawValue ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if exercise.muscleGroups.count > 1 {
                        Text("Secondary: \(exercise.muscleGroups.dropFirst().map { $0.rawValue }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}

struct TabNavigationView: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

struct SummaryTabView: View {
    let exercise: Exercise
    @Binding var isPlaying: Bool
    @Binding var animationProgress: Double
    @EnvironmentObject var dataManager: DataManager
    
    private var exerciseHistory: [Workout] {
        dataManager.workouts.filter { workout in
            workout.exercises.contains { $0.exercise.id == exercise.id }
        }
    }
    
    private var personalRecords: (heaviestWeight: Double, bestOneRM: Double, bestVolume: Double) {
        var heaviest: Double = 0
        var bestOneRM: Double = 0
        var bestVolume: Double = 0
        
        for workout in exerciseHistory {
            for workoutExercise in workout.exercises where workoutExercise.exercise.id == exercise.id {
                for set in workoutExercise.sets {
                    if let weight = set.weight, let reps = set.reps {
                        // Heaviest weight
                        if weight > heaviest {
                            heaviest = weight
                        }
                        
                        // One rep max calculation (simplified)
                        let oneRM = weight * (1 + Double(reps) / 30)
                        if oneRM > bestOneRM {
                            bestOneRM = oneRM
                        }
                        
                        // Best volume
                        let volume = weight * Double(reps)
                        if volume > bestVolume {
                            bestVolume = volume
                        }
                    }
                }
            }
        }
        
        return (heaviest, bestOneRM, bestVolume)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Animated Exercise Illustration
                AnimatedExerciseView(
                    exercise: exercise,
                    isPlaying: $isPlaying,
                    animationProgress: $animationProgress
                )
                
                // Progress Section
                ProgressSectionView(
                    exercise: exercise,
                    personalRecords: personalRecords
                )
                
                // Personal Records
                PersonalRecordsView(personalRecords: personalRecords)
            }
            .padding()
        }
    }
}

struct AnimatedExerciseView: View {
    let exercise: Exercise
    @Binding var isPlaying: Bool
    @Binding var animationProgress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Exercise illustration background
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 250)
                
                // Animated exercise figure
                ExerciseFigureView(
                    exercise: exercise,
                    isPlaying: isPlaying,
                    animationProgress: animationProgress
                )
                
                // Play/Pause button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPlaying.toggle()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .padding(.top, 16)
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)
                    Text("How to log \(exercise.equipment?.rawValue.lowercased() ?? "bodyweight") exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ExerciseFigureView: View {
    let exercise: Exercise
    let isPlaying: Bool
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            // Simplified exercise figure based on exercise type
            switch exercise.category {
            case .strength:
                StrengthExerciseFigure(exercise: exercise, progress: animationProgress)
            case .cardio:
                CardioExerciseFigure(exercise: exercise, progress: animationProgress)
            case .flexibility:
                FlexibilityExerciseFigure(exercise: exercise, progress: animationProgress)
            case .sports:
                SportsExerciseFigure(exercise: exercise, progress: animationProgress)
            case .other:
                OtherExerciseFigure(exercise: exercise, progress: animationProgress)
            }
        }
        .onAppear {
            if isPlaying {
                startAnimation()   
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
            // Animation will be handled by the individual exercise figures
        }
    }
}

struct StrengthExerciseFigure: View {
    let exercise: Exercise
    let progress: Double
    
    var body: some View {
        VStack {
            // Simplified stick figure for strength exercises
            ZStack {
                // Body
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 60)
                    .offset(y: sin(progress * .pi * 2) * 5)
                
                // Arms
                HStack(spacing: 40) {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 30, height: 6)
                        .rotationEffect(.degrees(sin(progress * .pi * 2) * 15))
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 30, height: 6)
                        .rotationEffect(.degrees(-sin(progress * .pi * 2) * 15))
                }
                .offset(y: -20)
                
                // Head
                Circle()
                    .fill(Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(y: -40)
            }
            
            Text("Bench Press")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct CardioExerciseFigure: View {
    let exercise: Exercise
    let progress: Double
    
    var body: some View {
        VStack {
            // Cardio exercise figure
            ZStack {
                Circle()
                    .stroke(Color.orange, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .scaleEffect(1 + sin(progress * .pi * 2) * 0.1)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }
            
            Text("Running")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct FlexibilityExerciseFigure: View {
    let exercise: Exercise
    let progress: Double
    
    var body: some View {
        VStack {
            // Flexibility exercise figure
            ZStack {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 60)
                    .rotationEffect(.degrees(sin(progress * .pi * 2) * 10))
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(y: -40)
            }
            
            Text("Stretching")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct SportsExerciseFigure: View {
    let exercise: Exercise
    let progress: Double
    
    var body: some View {
        VStack {
            // Sports exercise figure
            ZStack {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 60)
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(y: -40)
                    .offset(x: sin(progress * .pi * 2) * 10)
            }
            
            Text("Sports")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct OtherExerciseFigure: View {
    let exercise: Exercise
    let progress: Double
    
    var body: some View {
        VStack {
            // Other exercise figure
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 60, height: 60)
                    .scaleEffect(1 + sin(progress * .pi * 2) * 0.1)
                
                Image(systemName: "questionmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text("Other")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct ProgressSectionView: View {
    let exercise: Exercise
    let personalRecords: (heaviestWeight: Double, bestOneRM: Double, bestVolume: Double)
    @State private var selectedMetric = 0
    
    private let metrics = ["Heaviest Weight", "One Rep Max", "Best Set Vol"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(Int(personalRecords.heaviestWeight)) lbs (In progress)")
                .font(.headline)
            
            // Progress Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Heaviest Weight")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Simplified progress chart
                HStack {
                    Text("Last 3 months")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(personalRecords.heaviestWeight))lbs")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Simple line chart representation
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 4)
                    .overlay(
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Metric Selection
            HStack(spacing: 12) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    Button(action: {
                        selectedMetric = index
                    }) {
                        Text(metric)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMetric == index ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedMetric == index ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

struct PersonalRecordsView: View {
    let personalRecords: (heaviestWeight: Double, bestOneRM: Double, bestVolume: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(.yellow)
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                PersonalRecordRow(
                    title: "Heaviest Weight",
                    value: "\(Int(personalRecords.heaviestWeight))lbs",
                    icon: "dumbbell.fill"
                )
                
                PersonalRecordRow(
                    title: "Best 1RM",
                    value: "\(String(format: "%.1f", personalRecords.bestOneRM))lbs",
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                PersonalRecordRow(
                    title: "Best Volume",
                    value: "\(Int(personalRecords.bestVolume))lbs",
                    icon: "chart.bar.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


// Placeholder views for other tabs
struct HistoryTabView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack {
            Text("Exercise History")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your workout history for this exercise will appear here.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct HowToTabView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Perform")
                .font(.title2)
                .fontWeight(.bold)
            
            if let instructions = exercise.instructions {
                Text(instructions)
                    .font(.body)
            } else {
                Text("Instructions for \(exercise.name) will be provided here.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct LeaderboardTabView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack {
            Text("Leaderboard")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Compare your performance with other users.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    ExerciseDetailView(exercise: Exercise(
        name: "Bench Press (Barbell)",
        category: .strength,
        muscleGroups: [.chest, .triceps, .shoulders],
        equipment: .barbell,
        instructions: "Lie on a flat bench and press the barbell up and down."
    ))
    .environmentObject(DataManager())
}

import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewWorkout = false
    @State private var selectedWorkout: Workout? = nil
    @State private var showingWorkoutOverview: Workout? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.workouts.isEmpty {
                    EmptyWorkoutsView {
                        showingNewWorkout = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                        ForEach(dataManager.workouts) { workout in
                            WorkoutCardView(
                                workout: workout,
                                onTap: {
                                    selectedWorkout = workout
                                },
                                onStartWorkout: {
                                    showingWorkoutOverview = workout
                                }
                            )
                        }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewWorkout = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewWorkout) {
                NewWorkoutView()
                    .environmentObject(dataManager)
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
                    .environmentObject(dataManager)
            }
            .sheet(item: $showingWorkoutOverview) { workout in
                WorkoutOverviewView(workout: workout)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct EmptyWorkoutsView: View {
    let onCreateWorkout: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Workouts Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first workout to start tracking your fitness journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateWorkout) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct WorkoutCardView: View {
    let workout: Workout
    let onTap: () -> Void
    let onStartWorkout: () -> Void
    
    private var exerciseCount: Int {
        workout.exercises.count
    }
    
    private var totalSets: Int {
        workout.exercises.flatMap { $0.sets }.count
    }
    
    private var completedSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    private var isCompleted: Bool {
        let totalSets = workout.exercises.flatMap { $0.sets }.count
        return totalSets > 0 && completedSets == totalSets
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(workout.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(exerciseCount) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(completedSets)/\(totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Bar
                ProgressView(value: Double(completedSets), total: Double(totalSets))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                HStack {
                    Text("Duration: \(formatDuration(workout.duration ?? 0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Button(action: onStartWorkout) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutsView()
        .environmentObject(DataManager())
}

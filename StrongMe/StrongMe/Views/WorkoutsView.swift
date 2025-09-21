import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewWorkout = false
    @State private var selectedWorkout: Workout? = nil
    @State private var showingWorkoutOverview: Workout? = nil
    @State private var showingShareSheet = false
    @State private var workoutToShare: Workout?
    
    // MARK: - Action Functions
    private func shareWorkout(_ workout: Workout) {
        workoutToShare = workout
        showingShareSheet = true
    }
    
    private func duplicateWorkout(_ workout: Workout) {
        let duplicatedWorkout = Workout(
            name: "\(workout.name) Copy",
            exercises: workout.exercises.map { exercise in
                WorkoutExercise(
                    exercise: exercise.exercise,
                    sets: exercise.sets.map { set in
                        Set(
                            reps: set.reps,
                            weight: nil, // Reset weight for new workout
                            duration: set.duration,
                            distance: set.distance,
                            restTime: set.restTime,
                            isCompleted: false, // Reset completion status
                            order: set.order
                        )
                    },
                    notes: exercise.notes,
                    order: exercise.order
                )
            },
            date: Date(),
            duration: nil,
            notes: workout.notes,
            isTemplate: workout.isTemplate
        )
        
        dataManager.workouts.append(duplicatedWorkout)
        print("DEBUG: WorkoutsView - Duplicated workout: \(workout.name) -> \(duplicatedWorkout.name)")
    }
    
    private func editWorkout(_ workout: Workout) {
        selectedWorkout = workout
    }
    
    private func deleteWorkout(_ workout: Workout) {
        dataManager.deleteWorkout(workout)
        print("DEBUG: WorkoutsView - Deleted workout: \(workout.name)")
    }
    
    private func moveWorkouts(from source: IndexSet, to destination: Int) {
        print("DEBUG: WorkoutsView - Moving workouts from \(source) to \(destination)")
        dataManager.workouts.move(fromOffsets: source, toOffset: destination)
        dataManager.saveWorkoutsDirectly(dataManager.workouts)
        print("DEBUG: WorkoutsView - Workouts reordered successfully")
    }
    
    private func workoutShareText(_ workout: Workout) -> String {
        var text = "🏋️ Workout: \(workout.name)\n\n"
        
        for exercise in workout.exercises {
            text += "• \(exercise.exercise.name)\n"
            for set in exercise.sets {
                if let weight = set.weight, let reps = set.reps {
                    text += "  - \(Int(weight))lbs × \(reps) reps\n"
                } else if let reps = set.reps {
                    text += "  - \(reps) reps\n"
                }
            }
            text += "\n"
        }
        
        if let notes = workout.notes, !notes.isEmpty {
            text += "Notes: \(notes)\n"
        }
        
        text += "\nCreated with StrongMe 💪"
        return text
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.workouts.isEmpty {
                    EmptyWorkoutsView {
                        showingNewWorkout = true
                    }
                } else {
                    List {
                        ForEach(dataManager.workouts) { workout in
                            WorkoutCardView(
                                workout: workout,
                                dataManager: dataManager,
                                onTap: {
                                    selectedWorkout = workout
                                },
                                onStartWorkout: {
                                    print("DEBUG: WorkoutsView - Starting workout: \(workout.name)")
                                    print("DEBUG: WorkoutsView - Workout ID: \(workout.id)")
                                    print("DEBUG: WorkoutsView - Exercise count: \(workout.exercises.count)")
                                    for (exIndex, exercise) in workout.exercises.enumerated() {
                                        print("DEBUG: WorkoutsView - Exercise \(exIndex): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                                        for (setIndex, set) in exercise.sets.enumerated() {
                                            print("DEBUG: WorkoutsView -   Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
                                        }
                                    }
                                    
                                    // Find the most recent modified workout with the same name
                                    let recentModifiedWorkout = dataManager.workouts
                                        .filter { $0.name == workout.name && $0.id != workout.id }
                                        .filter { w in
                                            w.exercises.contains { exercise in
                                                exercise.sets.contains { set in
                                                    (set.weight ?? 0) > 0 || (set.reps ?? 0) > 0 || set.isCompleted
                                                }
                                            }
                                        }
                                        .sorted { $0.date > $1.date }
                                        .first
                                    
                                    if let recentWorkout = recentModifiedWorkout {
                                        print("DEBUG: WorkoutsView - Found recent modified workout: \(recentWorkout.name) (ID: \(recentWorkout.id))")
                                        print("DEBUG: WorkoutsView - Recent workout sets:")
                                        for exercise in recentWorkout.exercises {
                                            print("DEBUG: WorkoutsView -   Exercise: \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                                            for (setIndex, set) in exercise.sets.enumerated() {
                                                print("DEBUG: WorkoutsView -     Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
                                            }
                                        }
                                        // Create a new workout instance based on the recent workout's structure, but with fresh completion states
                                        let newWorkout = Workout(
                                            name: recentWorkout.name,
                                            exercises: recentWorkout.exercises.map { exercise in
                                                WorkoutExercise(
                                                    exercise: exercise.exercise,
                                                    sets: exercise.sets.map { set in
                                                        Set(
                                                            reps: set.reps ?? 10, // Keep the reps from previous session
                                                            weight: set.weight, // Keep the weight from previous session
                                                            duration: set.duration,
                                                            distance: set.distance,
                                                            restTime: set.restTime,
                                                            isCompleted: false, // Start as not completed for new session
                                                            order: set.order
                                                        )
                                                    },
                                                    notes: exercise.notes,
                                                    order: exercise.order
                                                )
                                            },
                                            date: Date(), // New date for new session
                                            duration: nil,
                                            notes: recentWorkout.notes,
                                            isTemplate: false
                                        )
                                        
                                        print("DEBUG: WorkoutsView - Created new workout from recent modified workout: \(newWorkout.name)")
                                        print("DEBUG: WorkoutsView - New workout ID: \(newWorkout.id)")
                                        print("DEBUG: WorkoutsView - New workout sets:")
                                        for exercise in newWorkout.exercises {
                                            print("DEBUG: WorkoutsView -   Exercise: \(exercise.exercise.name)")
                                            for (index, set) in exercise.sets.enumerated() {
                                                print("DEBUG: WorkoutsView -     Set \(index): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
                                            }
                                        }
                                        
                                        showingWorkoutOverview = newWorkout
                                    } else {
                                        print("DEBUG: WorkoutsView - No recent modified workout found, using template")
                                        showingWorkoutOverview = workout
                                    }
                                },
                                onShare: {
                                    shareWorkout(workout)
                                },
                                onDuplicate: {
                                    duplicateWorkout(workout)
                                },
                                onEdit: {
                                    editWorkout(workout)
                                },
                                onDelete: {
                                    deleteWorkout(workout)
                                }
                            )
                        }
                        .onMove(perform: moveWorkouts)
                        .listStyle(PlainListStyle())
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
                WorkoutSheetView(workout: workout, dataManager: dataManager)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let workout = workoutToShare {
                    ShareSheet(activityItems: [workoutShareText(workout)])
                }
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
    let dataManager: DataManager
    let onTap: () -> Void
    let onStartWorkout: () -> Void
    let onShare: () -> Void
    let onDuplicate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
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
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(exerciseCount) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(completedSets)/\(totalSets) sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 3-dot menu
                        Menu {
                            Button(action: onShare) {
                                Label("Share Workout", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: onDuplicate) {
                                Label("Duplicate Workout", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: onEdit) {
                                Label("Edit Workout", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(action: onDelete) {
                                Label("Delete Workout", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(8)
                        }
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
                        // Debug logging for completion status
                        let _ = print("DEBUG: WorkoutCardView - Workout '\(workout.name)' not completed. Total sets: \(totalSets), Completed sets: \(completedSets)")
                        Button(action: {
                            print("DEBUG: WorkoutCardView - Start button tapped for workout: \(workout.name)")
                            onStartWorkout()
                        }) {
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
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
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

struct WorkoutSheetView: View {
    let workout: Workout
    let dataManager: DataManager
    
    // Check if this workout has been modified (has actual set data)
    private var hasBeenModified: Bool {
        let modified = workout.exercises.contains { exercise in
            exercise.sets.contains { set in
                (set.weight ?? 0) > 0 || (set.reps ?? 0) > 0 || set.isCompleted
            }
        }
        
        print("DEBUG: WorkoutsView.hasBeenModified - Workout: \(workout.name)")
        print("DEBUG: WorkoutsView.hasBeenModified - Has been modified: \(modified)")
        print("DEBUG: WorkoutsView.hasBeenModified - Exercise count: \(workout.exercises.count)")
        
        for (exIndex, exercise) in workout.exercises.enumerated() {
            print("DEBUG: WorkoutsView.hasBeenModified - Exercise \(exIndex): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
            for (setIndex, set) in exercise.sets.enumerated() {
                print("DEBUG: WorkoutsView.hasBeenModified -   Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
            }
        }
        
        return modified
    }
    
    // Create a new workout instance based on the template
    private var newWorkout: Workout {
        Workout(
            name: workout.name,
            exercises: workout.exercises.map { exercise in
                WorkoutExercise(
                    exercise: exercise.exercise,
                    sets: exercise.sets.map { set in
                        Set(
                            reps: 10, // Default reps for new session
                            weight: nil, // Start with no weight for new session
                            duration: set.duration,
                            distance: set.distance,
                            restTime: set.restTime,
                            isCompleted: false, // Start as not completed
                            order: set.order
                        )
                    },
                    notes: exercise.notes,
                    order: exercise.order
                )
            },
            date: Date(), // New date for new session
            duration: nil,
            notes: workout.notes,
            isTemplate: false
        )
    }
    
    var body: some View {
        Group {
            if hasBeenModified {
                // Use the actual saved workout (includes deletions and modifications)
                ActiveWorkoutView(workout: workout, onWorkoutComplete: {
                    // Refresh the workout list after completion
                    print("DEBUG: WorkoutsView - Workout completed, refreshing list")
                })
                .environmentObject(dataManager)
                .onAppear {
                    print("DEBUG: WorkoutsView - Opening modified workout: \(workout.name)")
                    print("DEBUG: WorkoutsView - Workout ID: \(workout.id)")
                    print("DEBUG: WorkoutsView - Workout sets:")
                    for exercise in workout.exercises {
                        print("DEBUG: WorkoutsView -   Exercise: \(exercise.exercise.name)")
                        for (index, set) in exercise.sets.enumerated() {
                            print("DEBUG: WorkoutsView -     Set \(index): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
                        }
                    }
                }
            } else {
                // Create a new workout instance based on the template
                ActiveWorkoutView(workout: newWorkout, onWorkoutComplete: {
                    // Refresh the workout list after completion
                })
                .environmentObject(dataManager)
                .onAppear {
                    print("DEBUG: WorkoutsView - Creating new workout from template: \(workout.name)")
                    print("DEBUG: WorkoutsView - Original workout ID: \(workout.id)")
                    print("DEBUG: WorkoutsView - New workout ID: \(newWorkout.id)")
                    print("DEBUG: WorkoutsView - New workout sets:")
                    for exercise in newWorkout.exercises {
                        print("DEBUG: WorkoutsView -   Exercise: \(exercise.exercise.name)")
                        for (index, set) in exercise.sets.enumerated() {
                            print("DEBUG: WorkoutsView -     Set \(index): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutsView()
        .environmentObject(DataManager())
}

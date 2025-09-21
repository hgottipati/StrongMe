import SwiftUI

struct SaveWorkoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let originalWorkout: Workout
    let onComplete: (() -> Void)?
    @State private var workoutName: String
    @State private var workoutDescription: String = ""
    @State private var showingUpdateRoutine = false
    @State private var showingCelebration = false
    @State private var hasWorkoutChanged: Bool = false
    
    init(workout: Workout, originalWorkout: Workout, onComplete: (() -> Void)? = nil) {
        self.workout = workout
        self.originalWorkout = originalWorkout
        self.onComplete = onComplete
        self._workoutName = State(initialValue: workout.name)
    }
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Workout Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Enter workout name", text: $workoutName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                workoutName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Workout Summary
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDuration(workoutDuration))
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Volume")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(totalVolume)) lbs")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(totalSets)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Date and Time
                        HStack {
                            Text("When")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(workout.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Media Attachment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Media")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            // Add photo/video functionality
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                Text("Add a photo / video")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                        }
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("How did your workout go? Leave some notes here...", text: $workoutDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Settings Section
                    VStack(spacing: 16) {
                        SettingsRow(title: "Visibility", icon: "eye", color: .blue, action: {})
                        SettingsRow(title: "Routine Settings", icon: "gear", color: .gray, action: {})
                        SettingsRow(title: "Sync With", icon: "heart", color: .red, action: {})
                    }
                    
                    // Discard Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Discard Workout")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Save Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
            .alert("Update '\(workout.name)'", isPresented: $showingUpdateRoutine) {
                Button("Update Routine") {
                    updateRoutine()
                }
                Button("Keep Original Routine") {
                    keepOriginalRoutine()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                let addedExercises = workout.exercises.count - originalWorkout.exercises.count
                let removedExercises = originalWorkout.exercises.count - workout.exercises.count
                
                if addedExercises > 0 {
                    Text("You added \(addedExercises) exercise\(addedExercises == 1 ? "" : "s") to this workout.")
                } else if removedExercises > 0 {
                    Text("You removed \(removedExercises) exercise\(removedExercises == 1 ? "" : "s") from this workout.")
                } else {
                    Text("You made changes to this workout (reordered exercises or changed details).")
                }
            }
            .fullScreenCover(isPresented: $showingCelebration) {
                WorkoutCelebrationView(workout: workout, onComplete: {
                    // Call the completion callback to dismiss the entire workout flow
                    onComplete?()
                })
                .environmentObject(dataManager)
            }
            .onAppear {
                detectChanges()
            }
        }
    }
    
    private func detectChanges() {
        print("DEBUG: SaveWorkoutView - Original workout has \(originalWorkout.exercises.count) exercises")
        print("DEBUG: SaveWorkoutView - Current workout has \(workout.exercises.count) exercises")
        
        // Check if exercises were added/removed during the workout
        let exerciseCountChanged = workout.exercises.count != originalWorkout.exercises.count
        print("DEBUG: SaveWorkoutView - exerciseCountChanged: \(exerciseCountChanged)")
        
        // Check if any exercise content changed (different exercises)
        var exerciseContentChanged = false
        if workout.exercises.count == originalWorkout.exercises.count {
            for (index, currentExercise) in workout.exercises.enumerated() {
                if index < originalWorkout.exercises.count {
                    let originalExercise = originalWorkout.exercises[index]
                    print("DEBUG: SaveWorkoutView - Comparing exercise \(index): '\(originalExercise.exercise.name)' (ID: \(originalExercise.exercise.id)) vs '\(currentExercise.exercise.name)' (ID: \(currentExercise.exercise.id))")
                    if currentExercise.exercise.id != originalExercise.exercise.id {
                        print("DEBUG: SaveWorkoutView - Exercise at index \(index) changed from '\(originalExercise.exercise.name)' to '\(currentExercise.exercise.name)'")
                        exerciseContentChanged = true
                        break
                    }
                }
            }
        }
        
        // Check if any sets were modified (added, removed, or changed)
        var setChangesDetected = false
        if workout.exercises.count == originalWorkout.exercises.count {
            for (index, currentExercise) in workout.exercises.enumerated() {
                if index < originalWorkout.exercises.count {
                    let originalExercise = originalWorkout.exercises[index]
                    
                    // Check if number of sets changed
                    if currentExercise.sets.count != originalExercise.sets.count {
                        print("DEBUG: SaveWorkoutView - Sets count changed for exercise '\(currentExercise.exercise.name)': \(originalExercise.sets.count) -> \(currentExercise.sets.count)")
                        setChangesDetected = true
                        break
                    }
                    
                    // Check if any set values changed (but don't treat individual set updates as "changes")
                    // Individual set weight/reps updates are normal workout logging, not structural changes
                    // Only detect if sets were added/removed (handled above) or if there are other structural changes
                    // Individual set value updates (weight, reps, isCompleted) are expected during workout logging
                    
                    if setChangesDetected { break }
                }
            }
        }
        
        hasWorkoutChanged = exerciseCountChanged || exerciseContentChanged || setChangesDetected
        print("DEBUG: SaveWorkoutView - exerciseContentChanged: \(exerciseContentChanged)")
        print("DEBUG: SaveWorkoutView - setChangesDetected: \(setChangesDetected)")
        print("DEBUG: SaveWorkoutView - hasWorkoutChanged: \(hasWorkoutChanged)")
        
        // Log alert message details
        let addedExercises = workout.exercises.count - originalWorkout.exercises.count
        let removedExercises = originalWorkout.exercises.count - workout.exercises.count
        print("DEBUG: Alert message - Original: \(originalWorkout.exercises.count), Current: \(workout.exercises.count)")
        print("DEBUG: Alert message - Added: \(addedExercises), Removed: \(removedExercises)")
    }
    
    private func saveWorkout() {
        // Check if workout was modified
        if hasWorkoutChanged {
            showingUpdateRoutine = true
        } else {
            finalizeWorkout()
        }
    }
    
    private func updateRoutine() {
        // Update the routine with changes
        finalizeWorkout()
    }
    
    private func keepOriginalRoutine() {
        // Keep original routine, revert to original workout and save it
        var originalWorkoutCopy = originalWorkout
        originalWorkoutCopy.name = workoutName
        
        // Use DataManager's saveWorkout method to properly update the state with original workout
        dataManager.saveWorkout(originalWorkoutCopy)
        
        // Navigate to celebration screen
        showingCelebration = true
    }
    
    private func finalizeWorkout() {
        // Create a new workout that preserves the original workout's ID but has the updated content
        var updatedWorkout = Workout(
            name: workoutName,
            exercises: workout.exercises,
            date: workout.date,
            duration: workout.duration,
            notes: workout.notes,
            isTemplate: workout.isTemplate
        )
        
        // Manually set the ID to match the original workout to ensure it updates instead of creating new
        // We need to create a workout that will be recognized as an update
        // Since we can't modify the ID after creation, we'll use a different approach
        
        // Instead, let's find the original workout in the dataManager and update it directly
        if let index = dataManager.workouts.firstIndex(where: { $0.id == originalWorkout.id }) {
            print("DEBUG: SaveWorkoutView.finalizeWorkout - Updating original workout at index \(index)")
            dataManager.workouts[index].name = workoutName
            dataManager.workouts[index].exercises = workout.exercises
            dataManager.workouts[index].duration = workout.duration
            dataManager.workouts[index].notes = workout.notes
            dataManager.workouts[index].isTemplate = workout.isTemplate
            
            // Save the updated workouts using the public method
            dataManager.saveWorkoutsDirectly(dataManager.workouts)
        } else {
            print("DEBUG: SaveWorkoutView.finalizeWorkout - Original workout not found, using saveWorkout method")
            // Fallback to the original method if we can't find the original workout
            dataManager.saveWorkout(workout)
        }
        
        // Navigate to celebration screen
        showingCelebration = true
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


#Preview {
    let sampleWorkout = Workout(
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
    )
    
    return SaveWorkoutView(workout: sampleWorkout, originalWorkout: sampleWorkout, onComplete: {
        print("Workout completed!")
    })
        .environmentObject(DataManager())
}

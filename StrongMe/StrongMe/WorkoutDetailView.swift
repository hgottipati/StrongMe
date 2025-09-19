//
//  WorkoutDetailView.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    @State private var isEditing = false
    @State private var showingStartWorkout = false
    
    // Get the current workout from DataManager to reflect updates
    private var currentWorkout: Workout {
        dataManager.workouts.first(where: { $0.id == workout.id }) ?? workout
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Workout Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentWorkout.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text(currentWorkout.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let duration = currentWorkout.duration {
                                Label(formatDuration(duration), systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let notes = currentWorkout.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(currentWorkout.exercises) { workoutExercise in
                            ExerciseDetailCard(workoutExercise: workoutExercise)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { showingStartWorkout = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { isEditing = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Workout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditWorkoutView(workout: currentWorkout)
            }
            .sheet(isPresented: $showingStartWorkout) {
                ActiveWorkoutView(workout: currentWorkout)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExerciseDetailCard: View {
    let workoutExercise: WorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workoutExercise.exercise.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(workoutExercise.sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !workoutExercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(workoutExercise.sets) { set in
                        HStack {
                            Text("Set \(set.order)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let reps = set.reps, let weight = set.weight {
                                Text("\(reps) × \(Int(weight))kg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let reps = set.reps {
                                Text("\(reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            if let notes = workoutExercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EditWorkoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    @State private var workoutName: String
    @State private var notes: String
    @State private var currentWorkout: Workout
    @State private var showingAddExercise = false
    @State private var showingExerciseOptions = false
    @State private var selectedExerciseIndex: Int = 0
    @State private var showingUpdateRoutine = false
    @State private var hasMadeChanges = false
    
    init(workout: Workout) {
        self.workout = workout
        self._workoutName = State(initialValue: workout.name)
        self._notes = State(initialValue: workout.notes ?? "")
        self._currentWorkout = State(initialValue: workout)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Workout Details Section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Workout Name", text: $workoutName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: workoutName) { _, newValue in
                                    if newValue != workout.name {
                                        hasMadeChanges = true
                                    }
                                }
                            
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                                .onChange(of: notes) { _, newValue in
                                    let currentNotes = newValue.isEmpty ? nil : newValue
                                    if currentNotes != workout.notes {
                                        hasMadeChanges = true
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    
                    // Exercises Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Exercises (\(currentWorkout.exercises.count))")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingAddExercise = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Exercise")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if currentWorkout.exercises.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("No exercises yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap 'Add Exercise' to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(currentWorkout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                        EditExerciseCard(
                                            exercise: exercise,
                                            exerciseNumber: index + 1,
                                            totalExercises: currentWorkout.exercises.count,
                                            onShowOptions: {
                                                selectedExerciseIndex = index
                                                showingExerciseOptions = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .fontWeight(.semibold)
                }
            }
            .actionSheet(isPresented: $showingExerciseOptions) {
                ActionSheet(
                    title: Text("Exercise Options"),
                    buttons: [
                        .default(Text("Replace Exercise")) { replaceExercise() },
                        .destructive(Text("Delete Exercise")) { deleteExercise() },
                        .default(Text("Move Up")) { moveExerciseUp() },
                        .default(Text("Move Down")) { moveExerciseDown() },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingAddExercise) {
                ExerciseSelectionView { exercises in
                    addSelectedExercises(exercises)
                }
                .environmentObject(dataManager)
            }
            .alert("Update workout?", isPresented: $showingUpdateRoutine) {
                Button("Update Routine") { updateRoutine() }
                Button("Keep Original Routine") { keepOriginalRoutine() }
                Button("Cancel", role: .cancel) { }
            } message: {
                let addedExercises = currentWorkout.exercises.count - workout.exercises.count
                let removedExercises = workout.exercises.count - currentWorkout.exercises.count
                
                if addedExercises > 0 {
                    Text("You added \(addedExercises) exercise\(addedExercises == 1 ? "" : "s") to this workout.")
                } else if removedExercises > 0 {
                    Text("You removed \(removedExercises) exercise\(removedExercises == 1 ? "" : "s") from this workout.")
                } else {
                    Text("You made changes to this workout (reordered exercises or changed details).")
                }
            }
        }
    }
    
    private func saveWorkout() {
        if hasMadeChanges {
            // Show update popup for changes
            showingUpdateRoutine = true
        } else {
            // No changes, silently save and dismiss
            saveWorkoutSilently()
        }
    }
    
    
    private func saveWorkoutSilently() {
        var updatedWorkout = currentWorkout
        updatedWorkout.name = workoutName
        updatedWorkout.notes = notes.isEmpty ? nil : notes
        
        dataManager.saveWorkout(updatedWorkout)
        dismiss()
    }
    
    private func updateRoutine() {
        saveWorkoutSilently()
    }
    
    private func keepOriginalRoutine() {
        // Just dismiss without saving changes
        dismiss()
    }
    
    private func addSelectedExercises(_ exercises: [Exercise]) {
        for (index, exercise) in exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                exercise: exercise,
                sets: [Set(reps: 10, weight: nil, order: 1)],
                order: currentWorkout.exercises.count + index
            )
            currentWorkout.exercises.append(workoutExercise)
        }
        hasMadeChanges = true
    }
    
    private func deleteExercise() {
        guard selectedExerciseIndex < currentWorkout.exercises.count else { return }
        currentWorkout.exercises.remove(at: selectedExerciseIndex)
        
        // Update order indices
        for (index, _) in currentWorkout.exercises.enumerated() {
            currentWorkout.exercises[index].order = index
        }
        hasMadeChanges = true
    }
    
    private func replaceExercise() {
        // For now, we'll delete and then add new exercise
        deleteExercise()
        showingAddExercise = true
    }
    
    private func moveExerciseUp() {
        guard selectedExerciseIndex > 0 else { return }
        currentWorkout.exercises.swapAt(selectedExerciseIndex, selectedExerciseIndex - 1)
        
        // Update order indices
        for (index, _) in currentWorkout.exercises.enumerated() {
            currentWorkout.exercises[index].order = index
        }
        hasMadeChanges = true
    }
    
    private func moveExerciseDown() {
        guard selectedExerciseIndex < currentWorkout.exercises.count - 1 else { return }
        currentWorkout.exercises.swapAt(selectedExerciseIndex, selectedExerciseIndex + 1)
        
        // Update order indices
        for (index, _) in currentWorkout.exercises.enumerated() {
            currentWorkout.exercises[index].order = index
        }
        hasMadeChanges = true
    }
}

struct EditExerciseCard: View {
    let exercise: WorkoutExercise
    let exerciseNumber: Int
    let totalExercises: Int
    let onShowOptions: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: exerciseIcon(for: exercise.exercise.category))
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(exercise.exercise.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if let equipment = exercise.exercise.equipment {
                            Text(equipment.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Options Button
                Button(action: onShowOptions) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Muscle Groups
            HStack {
                ForEach(Array(exercise.exercise.muscleGroups.prefix(3)), id: \.self) { muscle in
                    Text(muscle.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                }
                
                if exercise.exercise.muscleGroups.count > 3 {
                    Text("+\(exercise.exercise.muscleGroups.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Sets Summary
            HStack {
                Text("\(exercise.sets.count) sets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !exercise.sets.isEmpty {
                    let completedSets = exercise.sets.filter { $0.isCompleted }.count
                    Text("\(completedSets)/\(exercise.sets.count) completed")
                        .font(.caption)
                        .foregroundColor(completedSets == exercise.sets.count ? .green : .orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func exerciseIcon(for category: ExerciseCategory) -> String {
        switch category {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "figure.run"
        case .flexibility:
            return "figure.flexibility"
        case .sports:
            return "sportscourt.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    WorkoutDetailView(workout: Workout(
        name: "Push Day",
        exercises: [
            WorkoutExercise(
                exercise: Exercise(name: "Bench Press", category: .strength, muscleGroups: [.chest]),
                sets: [
                    Set(reps: 10, weight: 60, order: 1),
                    Set(reps: 8, weight: 70, order: 2)
                ],
                order: 1
            )
        ]
    ))
    .environmentObject(DataManager())
}

//
//  ActiveWorkoutView.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let onWorkoutComplete: (() -> Void)?
    @State private var currentWorkout: Workout {
        didSet {
            print("DEBUG: ActiveWorkoutView - currentWorkout state changed to: \(currentWorkout.id)")
            print("DEBUG: ActiveWorkoutView - currentWorkout exercises: \(currentWorkout.exercises.count)")
            for (index, exercise) in currentWorkout.exercises.enumerated() {
                print("DEBUG: ActiveWorkoutView - Exercise \(index): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("DEBUG: ActiveWorkoutView - Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                }
            }
        }
    }
    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var showingAddExercise = false
    @State private var showingDiscardConfirmation = false
    @State private var showingExerciseOptions = false
    @State private var selectedExerciseIndex: Int = 0
    @State private var showingSaveWorkout = false
    @FocusState private var isKeyboardVisible: Bool
    
    init(workout: Workout, onWorkoutComplete: (() -> Void)? = nil) {
        self.workout = workout
        self.onWorkoutComplete = onWorkoutComplete
        self._currentWorkout = State(initialValue: workout)
        
        print("DEBUG: ActiveWorkoutView.init - Received workout: \(workout.name)")
        print("DEBUG: ActiveWorkoutView.init - Workout ID: \(workout.id)")
        print("DEBUG: ActiveWorkoutView.init - Workout sets:")
        for exercise in workout.exercises {
            print("DEBUG: ActiveWorkoutView.init -   Exercise: \(exercise.exercise.name)")
            for (index, set) in exercise.sets.enumerated() {
                print("DEBUG: ActiveWorkoutView.init -     Set \(index): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
            }
        }
    }
    
    var currentExercise: WorkoutExercise? {
        guard currentExerciseIndex < currentWorkout.exercises.count else { return nil }
        return currentWorkout.exercises[currentExerciseIndex]
    }
    
    var currentSet: Set? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else { return nil }
        return exercise.sets[currentSetIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                ProgressHeaderView(
                    currentExercise: currentExerciseIndex + 1,
                    totalExercises: currentWorkout.exercises.count,
                    currentSet: currentSetIndex + 1,
                    totalSets: currentExercise?.sets.count ?? 0
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Workout Summary
                        WorkoutSummaryView(workout: currentWorkout)
                        
                        // All Exercises List
                        LazyVStack(spacing: 16) {
                            ForEach(Array(currentWorkout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    currentWorkout: currentWorkout,
                                    exerciseNumber: index + 1,
                                    totalExercises: currentWorkout.exercises.count,
                                    dataManager: dataManager,
                                    currentWorkoutId: currentWorkout.id,
                                    onAddSet: {
                                        addSetToExercise(exercise)
                                    },
                                    onEditSet: { setIndex, weight, reps in
                                        editSet(exercise, setIndex: setIndex, weight: weight, reps: reps)
                                    },
                                    onCompleteSet: { setIndex in
                                        completeSet(exercise, setIndex: setIndex)
                                    },
                                    onDeleteSet: { exercise, setIndex in
                                        deleteSet(exercise, setIndex: setIndex)
                                    },
                                    onTap: {
                                        selectExercise(index)
                                    },
                                    onShowOptions: {
                                        selectedExerciseIndex = index
                                        showingExerciseOptions = true
                                    }
                                )
                            }
                        }
                        
                        // Rest Timer
                        if restTimeRemaining > 0 {
                            RestTimerView(
                                timeRemaining: restTimeRemaining,
                                onSkip: skipRest
                            )
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if let set = currentSet, !set.isCompleted {
                                Button(action: completeCurrentSet) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Complete Set")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: addExercise) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add Exercise")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: discardWorkout) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Discard Workout")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(currentWorkout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish Workout") { 
                        finishWorkout()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .alert("Discard Workout", isPresented: $showingDiscardConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    confirmDiscardWorkout()
                }
            } message: {
                Text("Are you sure you want to discard this workout? All progress will be lost.")
            }
            .actionSheet(isPresented: $showingExerciseOptions) {
                ActionSheet(
                    title: Text("Exercise Options"),
                    buttons: [
                        .default(Text("Replace Exercise")) {
                            replaceExercise()
                        },
                        .destructive(Text("Delete Exercise")) {
                            deleteExercise()
                        },
                        .default(Text("Reorder Exercises")) {
                            reorderExercises()
                        },
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
            .sheet(isPresented: $showingSaveWorkout) {
                SaveWorkoutView(workout: currentWorkout, originalWorkout: workout, onComplete: {
                    // Call the workout completion callback to dismiss the entire flow
                    onWorkoutComplete?()
                })
                .environmentObject(dataManager)
                .onAppear {
                    print("DEBUG: ActiveWorkoutView - Opening SaveWorkoutView with currentWorkout:")
                    print("DEBUG: ActiveWorkoutView - currentWorkout ID: \(currentWorkout.id)")
                    print("DEBUG: ActiveWorkoutView - currentWorkout exercises: \(currentWorkout.exercises.count)")
                    for (index, exercise) in currentWorkout.exercises.enumerated() {
                        print("DEBUG: ActiveWorkoutView - Exercise \(index): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                        for (setIndex, set) in exercise.sets.enumerated() {
                            print("DEBUG: ActiveWorkoutView - Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                        }
                    }
                }
            }
            .onChange(of: showingSaveWorkout) { isShowing in
                if isShowing {
                    print("DEBUG: ActiveWorkoutView - showingSaveWorkout changed to true")
                    print("DEBUG: ActiveWorkoutView - currentWorkout at time of showing: \(currentWorkout.id)")
                    print("DEBUG: ActiveWorkoutView - currentWorkout exercises: \(currentWorkout.exercises.count)")
                    for (index, exercise) in currentWorkout.exercises.enumerated() {
                        print("DEBUG: ActiveWorkoutView - Exercise \(index): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                        for (setIndex, set) in exercise.sets.enumerated() {
                            print("DEBUG: ActiveWorkoutView - Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                        }
                    }
                }
            }
        }
    }
    
    private func completeCurrentSet() {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else { return }
        
        var updatedExercise = exercise
        updatedExercise.sets[currentSetIndex].isCompleted = true
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[currentExerciseIndex] = updatedExercise
        currentWorkout = updatedWorkout
        
        // Start rest timer
        startRestTimer()
        
        // Move to next set
        nextSet()
    }
    
    private func completeSet(_ exercise: WorkoutExercise, setIndex: Int) {
        guard let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < currentWorkout.exercises[exerciseIndex].sets.count else { return }
        
        // Use the current workout's exercise data (which has the updated weight/reps)
        var updatedWorkout = currentWorkout
        let set = updatedWorkout.exercises[exerciseIndex].sets[setIndex]
        
        print("DEBUG: ActiveWorkoutView.completeSet - Set before completion: weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
        
        // Set isCompleted to true if the set has valid weight and reps data
        updatedWorkout.exercises[exerciseIndex].sets[setIndex].isCompleted = (set.weight ?? 0) > 0 && (set.reps ?? 0) > 0
        
        print("DEBUG: ActiveWorkoutView.completeSet - Setting isCompleted to: \(updatedWorkout.exercises[exerciseIndex].sets[setIndex].isCompleted)")
        
        currentWorkout = updatedWorkout
    }
    
    private func editSet(_ exercise: WorkoutExercise, setIndex: Int, weight: Double, reps: Int) {
        print("DEBUG: ActiveWorkoutView.editSet - Exercise: \(exercise.exercise.name), SetIndex: \(setIndex), Weight: \(weight), Reps: \(reps)")
        
        guard let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < exercise.sets.count else { 
            print("DEBUG: ActiveWorkoutView.editSet - ERROR: Could not find exercise or setIndex out of bounds")
            return 
        }
        
        var updatedExercise = exercise
        updatedExercise.sets[setIndex].weight = weight
        updatedExercise.sets[setIndex].reps = reps
        updatedExercise.sets[setIndex].isCompleted = true // Set as completed when data is entered
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[exerciseIndex] = updatedExercise
        
        print("DEBUG: ActiveWorkoutView.editSet - About to update currentWorkout")
        print("DEBUG: ActiveWorkoutView.editSet - currentWorkout before update: \(currentWorkout.id)")
        print("DEBUG: ActiveWorkoutView.editSet - updatedWorkout ID: \(updatedWorkout.id)")
        
        currentWorkout = updatedWorkout
        
        print("DEBUG: ActiveWorkoutView.editSet - currentWorkout after update: \(currentWorkout.id)")
        print("DEBUG: ActiveWorkoutView.editSet - currentWorkout.exercises.count: \(currentWorkout.exercises.count)")
        
        print("DEBUG: ActiveWorkoutView.editSet - Updated workout. Set \(setIndex) now has weight=\(weight), reps=\(reps)")
        print("DEBUG: ActiveWorkoutView.editSet - currentWorkout now has \(currentWorkout.exercises.count) exercises")
        for (exIndex, ex) in currentWorkout.exercises.enumerated() {
            print("DEBUG: ActiveWorkoutView.editSet - Exercise \(exIndex): \(ex.exercise.name) - Sets: \(ex.sets.count)")
            for (sIndex, s) in ex.sets.enumerated() {
                print("DEBUG: ActiveWorkoutView.editSet - Set \(sIndex): weight=\(s.weight ?? 0), reps=\(s.reps ?? 0)")
            }
        }
    }
    
    private func deleteSet(_ exercise: WorkoutExercise, setIndex: Int) {
        print("DEBUG: ActiveWorkoutView.deleteSet - Exercise: \(exercise.exercise.name), SetIndex: \(setIndex)")
        print("DEBUG: ActiveWorkoutView.deleteSet - Current workout ID: \(currentWorkout.id)")
        print("DEBUG: ActiveWorkoutView.deleteSet - Exercise has \(exercise.sets.count) sets")
        
        guard let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < exercise.sets.count,
              exercise.sets.count > 1 else { // Don't allow deleting the last set
            print("DEBUG: ActiveWorkoutView.deleteSet - ERROR: Could not find exercise, setIndex out of bounds, or trying to delete last set")
            return 
        }
        
        var updatedExercise = exercise
        updatedExercise.sets.remove(at: setIndex)
        
        // Update the order of remaining sets
        for (index, set) in updatedExercise.sets.enumerated() {
            updatedExercise.sets[index].order = index + 1
        }
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[exerciseIndex] = updatedExercise
        
        print("DEBUG: ActiveWorkoutView.deleteSet - Deleted set \(setIndex) from exercise '\(exercise.exercise.name)'")
        print("DEBUG: ActiveWorkoutView.deleteSet - Remaining sets: \(updatedExercise.sets.count)")
        print("DEBUG: ActiveWorkoutView.deleteSet - Updated workout ID: \(updatedWorkout.id)")
        
        currentWorkout = updatedWorkout
        
        print("DEBUG: ActiveWorkoutView.deleteSet - After update, currentWorkout has \(currentWorkout.exercises.count) exercises")
        for (exIndex, ex) in currentWorkout.exercises.enumerated() {
            print("DEBUG: ActiveWorkoutView.deleteSet - Exercise \(exIndex): \(ex.exercise.name) - Sets: \(ex.sets.count)")
        }
    }
    
    private func selectExercise(_ index: Int) {
        guard index < currentWorkout.exercises.count else { return }
        currentExerciseIndex = index
        currentSetIndex = 0
    }
    
    private func addSetToExercise(_ exercise: WorkoutExercise) {
        guard let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        
        let newSet = Set(
            reps: 10,
            weight: nil,
            order: exercise.sets.count + 1
        )
        
        var updatedExercise = exercise
        updatedExercise.sets.append(newSet)
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[exerciseIndex] = updatedExercise
        currentWorkout = updatedWorkout
    }
    
    private func nextSet() {
        guard let exercise = currentExercise else { return }
        
        if currentSetIndex < exercise.sets.count - 1 {
            currentSetIndex += 1
        } else {
            nextExercise()
        }
    }
    
    private func nextExercise() {
        if currentExerciseIndex < currentWorkout.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
        }
    }
    
    private func startRestTimer() {
        restTimeRemaining = 90 // Default 90 seconds
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                restTimer?.invalidate()
                restTimer = nil
            }
        }
    }
    
    private func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
    }
    
    private func finishWorkout() {
        dataManager.endWorkout()
        showingSaveWorkout = true
    }
    
    private func addExercise() {
        showingAddExercise = true
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
    }
    
    private func discardWorkout() {
        showingDiscardConfirmation = true
    }
    
    private func confirmDiscardWorkout() {
        dataManager.endWorkout()
        dismiss()
    }
    
    private func deleteExercise() {
        guard selectedExerciseIndex < currentWorkout.exercises.count else { return }
        currentWorkout.exercises.remove(at: selectedExerciseIndex)
        
        // Adjust current exercise index if needed
        if currentExerciseIndex >= selectedExerciseIndex {
            currentExerciseIndex = max(0, currentExerciseIndex - 1)
        }
        
        // Reset set index
        currentSetIndex = 0
    }
    
    private func replaceExercise() {
        // Navigate to exercises view for replacement
        showingAddExercise = true
    }
    
    private func reorderExercises() {
        // This would show a reorder interface
        // For now, we'll implement a simple swap with next exercise
        guard selectedExerciseIndex < currentWorkout.exercises.count - 1 else { return }
        currentWorkout.exercises.swapAt(selectedExerciseIndex, selectedExerciseIndex + 1)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WorkoutSummaryView: View {
    let workout: Workout
    
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
        HStack(spacing: 20) {
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
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(totalSets)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ProgressHeaderView: View {
    let currentExercise: Int
    let totalExercises: Int
    let currentSet: Int
    let totalSets: Int
    
    private var progressValue: Double {
        guard totalExercises > 0 && totalSets > 0 else { return 0 }
        return Double(currentExercise - 1) + Double(currentSet - 1) / Double(totalSets)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Exercise \(currentExercise) of \(totalExercises)")
                    .font(.headline)
                Spacer()
                Text("Set \(currentSet) of \(totalSets)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if totalExercises > 0 {
                SwiftUI.ProgressView(value: progressValue, total: Double(totalExercises))
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct ExerciseInfoCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(exercise.category.rawValue, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let equipment = exercise.equipment {
                    Label(equipment.rawValue, systemImage: "wrench.and.screwdriver")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if !exercise.muscleGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(exercise.muscleGroups, id: \.self) { muscleGroup in
                            Text(muscleGroup.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SetRowView: View {
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    let set: Set
    let setIndex: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let exercise: Exercise
    let dataManager: DataManager
    let currentWorkoutId: UUID
    let totalSetsCount: Int
    let onComplete: () -> Void
    let onEdit: (Int, Double, Int) -> Void
    let onDelete: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(set.order)")
                .font(.headline)
                .frame(width: 30)
            
            // Previous Performance
            Text(previousPerformance)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weight Input
            TextField("0", text: $weight)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 50)
                .focused($isWeightFocused)
            
            // Reps Input
            TextField("0", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 50)
                .focused($isRepsFocused)
            
            // Complete Button
            Button(action: {
                print("DEBUG: SetRowView - Complete button tapped. Weight: '\(weight)', Reps: '\(reps)', SetIndex: \(setIndex)")
                if let weightValue = Double(weight), let repsValue = Int(reps) {
                    print("DEBUG: SetRowView - Calling onEdit with setIndex: \(setIndex), weight: \(weightValue), reps: \(repsValue)")
                    onEdit(setIndex, weightValue, repsValue)
                    // onComplete() removed - editSet() now handles setting isCompleted
                } else {
                    print("DEBUG: SetRowView - ERROR: Could not convert weight '\(weight)' or reps '\(reps)' to numbers")
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .disabled(weight.isEmpty && reps.isEmpty)
            
            // Delete Button (only show if more than 1 set)
            if totalSetsCount > 1 {
                Button(action: {
                    onDelete(setIndex)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCompleted ? Color.green.opacity(0.2) : (isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6)))
        .cornerRadius(8)
        .onAppear {
            // Only update fields if there's actual saved data, don't clear on initial load
            if let setWeight = set.weight, setWeight > 0 {
                weight = String(Int(setWeight))
            }
            if let setReps = set.reps, setReps > 0 {
                reps = String(setReps)
            } else {
                reps = "10" // Default reps
            }
        }
        .onChange(of: set.weight) { _ in
            updateFieldsFromSet()
        }
        .onChange(of: set.reps) { _ in
            updateFieldsFromSet()
        }
    }
    
    private func updateFieldsFromSet() {
        print("DEBUG: SetRowView.updateFieldsFromSet - Called for set \(set.order)")
        print("DEBUG: SetRowView.updateFieldsFromSet - set.weight: \(set.weight ?? 0), set.reps: \(set.reps ?? 0), set.isCompleted: \(set.isCompleted)")
        print("DEBUG: SetRowView.updateFieldsFromSet - Current weight field: '\(weight)', reps field: '\(reps)'")
        
        // Only update weight if we have a valid saved weight
        if let setWeight = set.weight, setWeight > 0 {
            print("DEBUG: SetRowView.updateFieldsFromSet - Setting weight to saved value: \(setWeight)")
            weight = String(Int(setWeight))
        } else {
            // Never clear the weight field - preserve user input
            print("DEBUG: SetRowView.updateFieldsFromSet - Keeping current weight field value: '\(weight)'")
        }
        
        // Only update reps if we have a valid saved reps value
        if let setReps = set.reps, setReps > 0 {
            print("DEBUG: SetRowView.updateFieldsFromSet - Setting reps to saved value: \(setReps)")
            reps = String(setReps)
        } else {
            // Never clear the reps field - preserve user input or use default
            if reps.isEmpty {
                print("DEBUG: SetRowView.updateFieldsFromSet - Setting reps to default: 10")
                reps = "10" // Default reps only if field is empty
            } else {
                print("DEBUG: SetRowView.updateFieldsFromSet - Keeping current reps field value: '\(reps)'")
            }
        }
        
        print("DEBUG: SetRowView.updateFieldsFromSet - Final weight field: '\(weight)', reps field: '\(reps)'")
    }
    
    private var previousPerformance: String {
        // Get all workouts that contain this exercise
        let allWorkouts = dataManager.workouts
        print("DEBUG: Total workouts in dataManager: \(allWorkouts.count)")
        
        let today = Calendar.current.startOfDay(for: Date())
        print("DEBUG: Today's date: \(today)")
        
        // Log all workouts for debugging
        for (index, workout) in allWorkouts.enumerated() {
            print("DEBUG: Workout \(index): \(workout.name) - Date: \(workout.date), IsTemplate: \(workout.isTemplate)")
            for exerciseInWorkout in workout.exercises {
                print("DEBUG:   - Exercise: \(exerciseInWorkout.exercise.name) (ID: \(exerciseInWorkout.exercise.id)) - Sets: \(exerciseInWorkout.sets.count)")
                for (setIndex, set) in exerciseInWorkout.sets.enumerated() {
                    print("DEBUG:     Set \(setIndex + 1): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), order=\(set.order)")
                }
            }
        }
        
        let recentWorkouts = allWorkouts
            .filter { workout in
                // Exclude templates and the current workout (by comparing workout IDs)
                let isNotTemplate = !workout.isTemplate
                let isNotCurrentWorkout = workout.id != currentWorkoutId
                // Use name-based matching instead of ID matching since IDs are different for each workout
                let hasExercise = workout.exercises.contains { $0.exercise.name == exercise.name }
                
                print("DEBUG: Workout '\(workout.name)': isNotTemplate=\(isNotTemplate), isNotCurrentWorkout=\(isNotCurrentWorkout), hasExercise=\(hasExercise)")
                
                return isNotTemplate && isNotCurrentWorkout && hasExercise
            }
            .sorted { $0.date > $1.date }
        
        print("DEBUG: Previous performance for \(exercise.name) (ID: \(exercise.id))")
        print("DEBUG: Found \(recentWorkouts.count) recent workouts with this exercise")
        
        // Try to find the most recent workout with this exact exercise
        for workout in recentWorkouts {
            print("DEBUG: Checking workout: \(workout.name) on \(workout.date)")
            
            if let exerciseInWorkout = workout.exercises.first(where: { $0.exercise.name == exercise.name }) {
                print("DEBUG: Found matching exercise in workout with \(exerciseInWorkout.sets.count) sets")
                // Log all sets in this exercise for debugging
                for (setIndex, set) in exerciseInWorkout.sets.enumerated() {
                    print("DEBUG:   Set \(setIndex + 1): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), order=\(set.order)")
                }
                
                // Find the set that corresponds to the current set number
                let currentSetNumber = set.order
                if let previousSet = exerciseInWorkout.sets.first(where: { $0.order == currentSetNumber }) {
                    print("DEBUG: Previous set \(currentSetNumber) - weight: \(previousSet.weight ?? 0), reps: \(previousSet.reps ?? 0)")
                    
                    // Skip sets that have no actual data (weight: 0 and reps: 0 or nil)
                    if let reps = previousSet.reps, reps > 0 {
                        if let weight = previousSet.weight, weight > 0 {
                            // Weighted exercise
                            let result = "\(Int(weight))lbs × \(reps)"
                            print("DEBUG: Returning previous performance: \(result)")
                            return result
                        } else {
                            // Bodyweight exercise - show both weight (0) and reps
                            let result = "0lbs × \(reps)"
                            print("DEBUG: Returning previous performance (bodyweight): \(result)")
                            return result
                        }
                    } else {
                        print("DEBUG: Previous set has no valid data (reps: \(previousSet.reps ?? 0), weight: \(previousSet.weight ?? 0))")
                    }
                } else {
                    print("DEBUG: No previous set found for set number \(currentSetNumber)")
                }
            } else {
                print("DEBUG: No matching exercise found in this workout")
            }
        }
        
        // Fallback: if no exact exercise match, try to find by name
        print("DEBUG: No exact exercise match found, trying name-based matching")
        for workout in recentWorkouts {
            if let exerciseInWorkout = workout.exercises.first(where: { $0.exercise.name == exercise.name }) {
                print("DEBUG: Found exercise by name: \(exerciseInWorkout.exercise.name)")
                
                let currentSetNumber = set.order
                if let previousSet = exerciseInWorkout.sets.first(where: { $0.order == currentSetNumber }) {
                    if let reps = previousSet.reps {
                        if let weight = previousSet.weight {
                            let result = "\(Int(weight))lbs × \(reps)"
                            print("DEBUG: Returning previous performance (by name): \(result)")
                            return result
                        } else {
                            let result = "0lbs × \(reps)"
                            print("DEBUG: Returning previous performance (by name, bodyweight): \(result)")
                            return result
                        }
                    }
                }
            }
        }
        
        print("DEBUG: No previous performance found, returning '-'")
        return "-"
    }
}

struct RestTimerView: View {
    let timeRemaining: TimeInterval
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Rest Time")
                .font(.headline)
            
            Text(formatTime(timeRemaining))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Button("Skip Rest", action: onSkip)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct WorkoutCompleteView: View {
    let workout: Workout
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Workout Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Great job! You've completed your workout.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Finish", action: onFinish)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding()
    }
}

struct ExerciseCard: View {
    let exercise: WorkoutExercise
    let currentWorkout: Workout
    let exerciseNumber: Int
    let totalExercises: Int
    let dataManager: DataManager
    let currentWorkoutId: UUID
    let onAddSet: () -> Void
    let onEditSet: (Int, Double, Int) -> Void
    let onCompleteSet: (Int) -> Void
    let onDeleteSet: (WorkoutExercise, Int) -> Void
    let onTap: () -> Void
    let onShowOptions: () -> Void
    
    // Get the current exercise data from the current workout
    private var currentExercise: WorkoutExercise {
        currentWorkout.exercises.first { $0.id == exercise.id } ?? exercise
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
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
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: exerciseIcon(for: exercise.exercise.category))
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exercise.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        HStack {
                            HStack {
                                Image(systemName: "diamond.fill")
                                    .font(.caption)
                                Text(exercise.exercise.category.rawValue)
                                    .font(.caption)
                            }
                            
                            HStack {
                                Image(systemName: "wrench.fill")
                                    .font(.caption)
                                Text(exercise.exercise.equipment?.rawValue ?? "Bodyweight")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onShowOptions) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Muscle Group Tags (Static, not scrollable)
                HStack(spacing: 8) {
                    ForEach(exercise.exercise.muscleGroups, id: \.self) { muscle in
                        Text(muscle.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            
                // Notes Section
                Text("Add notes here...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                
                // Rest Timer
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Rest Timer: OFF")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Sets Table
                VStack(spacing: 8) {
                    // Table Headers (no background box)
                    HStack(spacing: 12) {
                        Text("SET")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 30)
                        
                        Text("PREVIOUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "dumbbell")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("LBS")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 60)
                        
                        Text("REPS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 50)
                        
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    // Sets Rows
                    VStack(spacing: 8) {
                        ForEach(Array(currentExercise.sets.enumerated()), id: \.element.id) { index, set in
                            SetRowView(
                                set: set,
                                setIndex: index,
                                isCurrent: false, // No current set highlighting
                                isCompleted: set.isCompleted,
                                exercise: exercise.exercise,
                                dataManager: dataManager,
                                currentWorkoutId: currentWorkoutId,
                                totalSetsCount: currentExercise.sets.count,
                                onComplete: {
                                    onCompleteSet(index)
                                },
                                onEdit: { setOrder, weight, reps in
                                    onEditSet(index, weight, reps)
                                },
                                onDelete: { setIndex in
                                    onDeleteSet(exercise, setIndex)
                                }
                            )
                        }
                    }
                    
                    // Add Set Button
                    Button(action: onAddSet) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
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
    ActiveWorkoutView(workout: Workout(
        name: "Push Day",
        exercises: [
            WorkoutExercise(
                exercise: Exercise(name: "Bench Press", category: .strength, muscleGroups: [.chest]),
                sets: [
                    Set(reps: 10, weight: 60, order: 1),
                    Set(reps: 8, weight: 70, order: 2),
                    Set(reps: 6, weight: 80, order: 3)
                ],
                order: 1
            )
        ]
    ))
    .environmentObject(DataManager())
}


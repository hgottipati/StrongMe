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
    @State private var currentWorkout: Workout
    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var showingEndWorkout = false
    @State private var showingAddExercise = false
    @State private var showingDiscardConfirmation = false
    @State private var showingExerciseOptions = false
    @State private var selectedExerciseIndex: Int = 0
    @State private var showingSaveWorkout = false
    @FocusState private var isKeyboardVisible: Bool
    
    init(workout: Workout) {
        self.workout = workout
        self._currentWorkout = State(initialValue: workout)
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
                                    exerciseNumber: index + 1,
                                    totalExercises: currentWorkout.exercises.count,
                                    onAddSet: {
                                        addSetToExercise(exercise)
                                    },
                                    onEditSet: { setIndex, weight, reps in
                                        editSet(exercise, setIndex: setIndex, weight: weight, reps: reps)
                                    },
                                    onCompleteSet: { setIndex in
                                        completeSet(exercise, setIndex: setIndex)
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
                            
                            Button(action: finishWorkout) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Finish Workout")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(currentWorkout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        showingEndWorkout = true
                    }
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
            .alert("End Workout", isPresented: $showingEndWorkout) {
                Button("Cancel", role: .cancel) { }
                Button("End Workout", role: .destructive) {
                    finishWorkout()
                }
            } message: {
                Text("Are you sure you want to end this workout? Your progress will be saved.")
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
                SaveWorkoutView(workout: currentWorkout, originalWorkout: workout)
                    .environmentObject(dataManager)
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
              setIndex < exercise.sets.count else { return }
        
        var updatedExercise = exercise
        updatedExercise.sets[setIndex].isCompleted.toggle()
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[exerciseIndex] = updatedExercise
        currentWorkout = updatedWorkout
    }
    
    private func editSet(_ exercise: WorkoutExercise, setIndex: Int, weight: Double, reps: Int) {
        guard let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < exercise.sets.count else { return }
        
        var updatedExercise = exercise
        updatedExercise.sets[setIndex].weight = weight
        updatedExercise.sets[setIndex].reps = reps
        
        var updatedWorkout = currentWorkout
        updatedWorkout.exercises[exerciseIndex] = updatedExercise
        currentWorkout = updatedWorkout
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
        .padding()
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
    let isCurrent: Bool
    let isCompleted: Bool
    let onComplete: () -> Void
    let onEdit: (Int, Double, Int) -> Void
    
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
            HStack {
                Image(systemName: "dumbbell")
                    .foregroundColor(.blue)
                TextField("0", text: $weight)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                    .focused($isWeightFocused)
            }
            
            // Reps Input
            TextField("0", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 50)
                .focused($isRepsFocused)
            
            // Complete Button
            Button(action: {
                if let weightValue = Double(weight), let repsValue = Int(reps) {
                    onEdit(set.order, weightValue, repsValue)
                    onComplete()
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .disabled(weight.isEmpty || reps.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
        .onAppear {
            if let setWeight = set.weight, let setReps = set.reps {
                weight = String(Int(setWeight))
                reps = String(setReps)
            } else {
                // Default reps to 10 if not set
                reps = "10"
            }
        }
    }
    
    private var previousPerformance: String {
        if let reps = set.reps, let weight = set.weight {
            return "\(Int(weight))lbs × \(reps)"
        }
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
    let exerciseNumber: Int
    let totalExercises: Int
    let onAddSet: () -> Void
    let onEditSet: (Int, Double, Int) -> Void
    let onCompleteSet: (Int) -> Void
    let onTap: () -> Void
    let onShowOptions: () -> Void
    
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
                    // Table Headers
                    HStack(spacing: 12) {
                        Text("SET")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 30)
                        
                        Text("PREVIOUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Image(systemName: "dumbbell")
                                .foregroundColor(.blue)
                            Text("LBS")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 50)
                        
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
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Sets Rows
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetRowView(
                            set: set,
                            isCurrent: false, // No current set highlighting
                            isCompleted: set.isCompleted,
                            onComplete: {
                                onCompleteSet(index)
                            },
                            onEdit: { setOrder, weight, reps in
                                onEditSet(index, weight, reps)
                            }
                        )
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
        .padding()
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


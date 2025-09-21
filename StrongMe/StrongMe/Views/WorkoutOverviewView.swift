import SwiftUI

struct WorkoutOverviewView: View {
    let workout: Workout
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndWorkout = false
    
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
    
    private var completedSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    private var workoutDuration: TimeInterval {
        Date().timeIntervalSince(workout.date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Summary Header
                    WorkoutSummaryHeader(
                        duration: workoutDuration,
                        volume: totalVolume,
                        sets: totalSets
                    )
                    
                    // Exercises List
                    LazyVStack(spacing: 16) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseOverviewCard(
                                exercise: exercise,
                                exerciseNumber: index + 1,
                                totalExercises: workout.exercises.count,
                                onAddSet: {
                                    addSetToExercise(exercise)
                                },
                                onEditSet: { setIndex, weight, reps in
                                    editSet(exercise, setIndex: setIndex, weight: weight, reps: reps)
                                },
                                onCompleteSet: { setIndex in
                                    completeSet(exercise, setIndex: setIndex)
                                }
                            )
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            // Navigate to add exercise
                        }) {
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
                        
                        HStack(spacing: 16) {
                            Button("Settings") {
                                // Settings action
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            
                            Button("Discard Workout") {
                                showingEndWorkout = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Log Workout")
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
                            Image(systemName: "clock")
                        }
                        
                        Button("Finish") {
                            finishWorkout()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
            .alert("Discard Workout", isPresented: $showingEndWorkout) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            }
        }
    }
    
    private func addSetToExercise(_ exercise: WorkoutExercise) {
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        
        let newSet = Set(
            reps: 10,
            weight: nil,
            order: exercise.sets.count + 1
        )
        
        var updatedWorkout = workout
        updatedWorkout.exercises[exerciseIndex].sets.append(newSet)
        
        // Update the workout in data manager
        if let workoutIndex = dataManager.workouts.firstIndex(where: { $0.id == workout.id }) {
            dataManager.workouts[workoutIndex] = updatedWorkout
        }
    }
    
    private func editSet(_ exercise: WorkoutExercise, setIndex: Int, weight: Double, reps: Int) {
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < exercise.sets.count else { return }
        
        var updatedWorkout = workout
        updatedWorkout.exercises[exerciseIndex].sets[setIndex].weight = weight
        updatedWorkout.exercises[exerciseIndex].sets[setIndex].reps = reps
        
        // Update the workout in data manager
        if let workoutIndex = dataManager.workouts.firstIndex(where: { $0.id == workout.id }) {
            dataManager.workouts[workoutIndex] = updatedWorkout
        }
    }
    
    private func completeSet(_ exercise: WorkoutExercise, setIndex: Int) {
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exercise.id }),
              setIndex < exercise.sets.count else { return }
        
        var updatedWorkout = workout
        updatedWorkout.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        
        // Update the workout in data manager
        if let workoutIndex = dataManager.workouts.firstIndex(where: { $0.id == workout.id }) {
            dataManager.workouts[workoutIndex] = updatedWorkout
        }
    }
    
    private func finishWorkout() {
        dataManager.endWorkout()
        dismiss()
    }
}

struct WorkoutSummaryHeader: View {
    let duration: TimeInterval
    let volume: Double
    let sets: Int
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDuration(duration))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(volume)) lbs")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(sets)")
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

struct ExerciseOverviewCard: View {
    let exercise: WorkoutExercise
    let exerciseNumber: Int
    let totalExercises: Int
    let onAddSet: () -> Void
    let onEditSet: (Int, Double, Int) -> Void
    let onCompleteSet: (Int) -> Void
    
    @State private var weightInputs: [String] = []
    @State private var repsInputs: [String] = []
    
    var body: some View {
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
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Muscle Group Tag
            if let primaryMuscle = exercise.exercise.muscleGroups.first {
                Text(primaryMuscle.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
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
                    SetOverviewRow(
                        set: set,
                        setIndex: index,
                        weightInput: Binding(
                            get: { weightInputs.indices.contains(index) ? weightInputs[index] : "" },
                            set: { weightInputs.indices.contains(index) ? weightInputs[index] = $0 : () }
                        ),
                        repsInput: Binding(
                            get: { repsInputs.indices.contains(index) ? repsInputs[index] : "" },
                            set: { repsInputs.indices.contains(index) ? repsInputs[index] = $0 : () }
                        ),
                        onEdit: { weight, reps in
                            onEditSet(index, weight, reps)
                        },
                        onComplete: {
                            onCompleteSet(index)
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            initializeInputs()
        }
    }
    
    private func initializeInputs() {
        weightInputs = exercise.sets.map { set in
            if let weight = set.weight {
                return String(Int(weight))
            }
            return ""
        }
        
        repsInputs = exercise.sets.map { set in
            if let reps = set.reps {
                return String(reps)
            }
            return "10" // Default to 10
        }
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

struct SetOverviewRow: View {
    let set: Set
    let setIndex: Int
    @Binding var weightInput: String
    @Binding var repsInput: String
    let onEdit: (Double, Int) -> Void
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(set.order)")
                .font(.subheadline)
                .frame(width: 30)
            
            // Previous Performance
            Text(previousPerformance)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weight Input
            TextField("0", text: $weightInput)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 50)
                .onChange(of: weightInput) { _, newValue in
                    if let weight = Double(newValue), let reps = Int(repsInput) {
                        onEdit(weight, reps)
                    }
                }
            
            // Reps Input
            TextField("10", text: $repsInput)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 50)
                .onChange(of: repsInput) { _, newValue in
                    if let weight = Double(weightInput), let reps = Int(newValue) {
                        onEdit(weight, reps)
                    }
                }
            
            // Complete Button
            Button(action: onComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .gray)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(set.isCompleted ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private var previousPerformance: String {
        // This should show historical data, not current set data
        // For now, return "-" since this view should be replaced with ActiveWorkoutView
        return "-"
    }
}

#Preview {
    WorkoutOverviewView(workout: Workout(
        name: "Sample Workout",
        exercises: [
            WorkoutExercise(
                exercise: Exercise(
                    name: "Bench Press (Barbell)",
                    category: .strength,
                    muscleGroups: [.chest],
                    equipment: .barbell
                ),
                sets: [
                    Set(reps: 10, weight: 135, isCompleted: true, order: 1),
                    Set(reps: 10, weight: 135, isCompleted: false, order: 2)
                ],
                order: 0
            )
        ]
    ))
    .environmentObject(DataManager())
}

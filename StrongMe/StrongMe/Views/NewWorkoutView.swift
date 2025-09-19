import SwiftUI

struct NewWorkoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var workoutName = ""
    @State private var selectedExercises: Swift.Set<Exercise> = []
    @State private var showingExerciseLibrary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    TextField("Workout Name", text: $workoutName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    HStack {
                        Text("\(selectedExercises.count) exercises")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Add Exercise") {
                            showingExerciseLibrary = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Exercises List
                if selectedExercises.isEmpty {
                    EmptyExercisesView {
                        showingExerciseLibrary = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(selectedExercises), id: \.id) { exercise in
                                SelectedExerciseRow(
                                    exercise: exercise,
                                    onRemove: {
                                        selectedExercises.remove(exercise)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Create Button
                VStack {
                    Divider()
                    
                    Button(action: createWorkout) {
                        Text("Create Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(workoutName.isEmpty || selectedExercises.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(workoutName.isEmpty || selectedExercises.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExerciseLibrary) {
                ExerciseLibraryView(selectedExercises: $selectedExercises)
                    .environmentObject(dataManager)
            }
        }
    }
    
    private func createWorkout() {
        let workout = Workout(
            name: workoutName,
            exercises: selectedExercises.map { exercise in
                WorkoutExercise(
                    exercise: exercise,
                    sets: [Set(reps: nil, weight: nil, order: 1)],
                    order: 0
                )
            },
            date: Date()
        )
        
        dataManager.workouts.append(workout)
        dismiss()
    }
}

struct EmptyExercisesView: View {
    let onAddExercise: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Exercises Added")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add exercises to create your workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddExercise) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Exercise")
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

struct SelectedExerciseRow: View {
    let exercise: Exercise
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: exerciseIcon(for: exercise.category))
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(exercise.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(exercise.muscleGroups.prefix(2), id: \.self) { muscleGroup in
                        Text(muscleGroup.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                    
                    if exercise.muscleGroups.count > 2 {
                        Text("+\(exercise.muscleGroups.count - 2)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
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

struct ExerciseLibraryView: View {
    @Binding var selectedExercises: Swift.Set<Exercise>
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    
    private var filteredExercises: [Exercise] {
        var exercises = dataManager.exerciseLibrary
        
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroups.contains { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Exercises List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseLibraryRow(
                                exercise: exercise,
                                isSelected: selectedExercises.contains(exercise),
                                onToggle: {
                                    if selectedExercises.contains(exercise) {
                                        selectedExercises.remove(exercise)
                                    } else {
                                        selectedExercises.insert(exercise)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseLibraryRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exerciseIcon(for: exercise.category))
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(exercise.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(exercise.muscleGroups.prefix(2), id: \.self) { muscleGroup in
                            Text(muscleGroup.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        
                        if exercise.muscleGroups.count > 2 {
                            Text("+\(exercise.muscleGroups.count - 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
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
    NewWorkoutView()
        .environmentObject(DataManager())
}

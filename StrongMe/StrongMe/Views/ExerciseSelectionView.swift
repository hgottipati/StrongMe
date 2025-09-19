import SwiftUI

struct ExerciseSelectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedExercises: Swift.Set<Exercise> = []
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    
    let onExercisesSelected: ([Exercise]) -> Void
    
    var filteredExercises: [Exercise] {
        var exercises = dataManager.exerciseLibrary
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Exercise List
                List {
                    ForEach(filteredExercises) { exercise in
                        ExerciseSelectionRow(
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
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedExercises.count))") {
                        onExercisesSelected(Array(selectedExercises))
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: exerciseIcon(for: exercise.category))
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(exercise.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if let equipment = exercise.equipment {
                            Text(equipment.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Muscle Groups
                    HStack {
                        ForEach(Array(exercise.muscleGroups.prefix(3)), id: \.self) { muscle in
                            Text(muscle.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                        
                        if exercise.muscleGroups.count > 3 {
                            Text("+\(exercise.muscleGroups.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ExerciseSelectionView { exercises in
        print("Selected \(exercises.count) exercises")
    }
    .environmentObject(DataManager())
}

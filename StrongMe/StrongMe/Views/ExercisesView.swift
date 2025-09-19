import SwiftUI

struct ExercisesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var selectedExercise: Exercise? = nil
    
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
        
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroups.contains(muscleGroup) }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    selectedMuscleGroup: $selectedMuscleGroup
                )
                
                // Exercises List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseCardView(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercises")
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct SearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedCategory: ExerciseCategory?
    @Binding var selectedMuscleGroup: MuscleGroup?
    
    var body: some View {
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
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Category Filter
                    FilterChip(
                        title: "All Categories",
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
            
            // Muscle Group Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Muscles",
                        isSelected: selectedMuscleGroup == nil,
                        action: { selectedMuscleGroup = nil }
                    )
                    
                    ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                        FilterChip(
                            title: muscleGroup.rawValue,
                            isSelected: selectedMuscleGroup == muscleGroup,
                            action: { selectedMuscleGroup = muscleGroup }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ExerciseCardView: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: exerciseIcon(for: exercise.category))
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(exercise.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(exercise.muscleGroups.prefix(3), id: \.self) { muscleGroup in
                            Text(muscleGroup.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        if exercise.muscleGroups.count > 3 {
                            Text("+\(exercise.muscleGroups.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
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
    ExercisesView()
        .environmentObject(DataManager())
}

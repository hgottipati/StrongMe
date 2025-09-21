import SwiftUI
import UniformTypeIdentifiers

enum WorkoutTab: String, CaseIterable {
    case adhoc = "Adhoc"
    case routines = "Routines"
    
    var displayName: String {
        return self.rawValue
    }
}

struct WorkoutsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewWorkout = false
    @State private var selectedWorkout: Workout? = nil
    @State private var showingWorkoutOverview: Workout? = nil
    @State private var showingShareSheet = false
    @State private var workoutToShare: Workout?
    
    // Drag and drop state
    @State private var draggedWorkout: Workout? = nil
    @State private var dragOffset: CGSize = .zero
    
    // Tab state
    @State private var selectedTab: WorkoutTab = .adhoc
    
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
        
        // Provide haptic feedback for successful reordering
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // Perform the move with smooth animation
        withAnimation(.easeInOut(duration: 0.3)) {
            dataManager.workouts.move(fromOffsets: source, toOffset: destination)
        }
        
        // Save the changes
        dataManager.saveWorkoutsDirectly(dataManager.workouts)
        print("DEBUG: WorkoutsView - Workouts reordered successfully")
    }
    
    private func startWorkout(_ workout: Workout) {
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
                                reps: set.reps,
                                weight: set.weight,
                                duration: set.duration,
                                distance: set.distance,
                                restTime: set.restTime,
                                isCompleted: false, // Reset completion state
                                order: set.order
                            )
                        },
                        order: exercise.order
                    )
                },
                date: Date(),
                duration: 0,
                notes: recentWorkout.notes,
                isTemplate: false
            )
            
            print("DEBUG: WorkoutsView - Created new workout based on recent workout with ID: \(newWorkout.id)")
            
            // Start the workout session with the new workout
            dataManager.startWorkout(newWorkout)
            
            // Navigate to active workout view
            showingWorkoutOverview = newWorkout
        } else {
            // Create a copy of the workout for the active session
            let activeWorkout = Workout(
                name: workout.name,
                exercises: workout.exercises,
                date: Date(),
                duration: 0,
                notes: workout.notes,
                isTemplate: false
            )
            
            print("DEBUG: WorkoutsView - Created active workout with ID: \(activeWorkout.id)")
            
            // Start the workout session
            dataManager.startWorkout(activeWorkout)
            
            // Navigate to active workout view
            showingWorkoutOverview = activeWorkout
        }
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
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Weekly Overview Section
                            WeeklyOverviewSection(dataManager: dataManager)
                            
                            // Tab Interface
                            TabInterface(selectedTab: $selectedTab)
                            
                            // Content based on selected tab
                            if selectedTab == .adhoc {
                                AdhocWorkoutsView(dataManager: dataManager, draggedWorkout: $draggedWorkout, dragOffset: $dragOffset, selectedWorkout: $selectedWorkout, showingWorkoutOverview: $showingWorkoutOverview)
                            } else {
                                RoutinesView(dataManager: dataManager)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
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

// MARK: - Weekly Overview Section
struct WeeklyOverviewSection: View {
    let dataManager: DataManager
    
    private var currentWeekWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        return dataManager.workouts.filter { workout in
            workout.date >= startOfWeek && workout.date < endOfWeek
        }.sorted { $0.date < $1.date }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(currentWeekWorkouts.count) workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Week days with dots
            HStack(spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(day, format: .dateTime.day())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        // Dot indicator
                        Circle()
                            .fill(hasWorkoutOnDay(day) ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .padding(.horizontal, 4)
    }
    
    private func hasWorkoutOnDay(_ day: Date) -> Bool {
        let calendar = Calendar.current
        return currentWeekWorkouts.contains { workout in
            calendar.isDate(workout.date, inSameDayAs: day)
        }
    }
}

// MARK: - Modern Workout Card View
struct ModernWorkoutCardView: View {
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
    
    private var progressPercentage: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with title, date, and menu
                HStack {
                    // Enhanced drag handle indicator
                    VStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            HStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.secondary.opacity(0.6))
                                    .frame(width: 3, height: 3)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.secondary.opacity(0.6))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(workout.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        // Stats
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
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                }
                
                // Progress section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    // Modern progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progressPercentage, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Bottom section with duration and action
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Duration: \(formatDuration(workout.duration ?? 0))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            Text("Completed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    } else {
                        Button(action: onStartWorkout) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.subheadline)
                                Text("Start")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Drop Delegate
struct WorkoutDropDelegate: DropDelegate {
    let workout: Workout
    let dataManager: DataManager
    @Binding var draggedWorkout: Workout?
    @Binding var dragOffset: CGSize
    
    func dropEntered(info: DropInfo) {
        guard let draggedWorkout = draggedWorkout,
              draggedWorkout.id != workout.id else { return }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Move the dragged workout to the position of the drop target
        withAnimation(.easeInOut(duration: 0.3)) {
            if let draggedIndex = dataManager.workouts.firstIndex(where: { $0.id == draggedWorkout.id }),
               let targetIndex = dataManager.workouts.firstIndex(where: { $0.id == workout.id }) {
                dataManager.workouts.move(fromOffsets: IndexSet(integer: draggedIndex), toOffset: targetIndex)
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Reset drag state
        draggedWorkout = nil
        dragOffset = .zero
        
        // Provide success haptic feedback
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // Save the changes
        dataManager.saveWorkoutsDirectly(dataManager.workouts)
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Tab Interface
struct TabInterface: View {
    @Binding var selectedTab: WorkoutTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(WorkoutTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.displayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Adhoc Workouts View
struct AdhocWorkoutsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var draggedWorkout: Workout?
    @Binding var dragOffset: CGSize
    @Binding var selectedWorkout: Workout?
    @Binding var showingWorkoutOverview: Workout?
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(dataManager.workouts.enumerated()), id: \.element.id) { index, workout in
                ModernWorkoutCardView(
                    workout: workout,
                    dataManager: dataManager,
                    onTap: {
                        selectedWorkout = workout
                    },
                    onStartWorkout: {
                        startWorkout(workout)
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
                .offset(draggedWorkout?.id == workout.id ? dragOffset : .zero)
                .scaleEffect(draggedWorkout?.id == workout.id ? 1.05 : 1.0)
                .opacity(draggedWorkout?.id == workout.id ? 0.8 : 1.0)
                .onDrag {
                    draggedWorkout = workout
                    return NSItemProvider(object: workout.id.uuidString as NSString)
                }
                .onDrop(of: [.text], delegate: WorkoutDropDelegate(
                    workout: workout,
                    dataManager: dataManager,
                    draggedWorkout: $draggedWorkout,
                    dragOffset: $dragOffset
                ))
            }
        }
    }
    
    private func startWorkout(_ workout: Workout) {
        print("DEBUG: AdhocWorkoutsView - Starting workout: \(workout.name)")
        print("DEBUG: AdhocWorkoutsView - Workout ID: \(workout.id)")
        print("DEBUG: AdhocWorkoutsView - Exercise count: \(workout.exercises.count)")
        
        for (exIndex, exercise) in workout.exercises.enumerated() {
            print("DEBUG: AdhocWorkoutsView - Exercise \(exIndex): \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
            for (setIndex, set) in exercise.sets.enumerated() {
                print("DEBUG: AdhocWorkoutsView -   Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
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
            print("DEBUG: AdhocWorkoutsView - Found recent modified workout: \(recentWorkout.name) (ID: \(recentWorkout.id))")
            print("DEBUG: AdhocWorkoutsView - Recent workout sets:")
            for exercise in recentWorkout.exercises {
                print("DEBUG: AdhocWorkoutsView -   Exercise: \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("DEBUG: AdhocWorkoutsView -     Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), isCompleted=\(set.isCompleted)")
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
                                reps: set.reps,
                                weight: set.weight,
                                duration: set.duration,
                                distance: set.distance,
                                restTime: set.restTime,
                                isCompleted: false, // Reset completion state
                                order: set.order
                            )
                        },
                        order: exercise.order
                    )
                },
                date: Date(),
                duration: 0,
                notes: recentWorkout.notes,
                isTemplate: false
            )
            
            print("DEBUG: AdhocWorkoutsView - Created new workout based on recent workout with ID: \(newWorkout.id)")
            
            // Start the workout session with the new workout
            dataManager.startWorkout(newWorkout)
            
            // Navigate to active workout view
            showingWorkoutOverview = newWorkout
        } else {
            // Create a copy of the workout for the active session
            let activeWorkout = Workout(
                name: workout.name,
                exercises: workout.exercises,
                date: Date(),
                duration: 0,
                notes: workout.notes,
                isTemplate: false
            )
            
            print("DEBUG: AdhocWorkoutsView - Created active workout with ID: \(activeWorkout.id)")
            
            // Start the workout session
            dataManager.startWorkout(activeWorkout)
            
            // Navigate to active workout view
            showingWorkoutOverview = activeWorkout
        }
    }
    
    private func shareWorkout(_ workout: Workout) {
        // Implementation for sharing workout
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
            isTemplate: false
        )
        
        dataManager.addWorkout(duplicatedWorkout)
    }
    
    private func editWorkout(_ workout: Workout) {
        // Implementation for editing workout
    }
    
    private func deleteWorkout(_ workout: Workout) {
        dataManager.deleteWorkout(workout)
        print("DEBUG: AdhocWorkoutsView - Deleted workout: \(workout.name)")
    }
}

// MARK: - Routines View
struct RoutinesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewRoutine = false
    
    var body: some View {
        LazyVStack(spacing: 16) {
            if dataManager.routines.isEmpty {
                EmptyRoutinesView {
                    showingNewRoutine = true
                }
            } else {
                ForEach(dataManager.routines) { routine in
                    RoutineCardView(routine: routine, dataManager: dataManager)
                }
            }
        }
        .sheet(isPresented: $showingNewRoutine) {
            NewRoutineView(dataManager: dataManager)
        }
    }
}

// MARK: - Empty Routines View
struct EmptyRoutinesView: View {
    let onCreateRoutine: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Routines Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first workout routine to get started with structured training")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateRoutine) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Routine")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Routine Card View
struct RoutineCardView: View {
    let routine: Routine
    @EnvironmentObject var dataManager: DataManager
    @State private var showingRoutineDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(routine.days.count) days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingRoutineDetail = true
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            // Days preview
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(routine.days) { day in
                    DayPreviewView(day: day)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingRoutineDetail) {
            RoutineDetailView(routine: routine, dataManager: dataManager)
        }
    }
}

// MARK: - Day Preview View
struct DayPreviewView: View {
    let day: RoutineDay
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day.dayName)
                .font(.caption)
                .fontWeight(.medium)
            
            if day.isRestDay {
                Text("Rest")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let workout = day.workout {
                Text(workout.name)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - New Routine View (Placeholder)
struct NewRoutineView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create New Routine")
                    .font(.title)
                    .padding()
                
                Text("Routine creation functionality will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Routine Detail View (Placeholder)
struct RoutineDetailView: View {
    let routine: Routine
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Routine Details")
                    .font(.title)
                    .padding()
                
                Text("Routine detail functionality will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
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

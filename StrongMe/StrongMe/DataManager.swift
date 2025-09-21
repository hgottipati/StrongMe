//
//  DataManager.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import Foundation
import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var routines: [Routine] = []
    @Published var exerciseLibrary: [Exercise] = []
    @Published var currentUser: User?
    @Published var currentWorkout: Workout?
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {
        loadData()
    }
    
    // MARK: - Workout Management
    func startWorkout(_ workout: Workout) {
        currentWorkout = workout
    }
    
    func endWorkout() {
        guard var workout = currentWorkout else { return }
        workout.duration = Date().timeIntervalSince(workout.date)
        workouts.append(workout)
        persistenceManager.saveWorkouts(workouts)
        currentWorkout = nil
    }
    
    func saveWorkout(_ workout: Workout) {
        print("DEBUG: DataManager.saveWorkout - Saving workout: \(workout.name)")
        print("DEBUG: DataManager.saveWorkout - Workout ID: \(workout.id)")
        print("DEBUG: DataManager.saveWorkout - Number of exercises: \(workout.exercises.count)")
        
        for (index, exercise) in workout.exercises.enumerated() {
            print("DEBUG: DataManager.saveWorkout - Exercise \(index): \(exercise.exercise.name)")
            print("DEBUG: DataManager.saveWorkout - Number of sets: \(exercise.sets.count)")
            for (setIndex, set) in exercise.sets.enumerated() {
                print("DEBUG: DataManager.saveWorkout - Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0), order=\(set.order)")
            }
        }
        
        // First try to find by exact ID match
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            print("DEBUG: DataManager.saveWorkout - Updating existing workout by ID at index \(index)")
            workouts[index] = workout
        } else {
            // If no ID match, check if this is an update to an existing workout
            // Look for workouts with the same name and recent date (within last 24 hours)
            let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            if let index = workouts.firstIndex(where: { existingWorkout in
                existingWorkout.name == workout.name && 
                existingWorkout.date > oneDayAgo &&
                !existingWorkout.name.contains("Copy") // Don't update if it's a copy
            }) {
                print("DEBUG: DataManager.saveWorkout - Updating existing workout by name/date at index \(index)")
                workouts[index] = workout
            } else {
                print("DEBUG: DataManager.saveWorkout - Adding new workout")
                workouts.append(workout)
            }
        }
        
        print("DEBUG: DataManager.saveWorkout - Total workouts after save: \(workouts.count)")
        
        // Log all workouts after save for debugging
        for (index, savedWorkout) in workouts.enumerated() {
            print("DEBUG: DataManager.saveWorkout - Saved workout \(index): \(savedWorkout.name) (ID: \(savedWorkout.id))")
            for exercise in savedWorkout.exercises {
                print("DEBUG: DataManager.saveWorkout -   Exercise: \(exercise.exercise.name)")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("DEBUG: DataManager.saveWorkout -     Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                }
            }
        }
        
        persistenceManager.saveWorkouts(workouts)
        print("DEBUG: DataManager.saveWorkout - Data saved to persistence")
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        persistenceManager.saveWorkouts(workouts)
    }
    
    func saveWorkoutsDirectly(_ workouts: [Workout]) {
        self.workouts = workouts
        persistenceManager.saveWorkouts(workouts)
    }
    
    // MARK: - Exercise Management
    func addExercise(_ exercise: Exercise) {
        exerciseLibrary.append(exercise)
    }
    
    func searchExercises(query: String) -> [Exercise] {
        if query.isEmpty {
            return exerciseLibrary
        }
        return exerciseLibrary.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.muscleGroups.contains { $0.rawValue.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadSampleExercises()
        loadWorkouts()
        loadRoutines()
        loadUser()
    }
    
    private func loadWorkouts() {
        let savedWorkouts = persistenceManager.loadWorkouts()
        if savedWorkouts.isEmpty {
            loadSampleWorkouts()
        } else {
            workouts = savedWorkouts
            // Always ensure we have some sample data for previous values
            ensureSampleDataExists()
        }
    }
    
    private func ensureSampleDataExists() {
        // Check if we have any workouts with Bench Press or Push-ups
        let hasBenchPress = workouts.contains { workout in
            workout.exercises.contains { $0.exercise.name == "Bench Press" }
        }
        let hasPushUps = workouts.contains { workout in
            workout.exercises.contains { $0.exercise.name == "Push-ups" }
        }
        
        print("DEBUG: DataManager - hasBenchPress: \(hasBenchPress), hasPushUps: \(hasPushUps)")
        print("DEBUG: DataManager - Total workouts: \(workouts.count)")
        
        // If we don't have sample exercises, add them
        if !hasBenchPress || !hasPushUps {
            print("DEBUG: Adding sample data for previous values")
            loadSampleWorkouts()
            print("DEBUG: DataManager - After adding sample data, total workouts: \(workouts.count)")
        }
    }
    
    private func loadUser() {
        if let savedUser = persistenceManager.loadUser() {
            currentUser = savedUser
        } else {
            loadSampleUser()
        }
    }
    
    private func loadSampleExercises() {
        exerciseLibrary = [
            // Chest Exercises
            Exercise(name: "Bench Press", category: .strength, muscleGroups: [.chest, .triceps, .shoulders], equipment: .barbell),
            Exercise(name: "Push-ups", category: .strength, muscleGroups: [.chest, .triceps, .shoulders], equipment: .bodyweight),
            Exercise(name: "Dumbbell Press", category: .strength, muscleGroups: [.chest, .triceps, .shoulders], equipment: .dumbbell),
            Exercise(name: "Incline Bench Press", category: .strength, muscleGroups: [.chest, .triceps, .shoulders], equipment: .barbell),
            Exercise(name: "Chest Fly", category: .strength, muscleGroups: [.chest], equipment: .dumbbell),
            
            // Back Exercises
            Exercise(name: "Deadlift", category: .strength, muscleGroups: [.back, .glutes, .hamstrings], equipment: .barbell),
            Exercise(name: "Pull-ups", category: .strength, muscleGroups: [.back, .biceps], equipment: .bodyweight),
            Exercise(name: "Bent-over Row", category: .strength, muscleGroups: [.back, .biceps], equipment: .barbell),
            Exercise(name: "Lat Pulldown", category: .strength, muscleGroups: [.back, .biceps], equipment: .machine),
            Exercise(name: "T-Bar Row", category: .strength, muscleGroups: [.back, .biceps], equipment: .barbell),
            
            // Leg Exercises
            Exercise(name: "Squat", category: .strength, muscleGroups: [.quads, .glutes, .hamstrings], equipment: .barbell),
            Exercise(name: "Lunges", category: .strength, muscleGroups: [.quads, .glutes, .hamstrings], equipment: .bodyweight),
            Exercise(name: "Leg Press", category: .strength, muscleGroups: [.quads, .glutes], equipment: .machine),
            Exercise(name: "Romanian Deadlift", category: .strength, muscleGroups: [.hamstrings, .glutes], equipment: .barbell),
            Exercise(name: "Calf Raises", category: .strength, muscleGroups: [.calves], equipment: .bodyweight),
            
            // Shoulder Exercises
            Exercise(name: "Overhead Press", category: .strength, muscleGroups: [.shoulders, .triceps], equipment: .barbell),
            Exercise(name: "Lateral Raises", category: .strength, muscleGroups: [.shoulders], equipment: .dumbbell),
            Exercise(name: "Front Raises", category: .strength, muscleGroups: [.shoulders], equipment: .dumbbell),
            Exercise(name: "Face Pulls", category: .strength, muscleGroups: [.shoulders, .back], equipment: .cable),
            
            // Arm Exercises
            Exercise(name: "Bicep Curls", category: .strength, muscleGroups: [.biceps], equipment: .dumbbell),
            Exercise(name: "Tricep Dips", category: .strength, muscleGroups: [.triceps, .chest], equipment: .bodyweight),
            Exercise(name: "Hammer Curls", category: .strength, muscleGroups: [.biceps, .forearms], equipment: .dumbbell),
            Exercise(name: "Close-grip Bench Press", category: .strength, muscleGroups: [.triceps, .chest], equipment: .barbell),
            
            // Core Exercises
            Exercise(name: "Plank", category: .strength, muscleGroups: [.abs, .obliques], equipment: .bodyweight),
            Exercise(name: "Crunches", category: .strength, muscleGroups: [.abs], equipment: .bodyweight),
            Exercise(name: "Russian Twists", category: .strength, muscleGroups: [.abs, .obliques], equipment: .bodyweight),
            Exercise(name: "Mountain Climbers", category: .cardio, muscleGroups: [.abs, .fullBody], equipment: .bodyweight),
            
            // Cardio Exercises
            Exercise(name: "Running", category: .cardio, muscleGroups: [.fullBody], equipment: .none),
            Exercise(name: "Cycling", category: .cardio, muscleGroups: [.quads, .calves], equipment: .none),
            Exercise(name: "Rowing", category: .cardio, muscleGroups: [.fullBody], equipment: .machine),
            Exercise(name: "Burpees", category: .cardio, muscleGroups: [.fullBody], equipment: .bodyweight)
        ]
    }
    
    private func loadSampleWorkouts() {
        print("DEBUG: DataManager - Loading sample workouts")
        
        // Add a previous workout from 2 days ago
        let previousWorkout = Workout(
            name: "Previous Push Day",
            exercises: [
                WorkoutExercise(
                    exercise: exerciseLibrary.first { $0.name == "Bench Press" }!,
                    sets: [
                        Set(reps: 12, weight: 55, order: 1),
                        Set(reps: 10, weight: 65, order: 2),
                        Set(reps: 8, weight: 75, order: 3)
                    ],
                    order: 1
                ),
                WorkoutExercise(
                    exercise: exerciseLibrary.first { $0.name == "Push-ups" }!,
                    sets: [
                        Set(reps: 15, weight: nil, order: 1),
                        Set(reps: 12, weight: nil, order: 2),
                        Set(reps: 10, weight: nil, order: 3)
                    ],
                    order: 2
                )
            ],
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )
        workouts.append(previousWorkout)
        
        // Add a more recent workout from yesterday
        let recentWorkout = Workout(
            name: "Push Day",
            exercises: [
                WorkoutExercise(
                    exercise: exerciseLibrary.first { $0.name == "Bench Press" }!,
                    sets: [
                        Set(reps: 10, weight: 60, order: 1),
                        Set(reps: 8, weight: 70, order: 2),
                        Set(reps: 6, weight: 80, order: 3)
                    ],
                    order: 1
                ),
                WorkoutExercise(
                    exercise: exerciseLibrary.first { $0.name == "Dumbbell Press" }!,
                    sets: [
                        Set(reps: 12, weight: 25, order: 1),
                        Set(reps: 10, weight: 30, order: 2),
                        Set(reps: 8, weight: 35, order: 3)
                    ],
                    order: 2
                )
            ],
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
        workouts.append(recentWorkout)
        
        print("DEBUG: DataManager - Added \(workouts.count) sample workouts")
        for (index, workout) in workouts.enumerated() {
            print("DEBUG: DataManager - Workout \(index): \(workout.name) on \(workout.date)")
        }
    }
    
    private func loadSampleUser() {
        currentUser = User(
            name: "Hareesh Gottipati",
            email: "hareesh@example.com",
            weight: 75.0,
            height: 175.0,
            fitnessGoals: [.strength, .muscleGain],
            workoutPreferences: WorkoutPreferences()
        )
        persistenceManager.saveUser(currentUser!)
    }
    
    // MARK: - Routine Management
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveRoutines()
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
            saveRoutines()
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }
    
    func saveRoutines() {
        persistenceManager.saveRoutines(routines)
    }
    
    func loadRoutines() {
        routines = persistenceManager.loadRoutines()
    }
}

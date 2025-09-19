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
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
        } else {
            workouts.append(workout)
        }
        persistenceManager.saveWorkouts(workouts)
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
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
        loadUser()
    }
    
    private func loadWorkouts() {
        let savedWorkouts = persistenceManager.loadWorkouts()
        if savedWorkouts.isEmpty {
            loadSampleWorkouts()
        } else {
            workouts = savedWorkouts
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
        let sampleWorkout = Workout(
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
        workouts.append(sampleWorkout)
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
}

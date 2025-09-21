//
//  PersistenceManager.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let workoutsKey = "saved_workouts"
    private let userKey = "current_user"
    
    private init() {}
    
    // MARK: - Workouts
    func saveWorkouts(_ workouts: [Workout]) {
        print("DEBUG: PersistenceManager.saveWorkouts - Saving \(workouts.count) workouts")
        
        for (index, workout) in workouts.enumerated() {
            print("DEBUG: PersistenceManager.saveWorkouts - Workout \(index): \(workout.name) (ID: \(workout.id))")
            for exercise in workout.exercises {
                print("DEBUG: PersistenceManager.saveWorkouts -   Exercise: \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("DEBUG: PersistenceManager.saveWorkouts -     Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                }
            }
        }
        
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: workoutsKey)
            print("DEBUG: PersistenceManager.saveWorkouts - Successfully saved to UserDefaults")
        } else {
            print("DEBUG: PersistenceManager.saveWorkouts - ERROR: Failed to encode workouts")
        }
    }
    
    func loadWorkouts() -> [Workout] {
        guard let data = UserDefaults.standard.data(forKey: workoutsKey),
              let workouts = try? JSONDecoder().decode([Workout].self, from: data) else {
            print("DEBUG: PersistenceManager.loadWorkouts - No saved workouts found or failed to decode")
            return []
        }
        
        print("DEBUG: PersistenceManager.loadWorkouts - Loaded \(workouts.count) workouts from UserDefaults")
        for (index, workout) in workouts.enumerated() {
            print("DEBUG: PersistenceManager.loadWorkouts - Workout \(index): \(workout.name) (ID: \(workout.id))")
            for exercise in workout.exercises {
                print("DEBUG: PersistenceManager.loadWorkouts -   Exercise: \(exercise.exercise.name) - Sets: \(exercise.sets.count)")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("DEBUG: PersistenceManager.loadWorkouts -     Set \(setIndex): weight=\(set.weight ?? 0), reps=\(set.reps ?? 0)")
                }
            }
        }
        
        return workouts
    }
    
    // MARK: - User
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
    
    func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
}

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
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: workoutsKey)
        }
    }
    
    func loadWorkouts() -> [Workout] {
        guard let data = UserDefaults.standard.data(forKey: workoutsKey),
              let workouts = try? JSONDecoder().decode([Workout].self, from: data) else {
            return []
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

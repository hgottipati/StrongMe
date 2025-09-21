//
//  Workout.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import Foundation

struct Workout: Identifiable, Codable {
    let id = UUID()
    var name: String
    var exercises: [WorkoutExercise]
    var date: Date
    var duration: TimeInterval?
    var notes: String?
    var isTemplate: Bool = false
    
    init(name: String, exercises: [WorkoutExercise] = [], date: Date = Date(), duration: TimeInterval? = nil, notes: String? = nil, isTemplate: Bool = false) {
        self.name = name
        self.exercises = exercises
        self.date = date
        self.duration = duration
        self.notes = notes
        self.isTemplate = isTemplate
    }
}

struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    var exercise: Exercise
    var sets: [Set]
    var notes: String?
    var order: Int
    
    init(exercise: Exercise, sets: [Set] = [], notes: String? = nil, order: Int) {
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
        self.order = order
    }
}

struct Set: Identifiable, Codable {
    let id = UUID()
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval? // For time-based exercises
    var distance: Double? // For cardio exercises
    var restTime: TimeInterval?
    var isCompleted: Bool = false
    var order: Int
    
    init(reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, distance: Double? = nil, restTime: TimeInterval? = nil, isCompleted: Bool = false, order: Int) {
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.restTime = restTime
        self.isCompleted = isCompleted
        self.order = order
    }
}

// MARK: - Routine Model
struct Routine: Identifiable, Codable {
    let id = UUID()
    var name: String
    var days: [RoutineDay]
    var isActive: Bool = true
    var createdDate: Date = Date()
    var notes: String?
    
    init(name: String, days: [RoutineDay] = [], isActive: Bool = true, notes: String? = nil) {
        self.name = name
        self.days = days
        self.isActive = isActive
        self.notes = notes
    }
}

struct RoutineDay: Identifiable, Codable {
    let id = UUID()
    var dayNumber: Int // 1, 2, 3, etc.
    var dayName: String // "Day 1", "Day 2", etc.
    var workout: Workout?
    var isRestDay: Bool = false
    var notes: String?
    
    init(dayNumber: Int, dayName: String? = nil, workout: Workout? = nil, isRestDay: Bool = false, notes: String? = nil) {
        self.dayNumber = dayNumber
        self.dayName = dayName ?? "Day \(dayNumber)"
        self.workout = workout
        self.isRestDay = isRestDay
        self.notes = notes
    }
}

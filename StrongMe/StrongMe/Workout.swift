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

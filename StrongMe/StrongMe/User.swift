//
//  User.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var profileImage: String?
    var weight: Double? // in kg
    var height: Double? // in cm
    var dateOfBirth: Date?
    var fitnessGoals: [FitnessGoal]
    var workoutPreferences: WorkoutPreferences
    
    init(name: String, email: String, profileImage: String? = nil, weight: Double? = nil, height: Double? = nil, dateOfBirth: Date? = nil, fitnessGoals: [FitnessGoal] = [], workoutPreferences: WorkoutPreferences = WorkoutPreferences()) {
        self.name = name
        self.email = email
        self.profileImage = profileImage
        self.weight = weight
        self.height = height
        self.dateOfBirth = dateOfBirth
        self.fitnessGoals = fitnessGoals
        self.workoutPreferences = workoutPreferences
    }
}

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "Weight Loss"
    case muscleGain = "Muscle Gain"
    case strength = "Strength"
    case endurance = "Endurance"
    case generalFitness = "General Fitness"
    case competition = "Competition"
}

struct WorkoutPreferences: Codable {
    var defaultRestTime: TimeInterval = 90 // seconds
    var weightUnit: WeightUnit = .kg
    var distanceUnit: DistanceUnit = .km
    var temperatureUnit: TemperatureUnit = .celsius
    var autoStartRestTimer: Bool = true
    var showPreviousWorkoutData: Bool = true
}

enum WeightUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case lbs = "lbs"
}

enum DistanceUnit: String, CaseIterable, Codable {
    case km = "km"
    case miles = "miles"
}

enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "°C"
    case fahrenheit = "°F"
}

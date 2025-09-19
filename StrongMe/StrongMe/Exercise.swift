//
//  Exercise.swift
//  StrongMe
//
//  Created by Hareesh Gottipati on 9/18/25.
//

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var equipment: Equipment?
    var instructions: String?
    var isCustom: Bool = false
    
    init(name: String, category: ExerciseCategory, muscleGroups: [MuscleGroup], equipment: Equipment? = nil, instructions: String? = nil, isCustom: Bool = false) {
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
    }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case sports = "Sports"
    case other = "Other"
}

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"
}

enum Equipment: String, CaseIterable, Codable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case kettlebell = "Kettlebell"
    case bodyweight = "Bodyweight"
    case machine = "Machine"
    case cable = "Cable"
    case resistanceBand = "Resistance Band"
    case none = "No Equipment"
}

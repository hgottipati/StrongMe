//
//  WorkoutModelTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
@testable import StrongMe

class WorkoutModelTests: XCTestCase {
    
    // MARK: - Workout Tests
    
    func testWorkoutInitialization() {
        // Given
        let name = "Test Workout"
        let exercises: [WorkoutExercise] = []
        let date = Date()
        let notes = "Test notes"
        
        // When
        let workout = Workout(name: name, exercises: exercises, date: date, duration: nil, notes: notes, isTemplate: false)
        
        // Then
        XCTAssertEqual(workout.name, name)
        XCTAssertEqual(workout.exercises.count, 0)
        XCTAssertEqual(workout.date, date)
        XCTAssertEqual(workout.notes, notes)
        XCTAssertFalse(workout.isTemplate)
        XCTAssertNotNil(workout.id)
    }
    
    func testWorkoutWithExercises() {
        // Given
        let exercise = createSampleExercise()
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                Set(reps: 10, weight: 50.0, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1)
            ],
            notes: "Test exercise",
            order: 1
        )
        
        // When
        let workout = Workout(name: "Test Workout", exercises: [workoutExercise], date: Date(), duration: nil, notes: nil, isTemplate: false)
        
        // Then
        XCTAssertEqual(workout.exercises.count, 1)
        XCTAssertEqual(workout.exercises.first?.exercise.name, "Push Up")
        XCTAssertEqual(workout.exercises.first?.sets.count, 1)
    }
    
    func testWorkoutCodable() {
        // Given
        let workout = createSampleWorkout()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(workout)
            let decodedWorkout = try decoder.decode(Workout.self, from: data)
            
            // Then
            XCTAssertEqual(workout.name, decodedWorkout.name)
            XCTAssertEqual(workout.exercises.count, decodedWorkout.exercises.count)
            XCTAssertEqual(workout.notes, decodedWorkout.notes)
            XCTAssertEqual(workout.isTemplate, decodedWorkout.isTemplate)
        } catch {
            XCTFail("Failed to encode/decode workout: \(error)")
        }
    }
    
    // MARK: - Routine Tests
    
    func testRoutineInitialization() {
        // Given
        let name = "Test Routine"
        let days: [RoutineDay] = []
        let notes = "Test routine notes"
        
        // When
        let routine = Routine(name: name, days: days, isActive: true, notes: notes)
        
        // Then
        XCTAssertEqual(routine.name, name)
        XCTAssertEqual(routine.days.count, 0)
        XCTAssertTrue(routine.isActive)
        XCTAssertEqual(routine.notes, notes)
        XCTAssertNotNil(routine.id)
        XCTAssertNotNil(routine.createdDate)
    }
    
    func testRoutineWithDays() {
        // Given
        let day1 = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: createSampleWorkout(), isRestDay: false)
        let day2 = RoutineDay(dayNumber: 2, dayName: "Day 2", workout: nil, isRestDay: true)
        
        // When
        let routine = Routine(name: "Test Routine", days: [day1, day2], isActive: true, notes: nil)
        
        // Then
        XCTAssertEqual(routine.days.count, 2)
        XCTAssertEqual(routine.days.first?.dayNumber, 1)
        XCTAssertEqual(routine.days.first?.dayName, "Day 1")
        XCTAssertFalse(routine.days.first?.isRestDay ?? true)
        XCTAssertEqual(routine.days.last?.dayNumber, 2)
        XCTAssertEqual(routine.days.last?.dayName, "Day 2")
        XCTAssertTrue(routine.days.last?.isRestDay ?? false)
    }
    
    func testRoutineCodable() {
        // Given
        let routine = createSampleRoutine()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(routine)
            let decodedRoutine = try decoder.decode(Routine.self, from: data)
            
            // Then
            XCTAssertEqual(routine.name, decodedRoutine.name)
            XCTAssertEqual(routine.days.count, decodedRoutine.days.count)
            XCTAssertEqual(routine.isActive, decodedRoutine.isActive)
            XCTAssertEqual(routine.notes, decodedRoutine.notes)
        } catch {
            XCTFail("Failed to encode/decode routine: \(error)")
        }
    }
    
    // MARK: - RoutineDay Tests
    
    func testRoutineDayInitialization() {
        // Given
        let dayNumber = 1
        let dayName = "Day 1"
        let workout = createSampleWorkout()
        let notes = "Test day notes"
        
        // When
        let day = RoutineDay(dayNumber: dayNumber, dayName: dayName, workout: workout, isRestDay: false, notes: notes)
        
        // Then
        XCTAssertEqual(day.dayNumber, dayNumber)
        XCTAssertEqual(day.dayName, dayName)
        XCTAssertEqual(day.workout?.name, workout.name)
        XCTAssertFalse(day.isRestDay)
        XCTAssertEqual(day.notes, notes)
        XCTAssertNotNil(day.id)
    }
    
    func testRoutineDayDefaultName() {
        // Given
        let dayNumber = 3
        
        // When
        let day = RoutineDay(dayNumber: dayNumber, dayName: nil, workout: nil, isRestDay: false, notes: nil)
        
        // Then
        XCTAssertEqual(day.dayName, "Day 3")
    }
    
    func testRoutineDayCodable() {
        // Given
        let day = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: createSampleWorkout(), isRestDay: false, notes: "Test")
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(day)
            let decodedDay = try decoder.decode(RoutineDay.self, from: data)
            
            // Then
            XCTAssertEqual(day.dayNumber, decodedDay.dayNumber)
            XCTAssertEqual(day.dayName, decodedDay.dayName)
            XCTAssertEqual(day.isRestDay, decodedDay.isRestDay)
            XCTAssertEqual(day.notes, decodedDay.notes)
        } catch {
            XCTFail("Failed to encode/decode routine day: \(error)")
        }
    }
    
    // MARK: - Set Tests
    
    func testSetInitialization() {
        // Given
        let reps = 10
        let weight = 50.0
        let duration = 30.0
        let distance = 100.0
        let restTime = 60
        let isCompleted = false
        let order = 1
        
        // When
        let set = Set(reps: reps, weight: weight, duration: duration, distance: distance, restTime: restTime, isCompleted: isCompleted, order: order)
        
        // Then
        XCTAssertEqual(set.reps, reps)
        XCTAssertEqual(set.weight, weight)
        XCTAssertEqual(set.duration, duration)
        XCTAssertEqual(set.distance, distance)
        XCTAssertEqual(set.restTime, restTime)
        XCTAssertEqual(set.isCompleted, isCompleted)
        XCTAssertEqual(set.order, order)
        XCTAssertNotNil(set.id)
    }
    
    func testSetCodable() {
        // Given
        let set = Set(reps: 10, weight: 50.0, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1)
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(set)
            let decodedSet = try decoder.decode(Set.self, from: data)
            
            // Then
            XCTAssertEqual(set.reps, decodedSet.reps)
            XCTAssertEqual(set.weight, decodedSet.weight)
            XCTAssertEqual(set.restTime, decodedSet.restTime)
            XCTAssertEqual(set.isCompleted, decodedSet.isCompleted)
            XCTAssertEqual(set.order, decodedSet.order)
        } catch {
            XCTFail("Failed to encode/decode set: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleExercise() -> Exercise {
        return Exercise(
            name: "Push Up",
            description: "A basic push up exercise",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight,
            difficulty: .beginner
        )
    }
    
    private func createSampleWorkout() -> Workout {
        let exercise = createSampleExercise()
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                Set(reps: 10, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1)
            ],
            notes: "Test exercise",
            order: 1
        )
        
        return Workout(
            name: "Test Workout",
            exercises: [workoutExercise],
            date: Date(),
            duration: nil,
            notes: "Test workout",
            isTemplate: false
        )
    }
    
    private func createSampleRoutine() -> Routine {
        let day1 = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: createSampleWorkout(), isRestDay: false)
        let day2 = RoutineDay(dayNumber: 2, dayName: "Day 2", workout: nil, isRestDay: true)
        
        return Routine(
            name: "Test Routine",
            days: [day1, day2],
            isActive: true,
            notes: "Test routine"
        )
    }
}

//
//  DataManagerTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
@testable import StrongMe

class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager()
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    // MARK: - Workout Management Tests
    
    func testAddWorkout() {
        // Given
        let workout = createSampleWorkout()
        
        // When
        dataManager.addWorkout(workout)
        
        // Then
        XCTAssertEqual(dataManager.workouts.count, 1)
        XCTAssertEqual(dataManager.workouts.first?.name, "Test Workout")
    }
    
    func testDeleteWorkout() {
        // Given
        let workout = createSampleWorkout()
        dataManager.addWorkout(workout)
        XCTAssertEqual(dataManager.workouts.count, 1)
        
        // When
        dataManager.deleteWorkout(workout)
        
        // Then
        XCTAssertEqual(dataManager.workouts.count, 0)
    }
    
    func testSaveWorkout() {
        // Given
        let workout = createSampleWorkout()
        
        // When
        dataManager.saveWorkout(workout)
        
        // Then
        XCTAssertEqual(dataManager.workouts.count, 1)
        XCTAssertEqual(dataManager.workouts.first?.name, "Test Workout")
    }
    
    func testStartWorkout() {
        // Given
        let workout = createSampleWorkout()
        
        // When
        dataManager.startWorkout(workout)
        
        // Then
        XCTAssertNotNil(dataManager.currentWorkout)
        XCTAssertEqual(dataManager.currentWorkout?.name, "Test Workout")
    }
    
    func testEndWorkout() {
        // Given
        let workout = createSampleWorkout()
        dataManager.startWorkout(workout)
        XCTAssertNotNil(dataManager.currentWorkout)
        
        // When
        dataManager.endWorkout()
        
        // Then
        XCTAssertNil(dataManager.currentWorkout)
        XCTAssertEqual(dataManager.workouts.count, 1)
    }
    
    // MARK: - Routine Management Tests
    
    func testAddRoutine() {
        // Given
        let routine = createSampleRoutine()
        
        // When
        dataManager.addRoutine(routine)
        
        // Then
        XCTAssertEqual(dataManager.routines.count, 1)
        XCTAssertEqual(dataManager.routines.first?.name, "Test Routine")
    }
    
    func testUpdateRoutine() {
        // Given
        let routine = createSampleRoutine()
        dataManager.addRoutine(routine)
        
        // When
        var updatedRoutine = routine
        updatedRoutine.name = "Updated Routine"
        dataManager.updateRoutine(updatedRoutine)
        
        // Then
        XCTAssertEqual(dataManager.routines.count, 1)
        XCTAssertEqual(dataManager.routines.first?.name, "Updated Routine")
    }
    
    func testDeleteRoutine() {
        // Given
        let routine = createSampleRoutine()
        dataManager.addRoutine(routine)
        XCTAssertEqual(dataManager.routines.count, 1)
        
        // When
        dataManager.deleteRoutine(routine)
        
        // Then
        XCTAssertEqual(dataManager.routines.count, 0)
    }
    
    // MARK: - Exercise Library Tests
    
    func testSearchExercises() {
        // Given
        let exercises = dataManager.searchExercises(query: "push")
        
        // Then
        XCTAssertFalse(exercises.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleWorkout() -> Workout {
        let exercise = Exercise(
            name: "Push Up",
            description: "A basic push up exercise",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight,
            difficulty: .beginner
        )
        
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                Set(reps: 10, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1),
                Set(reps: 10, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 2)
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

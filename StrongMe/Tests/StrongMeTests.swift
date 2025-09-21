//
//  StrongMeTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
@testable import StrongMe

class StrongMeTests: XCTestCase {
    
    func testAppLaunch() throws {
        // This is a basic test to ensure the app can launch
        // and the main components are accessible
        let dataManager = DataManager()
        XCTAssertNotNil(dataManager)
        
        let persistenceManager = PersistenceManager.shared
        XCTAssertNotNil(persistenceManager)
    }
    
    func testCoreModelsExist() throws {
        // Test that core models can be instantiated
        let workout = Workout(name: "Test", exercises: [], date: Date())
        XCTAssertNotNil(workout)
        
        let routine = Routine(name: "Test Routine", days: [])
        XCTAssertNotNil(routine)
        
        let exercise = Exercise(
            name: "Test Exercise",
            description: "Test",
            muscleGroups: [.chest],
            equipment: .bodyweight,
            difficulty: .beginner
        )
        XCTAssertNotNil(exercise)
    }
    
    func testDataManagerInitialization() throws {
        let dataManager = DataManager()
        
        // Test that DataManager initializes with empty collections
        XCTAssertEqual(dataManager.workouts.count, 0)
        XCTAssertEqual(dataManager.routines.count, 0)
        XCTAssertEqual(dataManager.exerciseLibrary.count, 0)
        XCTAssertNil(dataManager.currentUser)
        XCTAssertNil(dataManager.currentWorkout)
    }
    
    func testPersistenceManagerSingleton() throws {
        let instance1 = PersistenceManager.shared
        let instance2 = PersistenceManager.shared
        
        // Test that PersistenceManager is a singleton
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testWorkoutTabEnum() throws {
        // Test that WorkoutTab enum works correctly
        let adhocTab = WorkoutTab.adhoc
        let routinesTab = WorkoutTab.routines
        
        XCTAssertEqual(adhocTab.displayName, "Adhoc")
        XCTAssertEqual(routinesTab.displayName, "Routines")
        XCTAssertEqual(WorkoutTab.allCases.count, 2)
    }
    
    func testBasicWorkflow() throws {
        // Test a basic workflow: create workout, save it, load it
        let dataManager = DataManager()
        
        let exercise = Exercise(
            name: "Test Exercise",
            description: "Test",
            muscleGroups: [.chest],
            equipment: .bodyweight,
            difficulty: .beginner
        )
        
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                Set(reps: 10, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1)
            ],
            notes: nil,
            order: 1
        )
        
        let workout = Workout(
            name: "Test Workout",
            exercises: [workoutExercise],
            date: Date(),
            duration: nil,
            notes: "Test workout",
            isTemplate: false
        )
        
        // Add workout
        dataManager.addWorkout(workout)
        XCTAssertEqual(dataManager.workouts.count, 1)
        
        // Start workout
        dataManager.startWorkout(workout)
        XCTAssertNotNil(dataManager.currentWorkout)
        
        // End workout
        dataManager.endWorkout()
        XCTAssertNil(dataManager.currentWorkout)
        XCTAssertEqual(dataManager.workouts.count, 2) // Original + completed workout
    }
    
    func testRoutineWorkflow() throws {
        // Test a basic routine workflow
        let dataManager = DataManager()
        
        let day1 = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: nil, isRestDay: false)
        let day2 = RoutineDay(dayNumber: 2, dayName: "Day 2", workout: nil, isRestDay: true)
        
        let routine = Routine(
            name: "Test Routine",
            days: [day1, day2],
            isActive: true,
            notes: "Test routine"
        )
        
        // Add routine
        dataManager.addRoutine(routine)
        XCTAssertEqual(dataManager.routines.count, 1)
        
        // Update routine
        var updatedRoutine = routine
        updatedRoutine.name = "Updated Routine"
        dataManager.updateRoutine(updatedRoutine)
        XCTAssertEqual(dataManager.routines.first?.name, "Updated Routine")
        
        // Delete routine
        dataManager.deleteRoutine(updatedRoutine)
        XCTAssertEqual(dataManager.routines.count, 0)
    }
}

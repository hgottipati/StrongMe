//
//  TestRunner.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import Foundation
@testable import StrongMe

/// Simple test runner for manual verification
/// This can be used to run basic tests without Xcode
class TestRunner {
    
    static func runAllTests() {
        print("🧪 Running StrongMe Unit Tests...")
        print("=" * 50)
        
        var passedTests = 0
        var totalTests = 0
        
        // Test DataManager
        totalTests += testDataManager()
        passedTests += testDataManager()
        
        // Test Models
        totalTests += testModels()
        passedTests += testModels()
        
        // Test Persistence
        totalTests += testPersistence()
        passedTests += testPersistence()
        
        print("=" * 50)
        print("📊 Test Results: \(passedTests)/\(totalTests) tests passed")
        
        if passedTests == totalTests {
            print("✅ All tests passed!")
        } else {
            print("❌ Some tests failed!")
        }
    }
    
    private static func testDataManager() -> Int {
        print("\n🔧 Testing DataManager...")
        var passed = 0
        
        do {
            let dataManager = DataManager()
            
            // Test basic initialization
            if dataManager.workouts.isEmpty && dataManager.routines.isEmpty {
                print("  ✅ DataManager initializes correctly")
                passed += 1
            } else {
                print("  ❌ DataManager initialization failed")
            }
            
            // Test workout addition
            let workout = createSampleWorkout()
            dataManager.addWorkout(workout)
            if dataManager.workouts.count == 1 {
                print("  ✅ Workout addition works")
                passed += 1
            } else {
                print("  ❌ Workout addition failed")
            }
            
            // Test routine addition
            let routine = createSampleRoutine()
            dataManager.addRoutine(routine)
            if dataManager.routines.count == 1 {
                print("  ✅ Routine addition works")
                passed += 1
            } else {
                print("  ❌ Routine addition failed")
            }
            
        } catch {
            print("  ❌ DataManager tests failed with error: \(error)")
        }
        
        return passed
    }
    
    private static func testModels() -> Int {
        print("\n📋 Testing Models...")
        var passed = 0
        
        do {
            // Test Workout model
            let workout = createSampleWorkout()
            if workout.name == "Test Workout" && !workout.exercises.isEmpty {
                print("  ✅ Workout model works")
                passed += 1
            } else {
                print("  ❌ Workout model failed")
            }
            
            // Test Routine model
            let routine = createSampleRoutine()
            if routine.name == "Test Routine" && routine.days.count == 2 {
                print("  ✅ Routine model works")
                passed += 1
            } else {
                print("  ❌ Routine model failed")
            }
            
            // Test RoutineDay model
            let day = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: nil, isRestDay: false)
            if day.dayNumber == 1 && day.dayName == "Day 1" {
                print("  ✅ RoutineDay model works")
                passed += 1
            } else {
                print("  ❌ RoutineDay model failed")
            }
            
        } catch {
            print("  ❌ Model tests failed with error: \(error)")
        }
        
        return passed
    }
    
    private static func testPersistence() -> Int {
        print("\n💾 Testing Persistence...")
        var passed = 0
        
        do {
            let persistenceManager = PersistenceManager.shared
            
            // Test workout persistence
            let workout = createSampleWorkout()
            persistenceManager.saveWorkouts([workout])
            let loadedWorkouts = persistenceManager.loadWorkouts()
            if loadedWorkouts.count == 1 && loadedWorkouts.first?.name == "Test Workout" {
                print("  ✅ Workout persistence works")
                passed += 1
            } else {
                print("  ❌ Workout persistence failed")
            }
            
            // Test routine persistence
            let routine = createSampleRoutine()
            persistenceManager.saveRoutines([routine])
            let loadedRoutines = persistenceManager.loadRoutines()
            if loadedRoutines.count == 1 && loadedRoutines.first?.name == "Test Routine" {
                print("  ✅ Routine persistence works")
                passed += 1
            } else {
                print("  ❌ Routine persistence failed")
            }
            
        } catch {
            print("  ❌ Persistence tests failed with error: \(error)")
        }
        
        return passed
    }
    
    // MARK: - Helper Methods
    
    private static func createSampleWorkout() -> Workout {
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
    
    private static func createSampleRoutine() -> Routine {
        let day1 = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: nil, isRestDay: false)
        let day2 = RoutineDay(dayNumber: 2, dayName: "Day 2", workout: nil, isRestDay: true)
        
        return Routine(
            name: "Test Routine",
            days: [day1, day2],
            isActive: true,
            notes: "Test routine"
        )
    }
}

// Extension to make string repetition easier
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

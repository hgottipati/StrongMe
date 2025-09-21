//
//  PersistenceManagerTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
@testable import StrongMe
@testable import StrongMe

class PersistenceManagerTests: XCTestCase {
    var persistenceManager: PersistenceManager!
    
    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager.shared
        
        // Clear any existing data for clean tests
        UserDefaults.standard.removeObject(forKey: "workouts")
        UserDefaults.standard.removeObject(forKey: "routines")
        UserDefaults.standard.removeObject(forKey: "exercises")
        UserDefaults.standard.removeObject(forKey: "user")
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "workouts")
        UserDefaults.standard.removeObject(forKey: "routines")
        UserDefaults.standard.removeObject(forKey: "exercises")
        UserDefaults.standard.removeObject(forKey: "user")
        
        persistenceManager = nil
        super.tearDown()
    }
    
    // MARK: - Workout Persistence Tests
    
    func testSaveAndLoadWorkouts() {
        // Given
        let workout = createSampleWorkout()
        let workouts = [workout]
        
        // When
        persistenceManager.saveWorkouts(workouts)
        let loadedWorkouts = persistenceManager.loadWorkouts()
        
        // Then
        XCTAssertEqual(loadedWorkouts.count, 1)
        XCTAssertEqual(loadedWorkouts.first?.name, workout.name)
        XCTAssertEqual(loadedWorkouts.first?.exercises.count, workout.exercises.count)
    }
    
    func testSaveEmptyWorkouts() {
        // Given
        let workouts: [Workout] = []
        
        // When
        persistenceManager.saveWorkouts(workouts)
        let loadedWorkouts = persistenceManager.loadWorkouts()
        
        // Then
        XCTAssertEqual(loadedWorkouts.count, 0)
    }
    
    func testLoadWorkoutsWhenNoneExist() {
        // When
        let loadedWorkouts = persistenceManager.loadWorkouts()
        
        // Then
        XCTAssertEqual(loadedWorkouts.count, 0)
    }
    
    // MARK: - Routine Persistence Tests
    
    func testSaveAndLoadRoutines() {
        // Given
        let routine = createSampleRoutine()
        let routines = [routine]
        
        // When
        persistenceManager.saveRoutines(routines)
        let loadedRoutines = persistenceManager.loadRoutines()
        
        // Then
        XCTAssertEqual(loadedRoutines.count, 1)
        XCTAssertEqual(loadedRoutines.first?.name, routine.name)
        XCTAssertEqual(loadedRoutines.first?.days.count, routine.days.count)
    }
    
    func testSaveEmptyRoutines() {
        // Given
        let routines: [Routine] = []
        
        // When
        persistenceManager.saveRoutines(routines)
        let loadedRoutines = persistenceManager.loadRoutines()
        
        // Then
        XCTAssertEqual(loadedRoutines.count, 0)
    }
    
    func testLoadRoutinesWhenNoneExist() {
        // When
        let loadedRoutines = persistenceManager.loadRoutines()
        
        // Then
        XCTAssertEqual(loadedRoutines.count, 0)
    }
    
    // MARK: - Exercise Persistence Tests
    
    func testSaveAndLoadExercises() {
        // Given
        let exercise = createSampleExercise()
        let exercises = [exercise]
        
        // When
        persistenceManager.saveExercises(exercises)
        let loadedExercises = persistenceManager.loadExercises()
        
        // Then
        XCTAssertEqual(loadedExercises.count, 1)
        XCTAssertEqual(loadedExercises.first?.name, exercise.name)
        XCTAssertEqual(loadedExercises.first?.muscleGroups.count, exercise.muscleGroups.count)
    }
    
    func testSaveEmptyExercises() {
        // Given
        let exercises: [Exercise] = []
        
        // When
        persistenceManager.saveExercises(exercises)
        let loadedExercises = persistenceManager.loadExercises()
        
        // Then
        XCTAssertEqual(loadedExercises.count, 0)
    }
    
    func testLoadExercisesWhenNoneExist() {
        // When
        let loadedExercises = persistenceManager.loadExercises()
        
        // Then
        XCTAssertEqual(loadedExercises.count, 0)
    }
    
    // MARK: - User Persistence Tests
    
    func testSaveAndLoadUser() {
        // Given
        let user = createSampleUser()
        
        // When
        persistenceManager.saveUser(user)
        let loadedUser = persistenceManager.loadUser()
        
        // Then
        XCTAssertNotNil(loadedUser)
        XCTAssertEqual(loadedUser?.name, user.name)
        XCTAssertEqual(loadedUser?.email, user.email)
        XCTAssertEqual(loadedUser?.weight, user.weight)
        XCTAssertEqual(loadedUser?.height, user.height)
    }
    
    func testLoadUserWhenNoneExists() {
        // When
        let loadedUser = persistenceManager.loadUser()
        
        // Then
        XCTAssertNil(loadedUser)
    }
    
    // MARK: - Data Integrity Tests
    
    func testMultipleWorkoutsPersistence() {
        // Given
        let workout1 = createSampleWorkout(name: "Workout 1")
        let workout2 = createSampleWorkout(name: "Workout 2")
        let workouts = [workout1, workout2]
        
        // When
        persistenceManager.saveWorkouts(workouts)
        let loadedWorkouts = persistenceManager.loadWorkouts()
        
        // Then
        XCTAssertEqual(loadedWorkouts.count, 2)
        XCTAssertTrue(loadedWorkouts.contains { $0.name == "Workout 1" })
        XCTAssertTrue(loadedWorkouts.contains { $0.name == "Workout 2" })
    }
    
    func testMultipleRoutinesPersistence() {
        // Given
        let routine1 = createSampleRoutine(name: "Routine 1")
        let routine2 = createSampleRoutine(name: "Routine 2")
        let routines = [routine1, routine2]
        
        // When
        persistenceManager.saveRoutines(routines)
        let loadedRoutines = persistenceManager.loadRoutines()
        
        // Then
        XCTAssertEqual(loadedRoutines.count, 2)
        XCTAssertTrue(loadedRoutines.contains { $0.name == "Routine 1" })
        XCTAssertTrue(loadedRoutines.contains { $0.name == "Routine 2" })
    }
    
    func testComplexWorkoutPersistence() {
        // Given
        let exercise1 = createSampleExercise(name: "Push Up")
        let exercise2 = createSampleExercise(name: "Squat")
        
        let workoutExercise1 = WorkoutExercise(
            exercise: exercise1,
            sets: [
                Set(reps: 10, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 1),
                Set(reps: 12, weight: nil, duration: nil, distance: nil, restTime: 60, isCompleted: false, order: 2)
            ],
            notes: "Push up sets",
            order: 1
        )
        
        let workoutExercise2 = WorkoutExercise(
            exercise: exercise2,
            sets: [
                Set(reps: 15, weight: 50.0, duration: nil, distance: nil, restTime: 90, isCompleted: false, order: 1)
            ],
            notes: "Squat sets",
            order: 2
        )
        
        let workout = Workout(
            name: "Complex Workout",
            exercises: [workoutExercise1, workoutExercise2],
            date: Date(),
            duration: 1800, // 30 minutes
            notes: "A complex workout with multiple exercises",
            isTemplate: true
        )
        
        // When
        persistenceManager.saveWorkouts([workout])
        let loadedWorkouts = persistenceManager.loadWorkouts()
        
        // Then
        XCTAssertEqual(loadedWorkouts.count, 1)
        let loadedWorkout = loadedWorkouts.first!
        XCTAssertEqual(loadedWorkout.name, "Complex Workout")
        XCTAssertEqual(loadedWorkout.exercises.count, 2)
        XCTAssertEqual(loadedWorkout.exercises.first?.exercise.name, "Push Up")
        XCTAssertEqual(loadedWorkout.exercises.first?.sets.count, 2)
        XCTAssertEqual(loadedWorkout.exercises.last?.exercise.name, "Squat")
        XCTAssertEqual(loadedWorkout.exercises.last?.sets.count, 1)
        XCTAssertEqual(loadedWorkout.duration, 1800)
        XCTAssertTrue(loadedWorkout.isTemplate)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleExercise(name: String = "Push Up") -> Exercise {
        return Exercise(
            name: name,
            description: "A basic \(name.lowercased()) exercise",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight,
            difficulty: .beginner
        )
    }
    
    private func createSampleWorkout(name: String = "Test Workout") -> Workout {
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
            name: name,
            exercises: [workoutExercise],
            date: Date(),
            duration: nil,
            notes: "Test workout",
            isTemplate: false
        )
    }
    
    private func createSampleRoutine(name: String = "Test Routine") -> Routine {
        let day1 = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: createSampleWorkout(), isRestDay: false)
        let day2 = RoutineDay(dayNumber: 2, dayName: "Day 2", workout: nil, isRestDay: true)
        
        return Routine(
            name: name,
            days: [day1, day2],
            isActive: true,
            notes: "Test routine"
        )
    }
    
    private func createSampleUser() -> User {
        return User(
            name: "Test User",
            email: "test@example.com",
            weight: 70.0,
            height: 175.0,
            fitnessGoals: [.strength, .muscleGain],
            workoutPreferences: WorkoutPreferences()
        )
    }
}

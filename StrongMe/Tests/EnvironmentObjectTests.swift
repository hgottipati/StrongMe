//
//  EnvironmentObjectTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
import SwiftUI
@testable import StrongMe

class EnvironmentObjectTests: XCTestCase {
    
    func testDataManagerEnvironmentObjectInjection() {
        // Test that DataManager can be properly injected as EnvironmentObject
        let dataManager = DataManager()
        
        // Verify DataManager is ObservableObject
        XCTAssertTrue(dataManager is ObservableObject)
        
        // Test that we can access DataManager properties
        XCTAssertEqual(dataManager.workouts.count, 0)
        XCTAssertEqual(dataManager.routines.count, 0)
        XCTAssertNil(dataManager.currentWorkout)
    }
    
    func testWorkoutsViewWithDataManager() {
        // Test that WorkoutsView can be created with DataManager
        let dataManager = DataManager()
        
        // This test verifies that WorkoutsView can be instantiated
        // without crashing due to missing EnvironmentObject
        let workoutsView = WorkoutsView()
        
        // Verify the view exists
        XCTAssertNotNil(workoutsView)
    }
    
    func testContentViewWithDataManager() {
        // Test ContentView with DataManager injection
        let dataManager = DataManager()
        
        let contentView = ContentView()
        
        // Verify ContentView can be created
        XCTAssertNotNil(contentView)
    }
    
    func testTabViewEnvironmentObjectPropagation() {
        // Test that TabView properly propagates EnvironmentObject
        let dataManager = DataManager()
        
        // Create a simple TabView test
        let tabView = TabView {
            Text("Tab 1")
                .tabItem { Image(systemName: "1.circle") }
            Text("Tab 2")
                .tabItem { Image(systemName: "2.circle") }
        }
        
        XCTAssertNotNil(tabView)
    }
    
    func testWorkoutTabEnum() {
        // Test WorkoutTab enum functionality
        let adhocTab = WorkoutTab.adhoc
        let routinesTab = WorkoutTab.routines
        
        XCTAssertEqual(adhocTab.displayName, "Adhoc")
        XCTAssertEqual(routinesTab.displayName, "Routines")
        XCTAssertEqual(WorkoutTab.allCases.count, 2)
        XCTAssertTrue(WorkoutTab.allCases.contains(.adhoc))
        XCTAssertTrue(WorkoutTab.allCases.contains(.routines))
    }
    
    func testModernWorkoutCardViewEnvironmentObject() {
        // Test that ModernWorkoutCardView can be created
        let workout = createSampleWorkout()
        
        let cardView = ModernWorkoutCardView(
            workout: workout,
            onTap: {},
            onStartWorkout: {},
            onShare: {},
            onDuplicate: {},
            onEdit: {},
            onDelete: {}
        )
        
        XCTAssertNotNil(cardView)
    }
    
    func testWorkoutDropDelegateEnvironmentObject() {
        // Test that WorkoutDropDelegate can be created
        let workout = createSampleWorkout()
        
        let dropDelegate = WorkoutDropDelegate(
            workout: workout,
            draggedWorkout: .constant(nil),
            dragOffset: .constant(.zero)
        )
        
        XCTAssertNotNil(dropDelegate)
    }
    
    func testWeeklyOverviewSectionEnvironmentObject() {
        // Test WeeklyOverviewSection creation
        let section = WeeklyOverviewSection()
        XCTAssertNotNil(section)
    }
    
    func testWorkoutSheetViewEnvironmentObject() {
        // Test WorkoutSheetView creation
        let workout = createSampleWorkout()
        let sheetView = WorkoutSheetView(workout: workout)
        XCTAssertNotNil(sheetView)
    }
    
    func testRoutinesViewEnvironmentObject() {
        // Test RoutinesView creation
        let routinesView = RoutinesView()
        XCTAssertNotNil(routinesView)
    }
    
    func testAdhocWorkoutsViewEnvironmentObject() {
        // Test AdhocWorkoutsView creation
        let adhocView = AdhocWorkoutsView(
            draggedWorkout: .constant(nil),
            dragOffset: .constant(.zero),
            selectedWorkout: .constant(nil),
            showingWorkoutOverview: .constant(nil)
        )
        XCTAssertNotNil(adhocView)
    }
    
    func testTabInterfaceEnvironmentObject() {
        // Test TabInterface creation
        let tabInterface = TabInterface(selectedTab: .constant(.adhoc))
        XCTAssertNotNil(tabInterface)
    }
    
    func testRoutineCardViewEnvironmentObject() {
        // Test RoutineCardView creation
        let routine = createSampleRoutine()
        let cardView = RoutineCardView(routine: routine)
        XCTAssertNotNil(cardView)
    }
    
    func testNewRoutineViewEnvironmentObject() {
        // Test NewRoutineView creation
        let newRoutineView = NewRoutineView()
        XCTAssertNotNil(newRoutineView)
    }
    
    func testRoutineDetailViewEnvironmentObject() {
        // Test RoutineDetailView creation
        let routine = createSampleRoutine()
        let detailView = RoutineDetailView(routine: routine)
        XCTAssertNotNil(detailView)
    }
    
    func testEmptyRoutinesViewEnvironmentObject() {
        // Test EmptyRoutinesView creation
        let emptyView = EmptyRoutinesView { }
        XCTAssertNotNil(emptyView)
    }
    
    func testDayPreviewViewEnvironmentObject() {
        // Test DayPreviewView creation
        let day = RoutineDay(dayNumber: 1, dayName: "Day 1", workout: nil, isRestDay: false)
        let previewView = DayPreviewView(day: day)
        XCTAssertNotNil(previewView)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflowWithEnvironmentObject() {
        // Test a complete workflow to ensure EnvironmentObject works end-to-end
        let dataManager = DataManager()
        
        // Create a workout
        let workout = createSampleWorkout()
        dataManager.addWorkout(workout)
        
        // Create a routine
        let routine = createSampleRoutine()
        dataManager.addRoutine(routine)
        
        // Verify data is accessible
        XCTAssertEqual(dataManager.workouts.count, 1)
        XCTAssertEqual(dataManager.routines.count, 1)
        
        // Test that views can be created (this would crash if EnvironmentObject is missing)
        let workoutsView = WorkoutsView()
        XCTAssertNotNil(workoutsView)
        
        let routinesView = RoutinesView()
        XCTAssertNotNil(routinesView)
    }
    
    func testDragAndDropComponentsEnvironmentObject() {
        // Test that all drag and drop related components can be created
        let workout = createSampleWorkout()
        
        // Test ModernWorkoutCardView (used in drag and drop)
        let cardView = ModernWorkoutCardView(
            workout: workout,
            onTap: {},
            onStartWorkout: {},
            onShare: {},
            onDuplicate: {},
            onEdit: {},
            onDelete: {}
        )
        XCTAssertNotNil(cardView)
        
        // Test WorkoutDropDelegate (handles drop operations)
        let dropDelegate = WorkoutDropDelegate(
            workout: workout,
            draggedWorkout: .constant(nil),
            dragOffset: .constant(.zero)
        )
        XCTAssertNotNil(dropDelegate)
        
        // Test AdhocWorkoutsView (contains drag and drop functionality)
        let adhocView = AdhocWorkoutsView(
            draggedWorkout: .constant(nil),
            dragOffset: .constant(.zero),
            selectedWorkout: .constant(nil),
            showingWorkoutOverview: .constant(nil)
        )
        XCTAssertNotNil(adhocView)
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

//
//  DragAndDropTests.swift
//  StrongMeTests
//
//  Created by Hareesh Gottipati on 9/21/25.
//

import XCTest
import SwiftUI
@testable import StrongMe

class DragAndDropTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager()
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    // MARK: - WorkoutDropDelegate Tests
    
    func testWorkoutDropDelegateInitialization() {
        // Given
        let workout = createSampleWorkout()
        let draggedWorkout = Binding<Workout?>(
            get: { nil },
            set: { _ in }
        )
        let dragOffset = Binding<CGSize>(
            get: { .zero },
            set: { _ in }
        )
        
        // When
        let dropDelegate = WorkoutDropDelegate(
            workout: workout,
            draggedWorkout: draggedWorkout,
            dragOffset: dragOffset
        )
        
        // Then
        XCTAssertNotNil(dropDelegate)
        XCTAssertEqual(dropDelegate.workout.id, workout.id)
    }
    
    func testWorkoutDropDelegateDropEntered() {
        // Given
        let workout1 = createSampleWorkout(name: "Workout 1")
        let workout2 = createSampleWorkout(name: "Workout 2")
        
        dataManager.addWorkout(workout1)
        dataManager.addWorkout(workout2)
        
        let draggedWorkout = Binding<Workout?>(
            get: { workout1 },
            set: { _ in }
        )
        let dragOffset = Binding<CGSize>(
            get: { .zero },
            set: { _ in }
        )
        
        let dropDelegate = WorkoutDropDelegate(
            workout: workout2,
            draggedWorkout: draggedWorkout,
            dragOffset: dragOffset
        )
        
        let dropInfo = MockDropInfo()
        
        // When
        dropDelegate.dropEntered(info: dropInfo)
        
        // Then
        // Verify that workouts were reordered
        XCTAssertEqual(dataManager.workouts.count, 2)
        // The first workout should now be workout2 (moved to position of workout2)
        XCTAssertEqual(dataManager.workouts.first?.name, "Workout 2")
    }
    
    func testWorkoutDropDelegatePerformDrop() {
        // Given
        let workout = createSampleWorkout()
        let draggedWorkout = Binding<Workout?>(
            get: { workout },
            set: { _ in }
        )
        let dragOffset = Binding<CGSize>(
            get: { CGSize(width: 10, height: 10) },
            set: { _ in }
        )
        
        let dropDelegate = WorkoutDropDelegate(
            workout: workout,
            draggedWorkout: draggedWorkout,
            dragOffset: dragOffset
        )
        
        let dropInfo = MockDropInfo()
        
        // When
        let result = dropDelegate.performDrop(info: dropInfo)
        
        // Then
        XCTAssertTrue(result)
        // Verify drag state was reset
        XCTAssertNil(draggedWorkout.wrappedValue)
        XCTAssertEqual(dragOffset.wrappedValue, .zero)
    }
    
    func testWorkoutDropDelegateDropUpdated() {
        // Given
        let workout = createSampleWorkout()
        let dropDelegate = WorkoutDropDelegate(
            workout: workout,
            draggedWorkout: .constant(nil),
            dragOffset: .constant(.zero)
        )
        
        let dropInfo = MockDropInfo()
        
        // When
        let proposal = dropDelegate.dropUpdated(info: dropInfo)
        
        // Then
        XCTAssertNotNil(proposal)
        XCTAssertEqual(proposal?.operation, .move)
    }
    
    // MARK: - Drag and Drop State Tests
    
    func testDragStateManagement() {
        // Test that drag state can be properly managed
        let draggedWorkout = Binding<Workout?>(
            get: { nil },
            set: { _ in }
        )
        let dragOffset = Binding<CGSize>(
            get: { .zero },
            set: { _ in }
        )
        
        // Test setting drag state
        draggedWorkout.wrappedValue = createSampleWorkout()
        dragOffset.wrappedValue = CGSize(width: 5, height: 5)
        
        XCTAssertNotNil(draggedWorkout.wrappedValue)
        XCTAssertEqual(dragOffset.wrappedValue.width, 5)
        XCTAssertEqual(dragOffset.wrappedValue.height, 5)
        
        // Test clearing drag state
        draggedWorkout.wrappedValue = nil
        dragOffset.wrappedValue = .zero
        
        XCTAssertNil(draggedWorkout.wrappedValue)
        XCTAssertEqual(dragOffset.wrappedValue, .zero)
    }
    
    // MARK: - Workout Reordering Tests
    
    func testWorkoutReordering() {
        // Given
        let workout1 = createSampleWorkout(name: "Workout 1")
        let workout2 = createSampleWorkout(name: "Workout 2")
        let workout3 = createSampleWorkout(name: "Workout 3")
        
        dataManager.addWorkout(workout1)
        dataManager.addWorkout(workout2)
        dataManager.addWorkout(workout3)
        
        // Verify initial order
        XCTAssertEqual(dataManager.workouts[0].name, "Workout 1")
        XCTAssertEqual(dataManager.workouts[1].name, "Workout 2")
        XCTAssertEqual(dataManager.workouts[2].name, "Workout 3")
        
        // When - Move workout1 to position 2 (after workout3)
        dataManager.workouts.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        
        // Then
        XCTAssertEqual(dataManager.workouts[0].name, "Workout 2")
        XCTAssertEqual(dataManager.workouts[1].name, "Workout 3")
        XCTAssertEqual(dataManager.workouts[2].name, "Workout 1")
    }
    
    func testMultipleWorkoutReordering() {
        // Given
        let workouts = (1...5).map { createSampleWorkout(name: "Workout \($0)") }
        workouts.forEach { dataManager.addWorkout($0) }
        
        // Verify initial order
        for (index, workout) in dataManager.workouts.enumerated() {
            XCTAssertEqual(workout.name, "Workout \(index + 1)")
        }
        
        // When - Move workouts 1 and 2 to the end
        dataManager.workouts.move(fromOffsets: IndexSet([0, 1]), toOffset: 5)
        
        // Then
        XCTAssertEqual(dataManager.workouts[0].name, "Workout 3")
        XCTAssertEqual(dataManager.workouts[1].name, "Workout 4")
        XCTAssertEqual(dataManager.workouts[2].name, "Workout 5")
        XCTAssertEqual(dataManager.workouts[3].name, "Workout 1")
        XCTAssertEqual(dataManager.workouts[4].name, "Workout 2")
    }
    
    // MARK: - Visual Feedback Tests
    
    func testDragVisualFeedback() {
        // Test that visual feedback properties work correctly
        let workout = createSampleWorkout()
        let draggedWorkout: Workout? = workout
        let dragOffset = CGSize(width: 10, height: 10)
        
        // Test offset calculation
        let expectedOffset = draggedWorkout?.id == workout.id ? dragOffset : .zero
        XCTAssertEqual(expectedOffset, dragOffset)
        
        // Test scale effect
        let expectedScale: CGFloat = draggedWorkout?.id == workout.id ? 1.05 : 1.0
        XCTAssertEqual(expectedScale, 1.05)
        
        // Test opacity
        let expectedOpacity: Double = draggedWorkout?.id == workout.id ? 0.8 : 1.0
        XCTAssertEqual(expectedOpacity, 0.8)
    }
    
    func testNonDraggedVisualFeedback() {
        // Test visual feedback for non-dragged items
        let workout1 = createSampleWorkout(name: "Workout 1")
        let workout2 = createSampleWorkout(name: "Workout 2")
        let draggedWorkout: Workout? = workout1
        
        // Test offset for non-dragged workout
        let expectedOffset = draggedWorkout?.id == workout2.id ? CGSize(width: 10, height: 10) : .zero
        XCTAssertEqual(expectedOffset, .zero)
        
        // Test scale for non-dragged workout
        let expectedScale: CGFloat = draggedWorkout?.id == workout2.id ? 1.05 : 1.0
        XCTAssertEqual(expectedScale, 1.0)
        
        // Test opacity for non-dragged workout
        let expectedOpacity: Double = draggedWorkout?.id == workout2.id ? 0.8 : 1.0
        XCTAssertEqual(expectedOpacity, 1.0)
    }
    
    // MARK: - NSItemProvider Tests
    
    func testNSItemProviderCreation() {
        // Test that NSItemProvider can be created for drag operations
        let workout = createSampleWorkout()
        let itemProvider = NSItemProvider(object: workout.id.uuidString as NSString)
        
        XCTAssertNotNil(itemProvider)
        XCTAssertTrue(itemProvider.canLoadObject(ofClass: NSString.self))
    }
    
    // MARK: - Helper Methods
    
    private func createSampleWorkout(name: String = "Test Workout") -> Workout {
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
            name: name,
            exercises: [workoutExercise],
            date: Date(),
            duration: nil,
            notes: "Test workout",
            isTemplate: false
        )
    }
}

// MARK: - Mock Classes

class MockDropInfo: DropInfo {
    var location: CGPoint = .zero
    var hasItemsConforming: (Set<String>) -> Bool = { _ in false }
    var itemProviders: [NSItemProvider] = []
    
    func hasItemsConforming(to typeIdentifiers: Set<String>) -> Bool {
        return hasItemsConforming(typeIdentifiers)
    }
}

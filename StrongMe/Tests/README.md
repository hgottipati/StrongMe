# StrongMe Unit Tests

This directory contains comprehensive unit tests for the StrongMe app to ensure code quality and prevent regressions.

## Test Structure

### Core Test Files

1. **StrongMeTests.swift** - Main test suite with basic functionality tests
2. **DataManagerTests.swift** - Tests for DataManager core functionality
3. **WorkoutModelTests.swift** - Tests for Workout, Routine, and related models
4. **PersistenceManagerTests.swift** - Tests for data persistence layer
5. **EnvironmentObjectTests.swift** - Tests for EnvironmentObject injection and SwiftUI architecture
6. **DragAndDropTests.swift** - Tests for drag and drop functionality and reordering
7. **TestRunner.swift** - Manual test runner for verification

## Test Coverage

### DataManager Tests
- ✅ Workout management (add, delete, save, start, end)
- ✅ Routine management (add, update, delete)
- ✅ Exercise library search
- ✅ Data persistence integration

### Model Tests
- ✅ Workout model initialization and properties
- ✅ Routine model with multiple days
- ✅ RoutineDay model with workout assignments
- ✅ Set model with all properties
- ✅ Codable conformance for all models

### Persistence Tests
- ✅ Workout save/load operations
- ✅ Routine save/load operations
- ✅ Exercise save/load operations
- ✅ User save/load operations
- ✅ Empty data handling
- ✅ Complex data structures
- ✅ Data integrity verification

### EnvironmentObject Tests
- ✅ DataManager EnvironmentObject injection
- ✅ SwiftUI view hierarchy with EnvironmentObject
- ✅ TabView EnvironmentObject propagation
- ✅ All view components with EnvironmentObject
- ✅ Drag and drop components EnvironmentObject
- ✅ Complete workflow integration tests

### Drag and Drop Tests
- ✅ WorkoutDropDelegate functionality
- ✅ Drag state management
- ✅ Workout reordering operations
- ✅ Visual feedback calculations
- ✅ NSItemProvider creation
- ✅ Multiple workout reordering
- ✅ Drop operations and haptic feedback

## Running Tests

### In Xcode
1. Open the project in Xcode
2. Select the test target
3. Press Cmd+U to run all tests

### Manual Verification
The `TestRunner.swift` provides a simple way to verify basic functionality without Xcode.

## Test Principles

1. **Isolation**: Each test is independent and doesn't affect others
2. **Clean State**: Tests clean up after themselves
3. **Comprehensive**: Tests cover happy path, edge cases, and error conditions
4. **Readable**: Tests clearly show what is being tested and expected results

## Adding New Tests

When adding new features:

1. **Add model tests** for any new data structures
2. **Add DataManager tests** for new business logic
3. **Add persistence tests** for new data storage
4. **Update integration tests** for new workflows

## Regression Prevention

These tests help prevent regressions by:

- ✅ Verifying core functionality works after changes
- ✅ Ensuring data models remain consistent
- ✅ Validating persistence layer integrity
- ✅ Confirming business logic correctness

## Build Verification

**IMPORTANT**: Before committing any changes, ensure:

1. All tests pass
2. No linting errors
3. Successful build in Xcode
4. No breaking changes to existing functionality

This test suite provides confidence that the app's core functionality remains stable as new features are added.

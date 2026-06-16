import Foundation
import Combine

// We can run this script using `swift scratch/TestSuite.swift Sources/PetStateMachine.swift`

func runTests() {
    print("Starting Test Suite...")
    var failures = 0
    
    func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
        if actual != expected {
            print("❌ FAILED: \(message) - Expected \(expected), got \(actual)")
            failures += 1
        } else {
            print("✅ PASSED: \(message)")
        }
    }
    
    // Create state machine
    let sm = PetStateMachine()
    
    // Test 1: Idle priority
    assertEqual(sm.currentState, .idle, "Initial state should be idle")
    
    // Test 2: Typing vs Looking (Looking = 50, Typing = 60)
    sm.registerKeystroke()
    
    // Wait for async queue to flush
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    
    if case .typing = sm.currentState {
        print("✅ PASSED: Transition to typing")
    } else {
        print("❌ FAILED: Transition to typing")
        failures += 1
    }
    
    sm.updateDirection(to: .left)
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    if case .typing = sm.currentState {
        print("✅ PASSED: Looking (50) cannot override Typing (60)")
    } else {
        print("❌ FAILED: Looking overrode Typing")
        failures += 1
    }
    
    // Test 3: Stop typing
    // Wait for typing timer (0.5s) to expire
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
    assertEqual(sm.currentState, .idle, "State should return to idle after typing stops")
    
    // Test 4: Water vs Stretch Reminder priority (Water = 80, Stretch = 90)
    // Force set intervals to tiny values
    sm.stretchInterval = .custom(1)
    sm.waterInterval = .custom(1)
    
    // Wait 2.1 seconds for 2 timer ticks
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2.1))
    
    if case .stretchReminder = sm.currentState {
        print("✅ PASSED: Stretch reminder takes priority when both trigger")
    } else {
        print("❌ FAILED: Stretch reminder did not take priority over water. State is \(sm.currentState)")
        failures += 1
    }
    
    // Ensure water doesn't override stretch
    // updateWaterReminder is called by timer
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.1))
    if case .stretchReminder = sm.currentState {
        print("✅ PASSED: Water reminder (80) cannot override Stretch reminder (90)")
    } else {
        print("❌ FAILED: Water reminder overrode Stretch reminder")
        failures += 1
    }
    
    // Test 5: Dragging overrides Stretch
    sm.startDragging()
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    if case .dragging = sm.currentState {
        print("✅ PASSED: Dragging (100) overrides Stretch reminder (90)")
    } else {
        print("❌ FAILED: Dragging did not override Stretch reminder")
        failures += 1
    }
    
    // Acknowledge stretch while dragging (simulating click)
    sm.acknowledgeStretch()
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    if case .dragging = sm.currentState {
        print("✅ PASSED: Acknowledging stretch while dragging does not break dragging state")
    } else {
        print("❌ FAILED: Acknowledging stretch broke dragging state")
        failures += 1
    }
    
    // Stop dragging
    sm.stopDragging()
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    assertEqual(sm.currentState, .idle, "State should return to idle after dragging stops")
    
    print("---")
    if failures == 0 {
        print("🎉 ALL TESTS PASSED!")
        exit(0)
    } else {
        print("💥 \(failures) TESTS FAILED!")
        exit(1)
    }
}

@main
struct TestSuiteRunner {
    static func main() {
        runTests()
    }
}

import Foundation

enum PetState {
    case idle
    case looking(Direction)
    case dragging
}

enum Direction {
    case up, down, left, right, upLeft, upRight, downLeft, downRight, center
}

class PetStateMachine: ObservableObject {
    @Published var currentState: PetState = .idle
    
    private var lastDirectionChange: Date = Date()
    private let debounceInterval: TimeInterval = 0.05
    
    func updateDirection(to newDirection: Direction) {
        if case .dragging = currentState {
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastDirectionChange) > debounceInterval {
            if case .looking(let currentDir) = currentState, currentDir == newDirection {
                return
            }
            currentState = .looking(newDirection)
            lastDirectionChange = now
        }
    }
    
    func startDragging() {
        currentState = .dragging
    }
    
    func stopDragging() {
        currentState = .idle
    }
}

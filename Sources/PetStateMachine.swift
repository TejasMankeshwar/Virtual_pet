import Foundation

enum PetState: Equatable {
    case idle
    case looking(Direction)
    case dragging
    case typing(activePaw: PawSide)
    
    public static func == (lhs: PetState, rhs: PetState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.dragging, .dragging): return true
        case (.typing(let lPaw), .typing(let rPaw)): return lPaw == rPaw
        case (.looking(let lDir), .looking(let rDir)): return lDir == rDir
        default: return false
        }
    }
}

enum PawSide {
    case left, right
}

enum Direction {
    case up, down, left, right, upLeft, upRight, downLeft, downRight, center
}

class PetStateMachine: ObservableObject {
    @Published var currentState: PetState = .idle
    @Published var typingHeat: Double = 0.0 // 0.0 to 1.0
    
    private var lastDirectionChange: Date = Date()
    private let debounceInterval: TimeInterval = 0.05
    
    private var keystrokes: [Date] = []
    private var idleTimer: Timer?
    private var updateTimer: Timer?
    private var lastTypedPaw: PawSide = .right
    
    init() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.decayHeatAndVerifyState()
        }
    }
    
    func updateDirection(to newDirection: Direction) {
        if case .dragging = currentState {
            return
        }
        if case .typing = currentState {
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastDirectionChange) > debounceInterval {
            DispatchQueue.main.async {
                if case .looking(let currentDir) = self.currentState, currentDir == newDirection {
                    return
                }
                self.currentState = .looking(newDirection)
                self.lastDirectionChange = now
            }
        }
    }
    
    func startDragging() {
        DispatchQueue.main.async {
            self.currentState = .dragging
            self.typingHeat = 0.0
        }
    }
    
    func stopDragging() {
        DispatchQueue.main.async {
            // Only stop dragging if we are actually dragging (don't override typing)
            if case .dragging = self.currentState {
                self.currentState = .idle
            }
        }
    }
    
    func registerKeystroke() {
        let now = Date()
        keystrokes.append(now)
        
        let nextPaw: PawSide = (lastTypedPaw == .left) ? .right : .left
        lastTypedPaw = nextPaw
        
        DispatchQueue.main.async {
            // Typing overrides dragging or anything else! This prevents the cat from getting stuck in dragging state.
            self.currentState = .typing(activePaw: nextPaw)
            
            self.idleTimer?.invalidate()
            self.idleTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if case .typing = self.currentState {
                    self.currentState = .idle
                }
            }
            
            self.recalculateHeat()
        }
    }
    
    private func decayHeatAndVerifyState() {
        let now = Date()
        let beforeCount = keystrokes.count
        keystrokes = keystrokes.filter { now.timeIntervalSince($0) <= 2.0 }
        
        if beforeCount != keystrokes.count {
            DispatchQueue.main.async {
                self.recalculateHeat()
            }
        }
    }
    
    private func recalculateHeat() {
        let kps = Double(keystrokes.count) / 2.0
        
        if kps < 0.5 {
            typingHeat = 0.0
        } else if kps >= 4.0 {
            typingHeat = 1.0
        } else {
            typingHeat = (kps - 0.5) / 3.5
        }
    }
}

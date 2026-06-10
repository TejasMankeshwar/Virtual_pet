import Foundation
import SwiftUI

enum PetState: Equatable {
    case idle
    case looking(Direction)
    case dragging
    case typing(heat: Double)
    case petting
    case stretching
    case stretchReminder
}

enum StretchInterval: Equatable {
    case off
    case custom(Int)
    
    var rawValue: Int {
        switch self {
        case .off: return 0
        case .custom(let secs): return secs
        }
    }
}

enum PawSide: Equatable {
    case left
    case right
}

enum Direction {
    case up, down, left, right, upLeft, upRight, downLeft, downRight, center
}

class PetStateMachine: ObservableObject {
    @Published var currentState: PetState = .idle {
        didSet {
            let isStretching = (currentState == .stretching || currentState == .stretchReminder)
            let wasStretching = (oldValue == .stretching || oldValue == .stretchReminder)
            if isStretching != wasStretching {
                withAnimation(.easeInOut(duration: 0.3)) {
                    stretchColorAmount = isStretching ? 1.0 : 0.0
                }
            }
        }
    }
    @Published var isHiding: Bool = false
    @Published var isBlipping: Bool = false
    @Published var typingHeat: Double = 0.0 // 0.0 to 1.0
    
    @Published var stretchColorAmount: Double = 0.0
    @Published var wagTick: Bool = false
    @Published var lastTypedPaw: PawSide = .left
    
    @Published var purrMessage: String = ""
    @Published var showPurrMessage: Bool = false
    
    private var savedPurrMessage: String = ""
    private var savedShowPurrMessage: Bool = false
    
    @Published var isPomodoroActive: Bool = false
    @Published var pomodoroTimeRemaining: Int = 0
    private var pomodoroDuration: Int = 25 * 60
    
    @Published var stretchInterval: StretchInterval = .off {
        didSet {
            resetStretchTimer()
        }
    }
    @Published var timeUntilStretch: Int = 0

    private var lastDirectionChange: Date = Date()
    private let debounceInterval: TimeInterval = 0.05
    
    private var keystrokes: [Date] = []
    private var stateTimer: Timer?
    private var pettingTimer: Timer?
    private var lastInteractionTime: Date = Date()
    private var pettingAccumulator: CGFloat = 0
    private var pettingStartTime: Date?
    
    private var isCurrentlyTyping: Bool = false
    private var typingTimer: Timer?
    
    private var wagTimer: Timer?
    
    init() {
        stateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateTypingHeat()
            self.updatePomodoro()
            self.updateStretchReminder()
            
            // Random interactions roughly every 5 seconds
            if Int.random(in: 1...5) == 1 {
                self.updateIdleState()
            }
        }
        
        wagTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.wagTick.toggle()
        }
    }
    
    func registerInteraction() {
        lastInteractionTime = Date()
    }
    
    func registerPetting(delta: CGFloat) {
        registerInteraction()
        
        pettingAccumulator += delta
        
        pettingTimer?.invalidate()
        pettingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopPetting()
            }
        }
        
        if pettingStartTime == nil {
            pettingStartTime = Date()
        }
        
        if let startTime = pettingStartTime, Date().timeIntervalSince(startTime) >= 1.2 {
            if pettingAccumulator > 30 {
                DispatchQueue.main.async {
                    if self.currentState != .dragging && self.currentState != .petting {
                        if case .typing = self.currentState { return }
                        self.currentState = .petting
                    }
                }
            }
        }
    }
    
    func stopPetting() {
        pettingAccumulator = 0
        pettingStartTime = nil
        if case .petting = currentState {
            currentState = .idle
        }
    }
    
    func wakeUpIfNeeded() {
        if isHiding {
            DispatchQueue.main.async {
                self.isHiding = false
                if self.currentState != .stretchReminder {
                    self.currentState = .idle
                }
            }
        }
    }
    
    func startPomodoro() {
        DispatchQueue.main.async {
            self.isPomodoroActive = true
            self.pomodoroTimeRemaining = self.pomodoroDuration
        }
    }
    
    func stopPomodoro() {
        DispatchQueue.main.async {
            self.isPomodoroActive = false
        }
    }
    
    private func updatePomodoro() {
        guard isPomodoroActive else { return }
        if pomodoroTimeRemaining > 0 {
            pomodoroTimeRemaining -= 1
        } else if pomodoroTimeRemaining == 0 {
            isPomodoroActive = false
            purrMessage = "Pomodoro Done! 🐾"
            showPurrMessage = true
        }
    }
    
    private func updateStretchReminder() {
        if stretchInterval == .off { return }
        
        if timeUntilStretch > 0 {
            timeUntilStretch -= 1
        } else {
            if currentState != .stretchReminder {
                savedPurrMessage = purrMessage
                savedShowPurrMessage = showPurrMessage
                self.wakeUpIfNeeded()
                currentState = .stretchReminder
                purrMessage = "Time to stretch! 🐾"
                showPurrMessage = true
            }
        }
    }
    
    func resetStretchTimer() {
        let wasStretchReminder = (currentState == .stretchReminder)
        DispatchQueue.main.async {
            self.timeUntilStretch = self.stretchInterval.rawValue
            if wasStretchReminder {
                self.currentState = .idle
                self.purrMessage = self.savedPurrMessage
                self.showPurrMessage = self.savedShowPurrMessage
            }
        }
    }
    
    func acknowledgeStretch() {
        if currentState == .stretchReminder {
            resetStretchTimer()
        }
    }
    
    private func updateIdleState() {
        // Only trigger random states if we are currently idle and not blipping or hiding
        guard case .idle = currentState, !isHiding, !isBlipping else { return }
        
        // Very low chance to do a random stretch
        if Double.random(in: 0...1) < 0.05 {
            currentState = .stretching
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if case .stretching = self.currentState {
                    self.currentState = .idle
                }
            }
        }
    }
    
    func updateDirection(to newDirection: Direction) {
        registerInteraction()
        
        if case .dragging = currentState { return }
        if case .typing = currentState { return }
        if case .petting = currentState { return }
        if case .stretching = currentState { return }
        if case .stretchReminder = currentState { return }
        
        let now = Date()
        if now.timeIntervalSince(lastDirectionChange) > debounceInterval {
            DispatchQueue.main.async {
                self.currentState = .looking(newDirection)
                self.lastDirectionChange = now
            }
        }
    }
    
    func startDragging() {
        registerInteraction()
        DispatchQueue.main.async {
            self.currentState = .dragging
            self.typingHeat = 0.0
        }
    }
    
    func stopDragging() {
        DispatchQueue.main.async {
            if case .dragging = self.currentState {
                self.currentState = .idle
            }
        }
    }
    
    func registerKeystroke() {
        registerInteraction()
        wakeUpIfNeeded()
        let now = Date()
        keystrokes.append(now)
        
        lastTypedPaw = (lastTypedPaw == .left) ? .right : .left
        
        DispatchQueue.main.async {
            self.isCurrentlyTyping = true
            self.typingTimer?.invalidate()
            self.typingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isCurrentlyTyping = false
                    self?.updateTypingState()
                }
            }
            self.updateTypingHeat()
        }
    }
    
    private func updateTypingHeat() {
        let now = Date()
        keystrokes = keystrokes.filter { now.timeIntervalSince($0) <= 3.0 }
        
        DispatchQueue.main.async {
            self.recalculateHeat()
        }
        
        // Check for idle hiding
        if now.timeIntervalSince(lastInteractionTime) > 15.0 {
            DispatchQueue.main.async {
                if !self.isHiding && self.currentState != .dragging && self.currentState != .stretchReminder {
                    self.isHiding = true
                }
            }
        }
    }
    
    private func recalculateHeat() {
        let kps = Double(keystrokes.count) / 3.0
        
        let minKps = 1.25 // 15 WPM
        let maxKps = 5.83 // 70 WPM
        
        let newHeat: Double
        if kps < minKps {
            newHeat = 0.0
        } else if kps >= maxKps {
            newHeat = 1.0
        } else {
            newHeat = (kps - minKps) / (maxKps - minKps)
        }
        
        withAnimation(.linear(duration: 0.2)) {
            typingHeat = newHeat
        }
        
        updateTypingState()
    }
    
    private func updateTypingState() {
        if isCurrentlyTyping {
            if currentState != .stretchReminder && currentState != .dragging && currentState != .petting {
                currentState = .typing(heat: typingHeat)
            }
        } else {
            if case .typing = currentState {
                currentState = .idle
            }
        }
    }
}

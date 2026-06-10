import Cocoa

class GlobalEventTracker {
    private let stateMachine: PetStateMachine
    private weak var panel: NSPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var localKeyboardMonitor: Any?
    private var globalLeftMouseUpMonitor: Any?
    private var globalKeyboardTimer: Timer?
    private var lastKeyCount: UInt32 = 0
    private var lastMouseLoc: NSPoint?
    
    init(stateMachine: PetStateMachine, panel: NSPanel) {
        self.stateMachine = stateMachine
        self.panel = panel
    }
    
    func startTracking() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            print("Accessibility access not granted. Global event tracking (mouse + keyboard) requires permission.")
        } else {
            print("Accessibility access checked: Granted.")
        }
        
        // Mouse tracking
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
            return event
        }
        
        // Keyboard tracking using global HID counters (bulletproof, no permissions needed!)
        print("Starting bulletproof keyboard counter...")
        lastKeyCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
        globalKeyboardTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
            if currentCount > self.lastKeyCount {
                let diff = currentCount - self.lastKeyCount
                for _ in 0..<diff {
                    self.stateMachine.registerKeystroke()
                }
                self.lastKeyCount = currentCount
            }
        }
        
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("Local key down event captured.")
            self?.stateMachine.registerKeystroke()
            return event
        }
        
        globalLeftMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.stateMachine.stopDragging()
        }
    }
    
    func stopTracking() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
        globalKeyboardTimer?.invalidate()
        globalKeyboardTimer = nil
        
        if let monitor = localKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyboardMonitor = nil
        }
        if let monitor = globalLeftMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalLeftMouseUpMonitor = nil
        }
    }
    
    private func handleMouseMoved(event: NSEvent) {
        guard let panel = panel else { return }
        
        let mouseLoc = NSEvent.mouseLocation
        let panelFrame = panel.frame
        let center = CGPoint(x: panelFrame.midX, y: panelFrame.midY)
        
        let dx = mouseLoc.x - center.x
        let dy = mouseLoc.y - center.y
        
        let distance = sqrt(dx*dx + dy*dy)
        
        var delta: CGFloat = 0
        if let last = lastMouseLoc {
            delta = sqrt(pow(mouseLoc.x - last.x, 2) + pow(mouseLoc.y - last.y, 2))
        }
        lastMouseLoc = mouseLoc
        
        if distance < 60 {
            if delta > 0 {
                stateMachine.registerPetting(delta: delta)
            }
            stateMachine.updateDirection(to: .center)
            return
        } else {
            stateMachine.stopPetting()
        }
        
        let angle = atan2(dy, dx)
        let direction = angleToDirection(angle: angle)
        stateMachine.updateDirection(to: direction)
    }
    
    private func angleToDirection(angle: CGFloat) -> Direction {
        let pi = CGFloat.pi
        let octant = round(8 * angle / (2 * pi) + 8).truncatingRemainder(dividingBy: 8)
        
        switch Int(octant) {
        case 0: return .right
        case 1: return .upRight
        case 2: return .up
        case 3: return .upLeft
        case 4: return .left
        case 5: return .downLeft
        case 6: return .down
        case 7: return .downRight
        default: return .center
        }
    }
}

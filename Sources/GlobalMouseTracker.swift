import Cocoa

class GlobalMouseTracker {
    private let stateMachine: PetStateMachine
    private weak var panel: NSPanel?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    init(stateMachine: PetStateMachine, panel: NSPanel) {
        self.stateMachine = stateMachine
        self.panel = panel
    }
    
    func startTracking() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            print("Accessibility access not granted. Global mouse tracking requires permission.")
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
            return event
        }
    }
    
    func stopTracking() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleMouseMoved(event: NSEvent) {
        guard let panel = panel else { return }
        
        // NSEvent.mouseLocation is in global screen coordinates
        let mouseLoc = NSEvent.mouseLocation
        let panelFrame = panel.frame
        let center = CGPoint(x: panelFrame.midX, y: panelFrame.midY)
        
        let dx = mouseLoc.x - center.x
        let dy = mouseLoc.y - center.y
        
        let distance = sqrt(dx*dx + dy*dy)
        if distance < 60 {
            stateMachine.updateDirection(to: .center)
            return
        }
        
        let angle = atan2(dy, dx)
        let direction = angleToDirection(angle: angle)
        stateMachine.updateDirection(to: direction)
    }
    
    private func angleToDirection(angle: CGFloat) -> Direction {
        let pi = CGFloat.pi
        // Map angle from [-pi, pi] to octant
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

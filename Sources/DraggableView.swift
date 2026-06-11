import SwiftUI

struct DraggableView: NSViewRepresentable {
    var stateMachine: PetStateMachine
    
    func makeNSView(context: Context) -> DragNSView {
        return DragNSView(stateMachine: stateMachine)
    }
    
    func updateNSView(_ nsView: DragNSView, context: Context) {}
}

class DragNSView: NSView {
    var stateMachine: PetStateMachine
    private var initialMouseScreenLocation: NSPoint = .zero
    private var initialWindowTopLeft: NSPoint = .zero
    
    init(stateMachine: PetStateMachine) {
        self.stateMachine = stateMachine
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func mouseDown(with event: NSEvent) {
        stateMachine.startDragging()
        stateMachine.acknowledgeStretch()
        stateMachine.acknowledgeWater()
        initialMouseScreenLocation = NSEvent.mouseLocation
        if let window = self.window {
            initialWindowTopLeft = NSPoint(x: window.frame.origin.x, y: window.frame.maxY)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        
        let dx = currentLocation.x - initialMouseScreenLocation.x
        let dy = currentLocation.y - initialMouseScreenLocation.y
        
        let newTopLeft = NSPoint(x: initialWindowTopLeft.x + dx, y: initialWindowTopLeft.y + dy)
        
        var newOrigin = window.frame.origin
        newOrigin.x = newTopLeft.x
        newOrigin.y = newTopLeft.y - window.frame.height
        
        window.setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        stateMachine.stopDragging()
    }
}

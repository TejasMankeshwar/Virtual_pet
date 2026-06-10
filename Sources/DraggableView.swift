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
    private var initialMouseLocation: NSPoint = .zero
    
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
        initialMouseLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        
        var newOrigin = window.frame.origin
        newOrigin.x = currentLocation.x - initialMouseLocation.x
        newOrigin.y = currentLocation.y - initialMouseLocation.y
        
        window.setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        stateMachine.stopDragging()
    }
}

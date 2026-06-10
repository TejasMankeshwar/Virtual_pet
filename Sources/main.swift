import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: ComnyangPanel!
    var stateMachine: PetStateMachine!
    var tracker: GlobalMouseTracker!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        stateMachine = PetStateMachine()
        
        let rect = NSRect(x: 500, y: 500, width: 120, height: 120)
        panel = ComnyangPanel(contentRect: rect)
        
        let contentView = ZStack {
            DraggableView(stateMachine: stateMachine)
            SpriteView(stateMachine: stateMachine)
                .allowsHitTesting(false)
        }
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = rect
        panel.contentView = hostingView
        
        panel.makeKeyAndOrderFront(nil)
        
        tracker = GlobalMouseTracker(stateMachine: stateMachine, panel: panel)
        tracker.startTracking()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

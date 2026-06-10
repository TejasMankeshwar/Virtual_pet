import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: ComnyangPanel!
    var stateMachine: PetStateMachine!
    var tracker: GlobalEventTracker!
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.title = "🐱"
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Comnyang", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
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
        
        tracker = GlobalEventTracker(stateMachine: stateMachine, panel: panel)
        tracker.startTracking()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

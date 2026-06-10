import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: ComnyangPanel!
    var stateMachine: PetStateMachine!
    var tracker: GlobalEventTracker!
    var statusItem: NSStatusItem!
    var cancellables = Set<AnyCancellable>()
    
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
        
        stateMachine.$currentState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                if case .hiding = state {
                    self.slidePanelToRight()
                } else {
                    // Check if it's clinging to the right edge and pull it back
                    if let screen = self.panel.screen ?? NSScreen.main {
                        if self.panel.frame.origin.x >= screen.visibleFrame.maxX - 25 {
                            self.slidePanelBack()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func slidePanelToRight() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let targetX = screen.visibleFrame.maxX - panel.frame.width + 10 // +10 to hide a tiny bit of the right edge to make it look like clinging
        var frame = panel.frame
        frame.origin.x = targetX
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1.0
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.panel.animator().setFrame(frame, display: true)
        }
    }
    
    func slidePanelBack() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        var frame = panel.frame
        frame.origin.x = screen.visibleFrame.maxX - panel.frame.width - 50 // Move it 50 pixels away from the edge
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.panel.animator().setFrame(frame, display: true)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

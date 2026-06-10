import Cocoa
import SwiftUI
import Combine

struct MainContentView: View {
    @ObservedObject var stateMachine: PetStateMachine
    
    var body: some View {
        ZStack {
            DraggableView(stateMachine: stateMachine)
            
            SpriteView(stateMachine: stateMachine)
                .allowsHitTesting(false)
                .scaleEffect(y: stateMachine.isBlipping ? 0.0 : 1.0)
                
            HeartParticlesView(stateMachine: stateMachine)
                .offset(y: -32) // Position above the cat's head
                
            // Laser crushers that move to the center
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 3)
                    .shadow(color: .cyan, radius: 3)
                    .offset(y: stateMachine.isBlipping ? 60 : 0)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 3)
                    .shadow(color: .cyan, radius: 3)
                    .offset(y: stateMachine.isBlipping ? -60 : 0)
            }
            .opacity(stateMachine.isBlipping ? 1.0 : 0.0)
        }
    }
}

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
        
        let contentView = MainContentView(stateMachine: stateMachine)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = rect
        panel.contentView = hostingView
        
        panel.makeKeyAndOrderFront(nil)
        
        tracker = GlobalEventTracker(stateMachine: stateMachine, panel: panel)
        tracker.startTracking()
        
        stateMachine.$isHiding
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hiding in
                guard let self = self else { return }
                if hiding {
                    self.blipTeleport(toRight: true)
                } else {
                    // Check if it's clinging to the right edge and pull it back
                    if let screen = self.panel.screen ?? NSScreen.main {
                        if self.panel.frame.origin.x >= screen.visibleFrame.maxX - 25 {
                            self.blipTeleport(toRight: false)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func blipTeleport(toRight: Bool) {
        // Start blip compression
        withAnimation(.timingCurve(0.7, 0, 0.3, 1, duration: 0.5)) {
            stateMachine.isBlipping = true
        }
        
        // Wait exactly matching the animation duration for the compression to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Teleport
            guard let screen = self.panel.screen ?? NSScreen.main else { return }
            var frame = self.panel.frame
            if toRight {
                frame.origin.x = screen.visibleFrame.maxX - self.panel.frame.width + 10
            } else {
                frame.origin.x = screen.visibleFrame.maxX - self.panel.frame.width - 50
            }
            // Move instantaneously
            self.panel.setFrame(frame, display: true)
            
            // End blip (expand back)
            withAnimation(.timingCurve(0.7, 0, 0.3, 1, duration: 0.5)) {
                self.stateMachine.isBlipping = false
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

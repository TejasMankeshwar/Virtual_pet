import Cocoa
import SwiftUI
import Combine

struct MainContentView: View {
    @ObservedObject var stateMachine: PetStateMachine
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Message Area
            VStack(spacing: 2) {
                if !stateMachine.isHiding {
                    if stateMachine.showPurrMessage && !stateMachine.purrMessage.isEmpty {
                        Text(stateMachine.purrMessage)
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                    }
                    
                    if stateMachine.isPomodoroActive {
                        let mins = stateMachine.pomodoroTimeRemaining / 60
                        let secs = stateMachine.pomodoroTimeRemaining % 60
                        Text(String(format: "%02d:%02d", mins, secs))
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
                    }
                }
            }
            .frame(width: 120, height: 40, alignment: .bottom)
            
            // Cat Area
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
            .frame(width: 120, height: 120)
        }
        .frame(width: 120, height: 160)
        .contextMenu {
            Button(stateMachine.showPurrMessage ? "Hide Purr Message" : "Show Purr Message") {
                stateMachine.showPurrMessage.toggle()
            }
            Button("Set Purr Message...") {
                promptForPurrMessage()
            }
            Divider()
            if stateMachine.isPomodoroActive {
                Button("Stop Pomodoro Timer") {
                    stateMachine.stopPomodoro()
                }
            } else {
                Button("Start Pomodoro Timer") {
                    stateMachine.startPomodoro()
                }
            }
            Divider()
            Button("Hide") {
                stateMachine.isHiding = true
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func promptForPurrMessage() {
        let alert = NSAlert()
        alert.messageText = "Set Purr Message"
        alert.informativeText = "Enter a message (max 20 characters):"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.stringValue = stateMachine.purrMessage
        alert.accessoryView = inputTextField
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = inputTextField.stringValue
            stateMachine.purrMessage = String(text.prefix(20))
            stateMachine.showPurrMessage = true
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
        
        let rect = NSRect(x: 500, y: 500, width: 120, height: 160)
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

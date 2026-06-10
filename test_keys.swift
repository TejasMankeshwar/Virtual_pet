import Cocoa
let count = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
print("Key down count: \(count)")

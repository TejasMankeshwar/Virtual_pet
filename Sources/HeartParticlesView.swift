import SwiftUI

struct PixelHeart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pixelSize = rect.width / 5
        let pixels: [(Int, Int)] = [
            (1,0), (3,0),
            (0,1), (1,1), (2,1), (3,1), (4,1),
            (0,2), (1,2), (2,2), (3,2), (4,2),
            (1,3), (2,3), (3,3),
            (2,4)
        ]
        for p in pixels {
            let r = CGRect(x: CGFloat(p.0) * pixelSize, y: CGFloat(p.1) * pixelSize, width: pixelSize, height: pixelSize)
            path.addRect(r)
        }
        return path
    }
}

struct HeartParticle: Identifiable {
    let id = UUID()
    let initialX: CGFloat
}

struct AnimatedHeart: View {
    let initialX: CGFloat
    
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var xDrift: CGFloat = 0
    
    var body: some View {
        PixelHeart()
            .fill(Color.red)
            .frame(width: 15, height: 15)
            .offset(x: initialX + xDrift, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    yOffset = -22
                    opacity = 0.0
                    xDrift = CGFloat.random(in: -20...20)
                }
            }
    }
}

struct HeartParticlesView: View {
    @ObservedObject var stateMachine: PetStateMachine
    @State private var particles: [HeartParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                AnimatedHeart(initialX: particle.initialX)
            }
        }
        .onReceive(stateMachine.$currentState) { newState in
            if case .petting = newState {
                startSpawning()
            } else {
                stopSpawning()
            }
        }
    }
    
    func startSpawning() {
        if timer != nil { return }
        spawnParticle()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            spawnParticle()
        }
    }
    
    func stopSpawning() {
        timer?.invalidate()
        timer = nil
    }
    
    func spawnParticle() {
        let p = HeartParticle(initialX: CGFloat.random(in: -15...15))
        particles.append(p)
        
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if let index = particles.firstIndex(where: { $0.id == p.id }) {
                particles.remove(at: index)
            }
        }
    }
}

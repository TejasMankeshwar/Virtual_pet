import SwiftUI

struct SpriteView: View {
    @ObservedObject var stateMachine: PetStateMachine
    
    let pixelSize: CGFloat = 5.0
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { y in
                HStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { x in
                        Rectangle()
                            .fill(colorFor(x: x, y: y))
                            .frame(width: pixelSize, height: pixelSize)
                    }
                }
            }
        }
        .frame(width: 24 * pixelSize, height: 24 * pixelSize)
    }
    
    func colorFor(x: Int, y: Int) -> Color {
        let isDragging = (stateMachine.currentState == .dragging)
        let frame = isDragging ? dragFrame : baseFrame
        
        let row = frame[y]
        let char = row[row.index(row.startIndex, offsetBy: x)]
        
        // Render pupils dynamically over the white space
        if !isDragging {
            let pupilOffset = getPupilOffset()
            let leftEyeX = 4 + pupilOffset.x
            let leftEyeY = 10 + pupilOffset.y
            let rightEyeX = 18 + pupilOffset.x
            let rightEyeY = 10 + pupilOffset.y
            
            if (x == leftEyeX || x == leftEyeX + 1) && (y == leftEyeY || y == leftEyeY + 1) {
                return .black
            }
            if (x == rightEyeX || x == rightEyeX + 1) && (y == rightEyeY || y == rightEyeY + 1) {
                return .black
            }
        } else {
            // Surprised eyes when dragging! Small pupils.
            if x == 4 && y == 11 { return .black }
            if x == 19 && y == 11 { return .black }
        }
        
        switch char {
        case "1": return Color(white: 0.15) // Blackish fur
        case "2": return Color(white: 0.25) // Highlight
        case "5": return .pink // Nose/Ears
        case "3": return .white // Sclera
        default: return .clear
        }
    }
    
    func getPupilOffset() -> (x: Int, y: Int) {
        switch stateMachine.currentState {
        case .idle, .looking(.center):
            return (0, 0)
        case .dragging:
            return (0, 0)
        case .looking(let dir):
            switch dir {
            case .up: return (0, -2)
            case .down: return (0, 2)
            case .left: return (-2, 0)
            case .right: return (2, 0)
            case .upLeft: return (-2, -2)
            case .upRight: return (2, -2)
            case .downLeft: return (-2, 2)
            case .downRight: return (2, 2)
            case .center: return (0, 0)
            }
        }
    }
    
    let baseFrame = [
        "                        ",
        "   11              11   ",
        "  1551            1551  ",
        "  11111111111111111111  ",
        " 1111111111111111111111 ",
        " 1111111111111111111111 ",
        "111111111111111111111111",
        "111111111111111111111111",
        "111333311111111113333111",
        "113333331111111133333311",
        "113333331115511133333311",
        "113333331111111133333311",
        "113333331111111133333311",
        "111333311111111113333111",
        "111111111111111111111111",
        " 1111111111111111111111 ",
        " 1111111111111111111111 ",
        "  11111111111111111111  ",
        "   111111111111111111   ",
        "    111          111    ",
        "    111          111    ",
        "    111          111    ",
        "   1111          1111   ",
        "                        "
    ]
    
    let dragFrame = [
        "                        ",
        "  11                11  ",
        " 1551              1551 ",
        " 1111111111111111111111 ",
        "111111111111111111111111",
        "111111111111111111111111",
        "111111111111111111111111",
        "111111111111111111111111",
        "111333311111111113333111",
        "113333331111111133333311",
        "113333331115511133333311",
        "113333331111111133333311",
        "113333331111111133333311",
        "111333311111111113333111",
        "111111111111111111111111",
        " 1111111111111111111111 ",
        " 1111111111111111111111 ",
        "111111111111111111111111",
        "111111111111111111111111",
        " 1111              1111 ",
        "  11                11  ",
        "                        ",
        "                        ",
        "                        "
    ]
}

extension PetState: Equatable {
    public static func == (lhs: PetState, rhs: PetState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.dragging, .dragging): return true
        case (.looking(let lDir), .looking(let rDir)): return lDir == rDir
        default: return false
        }
    }
}

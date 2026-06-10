import SwiftUI

struct SpriteView: View {
    @ObservedObject var stateMachine: PetStateMachine
    
    let pixelSize: CGFloat = 4.0
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<30, id: \.self) { y in
                HStack(spacing: 0) {
                    ForEach(0..<30, id: \.self) { x in
                        Rectangle()
                            .fill(colorFor(x: x, y: y))
                            .frame(width: pixelSize, height: pixelSize)
                    }
                }
            }
        }
        .frame(width: 30 * pixelSize, height: 30 * pixelSize)
    }
    
    func colorFor(x: Int, y: Int) -> Color {
        let state = stateMachine.currentState
        
        let frame: [String]
        if stateMachine.isHiding {
            frame = peekRightFrame
        } else {
            switch state {
            case .dragging:
                frame = dragFrame
            case .typing(let activePaw):
                frame = (activePaw == .left) ? typeLeftFrame : typeRightFrame
            case .stretching:
                frame = stretchFrame
            default:
                frame = baseFrame
            }
        }
        
        guard y >= 0 && y < frame.count else { return .clear }
        let row = frame[y]
        guard x >= 0 && x < row.count else { return .clear }
        let char = row[row.index(row.startIndex, offsetBy: x)]
        
        if case .dragging = state {
            if (x == 8 || x == 9) && (y == 8 || y == 9) { return .black }
            if (x == 17 || x == 18) && (y == 8 || y == 9) { return .black }
        } else if case .petting = state {
            let leftEye = [(7,8), (8,7), (9,8)]
            let rightEye = [(16,8), (17,7), (18,8)]
            if leftEye.contains(where: { $0.0 == x && $0.1 == y }) { return getPinkPartColor() }
            if rightEye.contains(where: { $0.0 == x && $0.1 == y }) { return getPinkPartColor() }
            if char == "3" && (y >= 7 && y <= 9) { return getFurColor() }
        } else if case .stretching = state {
            let leftEye = [(7,8), (8,7), (9,8)]
            let rightEye = [(16,8), (17,7), (18,8)]
            if leftEye.contains(where: { $0.0 == x && $0.1 == y }) { return .black }
            if rightEye.contains(where: { $0.0 == x && $0.1 == y }) { return .black }
            if char == "3" && (y >= 7 && y <= 9) { return getStretchColor(y: y) }
        } else if stateMachine.isHiding {
            let pupilOffset = getPupilOffset()
            let leftEyeX = 14 + pupilOffset.x
            let leftEyeY = 9 + pupilOffset.y
            let rightEyeX = 14 + pupilOffset.x
            let rightEyeY = 16 + pupilOffset.y
            
            if (x == leftEyeX || x == leftEyeX + 1) && (y == leftEyeY || y == leftEyeY + 1) {
                if char == "3" { return .black }
            }
            if (x == rightEyeX || x == rightEyeX + 1) && (y == rightEyeY || y == rightEyeY + 1) {
                if char == "3" { return .black }
            }
        } else {
            let pupilOffset = getPupilOffset()
            let leftEyeX = 8 + pupilOffset.x
            let leftEyeY = 8 + pupilOffset.y
            let rightEyeX = 17 + pupilOffset.x
            let rightEyeY = 8 + pupilOffset.y
            
            if (x == leftEyeX || x == leftEyeX + 1) && (y == leftEyeY || y == leftEyeY + 1) {
                if char == "3" { return .black }
            }
            if (x == rightEyeX || x == rightEyeX + 1) && (y == rightEyeY || y == rightEyeY + 1) {
                if char == "3" { return .black }
            }
        }
        
        switch char {
        case "1":
            if case .stretching = state { return getStretchColor(y: y) }
            return getFurColor()
        case "5":
            if case .stretching = state { return getStretchColor(y: y) }
            return getPinkPartColor()
        case "3":
            return .white
        case "k":
            return Color(white: 0.5) 
        case "b":
            return Color(white: 0.8) 
        case "l":
            return Color(white: 1.0) 
        default:
            return .clear
        }
    }
    
    func getPinkPartColor() -> Color {
        let heat = stateMachine.typingHeat
        let r = 1.0 + (0.15 - 1.0) * heat
        let g = 0.4 + (0.15 - 0.4) * heat
        let b = 0.6 + (0.15 - 0.6) * heat
        return Color(red: r, green: g, blue: b)
    }
    
    func getFurColor() -> Color {
        let heat = stateMachine.typingHeat
        let r = 0.15 + (0.98 - 0.15) * heat
        let g = 0.15 + (0.165 - 0.15) * heat
        let b = 0.15 + (0.333 - 0.15) * heat
        return Color(red: r, green: g, blue: b)
    }
    
    func getStretchColor(y: Int) -> Color {
        let ratio = Double(y) / 29.0
        let r = 1.0
        let g = 1.0 - (0.5 * ratio)
        let b = 0.0
        return Color(red: r, green: g, blue: b)
    }
    
    func getPupilOffset() -> (x: Int, y: Int) {
        switch stateMachine.currentState {
        case .idle, .looking(.center), .dragging, .petting, .stretching:
            return (0, 0)
        case .typing:
            return (0, 1) 
        case .looking(let dir):
            switch dir {
            case .up: return (0, -1)
            case .down: return (0, 1)
            case .left: return (-1, 0)
            case .right: return (1, 0)
            case .upLeft: return (-1, -1)
            case .upRight: return (1, -1)
            case .downLeft: return (-1, 1)
            case .downRight: return (1, 1)
            case .center: return (0, 0)
            }
        }
    }
    
    let baseFrame = [
        "                              ",
        "        333      333          ",
        "       31113    31113         ",
        "      3111113  3111113        ",
        "     311111113311111113       ",
        "    31111111111111111113      ",
        "    31111111111111111113      ",
        "   3111333111111333111113     ",
        " 11311133311111133311111311   ",
        " 11311133311111133311111311   ",
        "   3111111111111111111113     ",
        " 11311111111111111111111311   ",
        "   3111111111111111111113     ",
        "    33111111111111111133      ",
        "      3111111111111113        ",
        "     311111111111111113       ",
        "    31111111111111111113      ",
        "   3111111111111111111113     ",
        "  311111111111111111111113    ",
        "  311111111111111111111113  33",
        "  311111111111111111111113 313",
        "  3111111111111111111111133113",
        "  3111111111111111111111111113",
        "  311111111111111111111111113 ",
        "   3111111111111111111111113  ",
        "    31111111111111111111133   ",
        "     33111133333311111333     ",
        "       3333      33333        ",
        "                              ",
        "                              "
    ]
    
    let typeLeftFrame = [
        "                              ",
        "        333      333          ",
        "       31113    31113         ",
        "      3111113  3111113        ",
        "     311111113311111113       ",
        "    31111111111111111113      ",
        "    31111111111111111113      ",
        "   3111333111111333111113     ",
        " 11311133311111133311111311   ",
        " 11311133311111133311111311   ",
        "   3111111111111111111113     ",
        " 11311111111111111111111311   ",
        "   3111111111111111111113     ",
        "    33111111111111111133      ",
        "      3111111111111113        ",
        "     311111111111111113       ",
        "    31111111111111111113      ",
        "   3111111111111111111113     ",
        "  311111111111111111111113    ",
        "  311111111111111111111113  33",
        "  311111111111111111111113 313",
        "  3111111111111111111111133113",
        "  3111111111111111111111111113",
        "  3111111  111111111111111113 ",
        "   31111   11111111111111113  ",
        "    3333   1111111111111133   ",
        "    bbbb   33333311111333     ",
        "  kllllllk       33333        ",
        "  kkkkkkkk                    ",
        "  kkkkkkkk                    "
    ]
    
    let typeRightFrame = [
        "                              ",
        "        333      333          ",
        "       31113    31113         ",
        "      3111113  3111113        ",
        "     311111113311111113       ",
        "    31111111111111111113      ",
        "    31111111111111111113      ",
        "   3111333111111333111113     ",
        " 11311133311111133311111311   ",
        " 11311133311111133311111311   ",
        "   3111111111111111111113     ",
        " 11311111111111111111111311   ",
        "   3111111111111111111113     ",
        "    33111111111111111133      ",
        "      3111111111111113        ",
        "     311111111111111113       ",
        "    31111111111111111113      ",
        "   3111111111111111111113     ",
        "  311111111111111111111113    ",
        "  311111111111111111111113  33",
        "  311111111111111111111113 313",
        "  3111111111111111111111133113",
        "  3111111111111111111111111113",
        "  311111111111111  1111111113 ",
        "   31111111111111   11111113  ",
        "    3111111111111   3333333   ",
        "     331111333333   bbbbbbb   ",
        "       3333       klllllllllk ",
        "                  kkkkkkkkkkk ",
        "                  kkkkkkkkkkk "
    ]
    
    let dragFrame = [
        "                              ",
        "        333      333          ",
        "       31113    31113         ",
        "      3111113  3111113        ",
        "     311111113311111113       ",
        "    31111111111111111113      ",
        "    31111111111111111113      ",
        "   3111333111111333111113     ",
        "   3111333111111333111113     ",
        "   3111333111111333111113     ",
        "   3111111111111111111113     ",
        "   3111111111111111111113     ",
        "   3111111111111111111113     ",
        "    33111111111111111133      ",
        "      3111111111111113        ",
        "     311111111111111113       ",
        "    31111111111111111113      ",
        "   33311111111111111111333    ",
        "  333 333333333333333333 333  ",
        "  333                    333  ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              "
    ]
    
    let stretchFrame = [
        "                              ",
        "                              ",
        "                              ",
        "        333      333          ",
        "       31113    31113         ",
        "      3111113  3111113        ",
        "     311111113311111113       ",
        "    31111111111111111113      ",
        "    31111111111111111113      ",
        "   3111333111111333111113     ",
        " 11311133311111133311111311   ",
        " 11311133311111133311111311   ",
        "   3111111111111111111113     ",
        " 11311111111111111111111311   ",
        "   3111111111111111111113     ",
        "    33111111111111111133      ",
        "      3111111111111113        ",
        "     311111111111111113       ",
        "    31111111111111111113      ",
        "   333311111111111111113333   ",
        " 333  333311111111113333  333 ",
        " 333     333333333333     333 ",
        "  33                      33  ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              "
    ]
    
    let peekRightFrame = [
        "                              ",
        "                              ",
        "                              ",
        "               33             ",
        "              3113     11     ",
        "             311113    11     ",
        "            31111113          ",
        "           3111111113         ",
        "          311111111113        ",
        "         31111333111113       ",
        "         31111333111113       ",
        "         31111333111113       ",
        "          31111111111113      ",
        "         311111111111113      ",
        "         311111111111113      ",
        "          31111111111113      ",
        "         31111333111113       ",
        "         31111333111113       ",
        "         31111333111113       ",
        "          311111111113        ",
        "           3111111113         ",
        "            31111113          ",
        "             311113    11     ",
        "              3113     11     ",
        "               33             ",
        "                              ",
        "                              ",
        "                              ",
        "                              ",
        "                              "
    ]
}

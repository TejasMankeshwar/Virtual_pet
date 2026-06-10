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
        
        let row = frame[y]
        let char = row[row.index(row.startIndex, offsetBy: x)]
        
        // Render pupils dynamically over the white space (character '3')
        if case .dragging = state {
            // Surprised tiny pupils when dragged
            if x == 5 && y == 10 { return .black }
            if x == 18 && y == 10 { return .black }
        } else if case .petting = state {
            // Closed happy eyes ^ ^
            let leftEye = [(4,10), (5,9), (6,10)]
            let rightEye = [(17,10), (18,9), (19,10)]
            if leftEye.contains(where: { $0.0 == x && $0.1 == y }) { return getPinkPartColor() }
            if rightEye.contains(where: { $0.0 == x && $0.1 == y }) { return getPinkPartColor() }
            // Replace the rest of the white eyeball with fur color
            if char == "3" { return getFurColor() }
        } else if case .stretching = state {
            // Closed eyes ^ ^ for stretching
            let leftEye = [(4,10), (5,9), (6,10)]
            let rightEye = [(17,10), (18,9), (19,10)]
            if leftEye.contains(where: { $0.0 == x && $0.1 == y }) { return .black }
            if rightEye.contains(where: { $0.0 == x && $0.1 == y }) { return .black }
            // Replace the rest of the white eyeball with fur color
            if char == "3" { return getStretchColor(y: y) }
        } else if stateMachine.isHiding {
            let pupilOffset = getPupilOffset()
            let leftEyeX = 14 + pupilOffset.x
            let leftEyeY = 15 + pupilOffset.y
            let rightEyeX = 14 + pupilOffset.x
            let rightEyeY = 5 + pupilOffset.y
            
            if (x == leftEyeX || x == leftEyeX + 1) && (y == leftEyeY || y == leftEyeY + 1) {
                return .black
            }
            if (x == rightEyeX || x == rightEyeX + 1) && (y == rightEyeY || y == rightEyeY + 1) {
                return .black
            }
        } else {
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
        }
        
        switch char {
        case "1":
            if case .stretching = state {
                return getStretchColor(y: y)
            }
            return getFurColor()
        case "5":
            if case .stretching = state {
                return getStretchColor(y: y) // Make ears match the stretch color
            }
            return getPinkPartColor()
        case "3":
            return .white
        case "k":
            return Color(white: 0.5) // Button base (medium grey)
        case "b":
            return Color(white: 0.8) // Unpressed button top (greyish white)
        case "l":
            return Color(white: 1.0) // Pressed button top (bright white)
        default:
            return .clear
        }
    }
    
    func getPinkPartColor() -> Color {
        let heat = stateMachine.typingHeat
        // Lerp from Pink to the unheated fur color (dark charcoal) when heated
        let r = 1.0 + (0.15 - 1.0) * heat
        let g = 0.4 + (0.15 - 0.4) * heat
        let b = 0.6 + (0.15 - 0.6) * heat
        return Color(red: r, green: g, blue: b)
    }
    
    func getFurColor() -> Color {
        let heat = stateMachine.typingHeat
        // Lerp from dark charcoal Color(white: 0.15) to #FA2A55 (r: 0.98, g: 0.165, b: 0.333)
        let r = 0.15 + (0.98 - 0.15) * heat
        let g = 0.15 + (0.165 - 0.15) * heat
        let b = 0.15 + (0.333 - 0.15) * heat
        return Color(red: r, green: g, blue: b)
    }
    
    func getStretchColor(y: Int) -> Color {
        // Orange to yellow gradient
        let ratio = Double(y) / 23.0
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
            return (0, 3) // Look down at keys, offset for "gamer lean"
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
        "  11111111111111111111  ",
        "   111111111111111111   ",
        "     111          111   ",
        "     111          111   ",
        "    33333        33333  ",
        "    33333        33333  ",
        "                        ",
        "                        "
    ]
    
    let typeLeftFrame = [
        "                        ",
        "                        ",
        "   11              11   ",
        "  1551            1551  ",
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
        "  11111111111111111111  ",
        "   111111111111111111   ",
        "    111          111    ",
        "    111         33333   ",
        "   33333       bbbbb    ",
        "  klllllk     kkkkkkk   ",
        "  kkkkkkk     kkkkkkk   "
    ]
    
    let typeRightFrame = [
        "                        ",
        "                        ",
        "   11              11   ",
        "  1551            1551  ",
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
        "  11111111111111111111  ",
        "   111111111111111111   ",
        "    111          111    ",
        "   33333         111    ",
        "   bbbbb       33333    ",
        "  kkkkkkk     klllllk   ",
        "  kkkkkkk     kkkkkkk   "
    ]
    
    let dragFrame = [
        "                        ",
        "   11              11   ",
        "  1551            1551  ",
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
        "  11111111111111111111  ",
        " 1111111111111111111111 ",
        " 111                111 ",
        " 333                333 ",
        " 333                333 ",
        "                        ",
        "                        ",
        "                        "
    ]
    
    let stretchFrame = [
        "                        ",
        "   11              11   ",
        "  1551            1551  ",
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
        "  11111111111111111111  ",
        " 1111111111111111111111 ",
        "33311              11333",
        "3331                1333",
        "3331                1333",
        " 333                333 ",
        "                        ",
        "                        "
    ]
    
    let peekRightFrame = [
        "            0 0         ",
        "            0 0         ",
        "           01010        ",
        "          011111000     ",
        "         01133331110000 ",
        "        0111333311111110",
        "        0111333315111110",
        "         011333311111110",
        "          0111111111110 ",
        "          011111111110  ",
        "          011511111110  ",
        "          011511111110  ",
        "          011111111110  ",
        "          0111111111110 ",
        "         011333311111110",
        "        0111333315111110",
        "        0111333311111110",
        "         011333311100000",
        "          011111000 0110",
        "           01010   01110",
        "            0 0    0110 ",
        "            0 0     00  ",
        "                        ",
        "                        "
    ]
}

import Foundation

public enum WindowAction: String, Codable, CaseIterable, Sendable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, centerThird, lastThird
    case firstTwoThirds, lastTwoThirds
    case firstSixth, secondSixth, thirdSixth, fourthSixth, fifthSixth, sixthSixth
    case fullscreen
    case almostMaximize
    case center
    case larger
    case smaller
    case nextDisplay
    case previousDisplay
    case undo
}

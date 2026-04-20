import Foundation

public enum WindowAction: String, Codable, CaseIterable, Sendable {
    // Halves
    case leftHalf, rightHalf, topHalf, bottomHalf

    // 2x2 quadrants
    case topLeft, topRight, bottomLeft, bottomRight

    // Thirds (horizontal)
    case firstThird, centerThird, lastThird

    // Two-thirds (horizontal)
    case firstTwoThirds, lastTwoThirds

    // Horizontal bands (full width, vertical portion anchored top/bottom)
    case topThird, bottomThird
    case topTwoThirds, bottomTwoThirds

    // Corner 2/3 × 2/3 (2/3 width × 2/3 height, anchored to that corner)
    case topLeftTwoThirds, topRightTwoThirds
    case bottomLeftTwoThirds, bottomRightTwoThirds

    // Sixths (2 rows x 3 cols)
    case topLeftSixth, topCenterSixth, topRightSixth
    case bottomLeftSixth, bottomCenterSixth, bottomRightSixth

    // 3x3 grid cells (each exactly 1/9 of screen)
    case grid3TopLeft, grid3TopCenter, grid3TopRight
    case grid3MiddleLeft, grid3MiddleCenter, grid3MiddleRight
    case grid3BottomLeft, grid3BottomCenter, grid3BottomRight

    // Sizing
    case fullscreen
    case almostMaximize
    case center
    case largerSize
    case smallerSize

    // Displays
    case nextDisplay
    case previousDisplay

    // History
    case undo
    case redo
}

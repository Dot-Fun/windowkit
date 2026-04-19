import Foundation
import WindowEngine

public struct ActionGroup: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let actions: [WindowAction]
    public let showsGridDiagram: Bool

    public init(id: String, title: String, subtitle: String? = nil, actions: [WindowAction], showsGridDiagram: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.actions = actions
        self.showsGridDiagram = showsGridDiagram
    }
}

public enum ActionCatalog {
    public static let groups: [ActionGroup] = [
        ActionGroup(
            id: "halves",
            title: "Halves",
            actions: [.leftHalf, .rightHalf, .topHalf, .bottomHalf]
        ),
        ActionGroup(
            id: "quadrants",
            title: "Quadrants (2×2)",
            actions: [.topLeft, .topRight, .bottomLeft, .bottomRight]
        ),
        ActionGroup(
            id: "thirds",
            title: "Thirds & Two-Thirds",
            actions: [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds]
        ),
        ActionGroup(
            id: "sixths",
            title: "Sixths (2×3)",
            actions: [
                .topLeftSixth, .topCenterSixth, .topRightSixth,
                .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
            ]
        ),
        ActionGroup(
            id: "grid3",
            title: "3×3 Grid",
            subtitle: "Spatial layout: U/I/O · J/K/L · M/,/.",
            actions: [
                .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
                .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
                .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight,
            ],
            showsGridDiagram: true
        ),
        ActionGroup(
            id: "sizing",
            title: "Fullscreen, Center & Sizing",
            actions: [.fullscreen, .almostMaximize, .center, .largerSize, .smallerSize]
        ),
        ActionGroup(
            id: "displays",
            title: "Displays",
            actions: [.nextDisplay, .previousDisplay]
        ),
        ActionGroup(
            id: "history",
            title: "History",
            actions: [.undo, .redo]
        ),
    ]

    public static func displayName(for action: WindowAction) -> String {
        switch action {
        case .leftHalf:          return "Left Half"
        case .rightHalf:         return "Right Half"
        case .topHalf:           return "Top Half"
        case .bottomHalf:        return "Bottom Half"
        case .topLeft:           return "Top Left Quadrant"
        case .topRight:          return "Top Right Quadrant"
        case .bottomLeft:        return "Bottom Left Quadrant"
        case .bottomRight:       return "Bottom Right Quadrant"
        case .firstThird:        return "First Third"
        case .centerThird:       return "Center Third"
        case .lastThird:         return "Last Third"
        case .firstTwoThirds:    return "First Two Thirds"
        case .lastTwoThirds:     return "Last Two Thirds"
        case .topLeftSixth:      return "Top Left Sixth"
        case .topCenterSixth:    return "Top Center Sixth"
        case .topRightSixth:     return "Top Right Sixth"
        case .bottomLeftSixth:   return "Bottom Left Sixth"
        case .bottomCenterSixth: return "Bottom Center Sixth"
        case .bottomRightSixth:  return "Bottom Right Sixth"
        case .grid3TopLeft:      return "Grid · Top Left (U)"
        case .grid3TopCenter:    return "Grid · Top Center (I)"
        case .grid3TopRight:     return "Grid · Top Right (O)"
        case .grid3MiddleLeft:   return "Grid · Middle Left (J)"
        case .grid3MiddleCenter: return "Grid · Middle Center (K)"
        case .grid3MiddleRight:  return "Grid · Middle Right (L)"
        case .grid3BottomLeft:   return "Grid · Bottom Left (M)"
        case .grid3BottomCenter: return "Grid · Bottom Center (,)"
        case .grid3BottomRight:  return "Grid · Bottom Right (.)"
        case .fullscreen:        return "Fullscreen"
        case .almostMaximize:    return "Almost Maximize"
        case .center:            return "Center on Screen"
        case .largerSize:        return "Make Larger"
        case .smallerSize:       return "Make Smaller"
        case .nextDisplay:       return "Move to Next Display"
        case .previousDisplay:   return "Move to Previous Display"
        case .undo:              return "Undo Last Move"
        case .redo:              return "Redo Last Move"
        }
    }
}

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
            actions: [
                .firstThird, .centerThird, .lastThird,
                .firstTwoThirds, .lastTwoThirds,
                .topThird, .bottomThird, .topTwoThirds, .bottomTwoThirds,
            ]
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
        case .topThird:          return "Top Third"
        case .bottomThird:       return "Bottom Third"
        case .topTwoThirds:      return "Top Two Thirds"
        case .bottomTwoThirds:   return "Bottom Two Thirds"
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

    /// Multi-tap cycle steps shown under the 9 grid3* rows.
    /// Mirrors the `TapCycles` map owned by HotkeyManager (task #2).
    public static func cycleSteps(for action: WindowAction) -> [String]? {
        switch action {
        case .grid3TopLeft:
            return ["1× top-left 1/9", "2× top-left 1/4"]
        case .grid3TopCenter:
            return ["1× top-center 1/9", "2× top 1/3", "3× top 1/2", "4× top 2/3"]
        case .grid3TopRight:
            return ["1× top-right 1/9", "2× top-right 1/4"]
        case .grid3MiddleLeft:
            return ["1× middle-left 1/9", "2× left 1/3", "3× left 1/2", "4× left 2/3"]
        case .grid3MiddleCenter:
            return ["1× center 1/9", "2× fullscreen"]
        case .grid3MiddleRight:
            return ["1× middle-right 1/9", "2× right 1/3", "3× right 1/2", "4× right 2/3"]
        case .grid3BottomLeft:
            return ["1× bottom-left 1/9", "2× bottom-left 1/4"]
        case .grid3BottomCenter:
            return ["1× bottom-center 1/9", "2× bottom 1/3", "3× bottom 1/2", "4× bottom 2/3"]
        case .grid3BottomRight:
            return ["1× bottom-right 1/9", "2× bottom-right 1/4"]
        default:
            return nil
        }
    }

    public static func cycleCaption(for action: WindowAction) -> String? {
        cycleSteps(for: action)?.joined(separator: " · ")
    }
}

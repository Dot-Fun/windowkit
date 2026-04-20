import CoreGraphics
import Foundation

/// Pure geometry functions for window placement.
///
/// **Coordinate convention**: all functions operate in the coordinate space
/// of the `screen` argument. The WindowKit app uses Accessibility API
/// coordinates (top-left origin, y grows downward) throughout — Geometry
/// itself is origin-agnostic, but vertical action names (`topHalf`,
/// `bottomHalf`, etc.) assume **top-left origin**: `topHalf.y == screen.minY`.
///
/// Tiling guarantee: the 3x3 grid, halves, quadrants, thirds, and sixths
/// tile `screen` exactly (no gaps, no overlaps) after integer rounding.
public enum Geometry {

    /// Growth/shrink step for `largerSize` / `smallerSize`, expressed as
    /// a fraction of the screen along each axis.
    public static let resizeStep: CGFloat = 0.05

    /// `almostMaximize` target as a fraction of the screen.
    public static let almostMaximizeFraction: CGFloat = 0.90

    /// Minimum window edge length (in screen coords) for `smallerSize`
    /// shrink clamp — prevents collapsing to zero.
    public static let minimumWindowEdge: CGFloat = 100

    /// Compute the target frame for `action` given the screen rect the
    /// window belongs to and its current frame.
    ///
    /// - Returns: target CGRect in the screen's coordinate space, or
    ///   `nil` for non-geometric actions (`nextDisplay`, `previousDisplay`,
    ///   `undo`, `redo`) which are resolved by the caller.
    public static func targetFrame(
        for action: WindowAction,
        screen: CGRect,
        current: CGRect
    ) -> CGRect? {
        switch action {
        // MARK: halves
        case .leftHalf:   return hSlice(screen, col: 0, outOf: 2)
        case .rightHalf:  return hSlice(screen, col: 1, outOf: 2)
        case .topHalf:    return vSlice(screen, row: 0, outOf: 2)
        case .bottomHalf: return vSlice(screen, row: 1, outOf: 2)

        // MARK: 2x2 quadrants
        case .topLeft:     return cell(screen, col: 0, row: 0, cols: 2, rows: 2)
        case .topRight:    return cell(screen, col: 1, row: 0, cols: 2, rows: 2)
        case .bottomLeft:  return cell(screen, col: 0, row: 1, cols: 2, rows: 2)
        case .bottomRight: return cell(screen, col: 1, row: 1, cols: 2, rows: 2)

        // MARK: thirds
        case .firstThird:  return hSlice(screen, col: 0, outOf: 3)
        case .centerThird: return hSlice(screen, col: 1, outOf: 3)
        case .lastThird:   return hSlice(screen, col: 2, outOf: 3)

        // MARK: two-thirds
        case .firstTwoThirds: return hRange(screen, startCol: 0, endCol: 2, outOf: 3)
        case .lastTwoThirds:  return hRange(screen, startCol: 1, endCol: 3, outOf: 3)

        // MARK: horizontal bands (full width, vertical portion)
        case .topThird:        return vRange(screen, startRow: 0, endRow: 1, outOf: 3)
        case .bottomThird:     return vRange(screen, startRow: 2, endRow: 3, outOf: 3)
        case .topTwoThirds:    return vRange(screen, startRow: 0, endRow: 2, outOf: 3)
        case .bottomTwoThirds: return vRange(screen, startRow: 1, endRow: 3, outOf: 3)

        // MARK: corner 2/3 x 2/3
        case .topLeftTwoThirds:     return gridRange(screen, startCol: 0, endCol: 2, cols: 3, startRow: 0, endRow: 2, rows: 3)
        case .topRightTwoThirds:    return gridRange(screen, startCol: 1, endCol: 3, cols: 3, startRow: 0, endRow: 2, rows: 3)
        case .bottomLeftTwoThirds:  return gridRange(screen, startCol: 0, endCol: 2, cols: 3, startRow: 1, endRow: 3, rows: 3)
        case .bottomRightTwoThirds: return gridRange(screen, startCol: 1, endCol: 3, cols: 3, startRow: 1, endRow: 3, rows: 3)

        // MARK: sixths (2 rows x 3 cols)
        case .topLeftSixth:      return cell(screen, col: 0, row: 0, cols: 3, rows: 2)
        case .topCenterSixth:    return cell(screen, col: 1, row: 0, cols: 3, rows: 2)
        case .topRightSixth:     return cell(screen, col: 2, row: 0, cols: 3, rows: 2)
        case .bottomLeftSixth:   return cell(screen, col: 0, row: 1, cols: 3, rows: 2)
        case .bottomCenterSixth: return cell(screen, col: 1, row: 1, cols: 3, rows: 2)
        case .bottomRightSixth:  return cell(screen, col: 2, row: 1, cols: 3, rows: 2)

        // MARK: 3x3 grid
        case .grid3TopLeft:      return cell(screen, col: 0, row: 0, cols: 3, rows: 3)
        case .grid3TopCenter:    return cell(screen, col: 1, row: 0, cols: 3, rows: 3)
        case .grid3TopRight:     return cell(screen, col: 2, row: 0, cols: 3, rows: 3)
        case .grid3MiddleLeft:   return cell(screen, col: 0, row: 1, cols: 3, rows: 3)
        case .grid3MiddleCenter: return cell(screen, col: 1, row: 1, cols: 3, rows: 3)
        case .grid3MiddleRight:  return cell(screen, col: 2, row: 1, cols: 3, rows: 3)
        case .grid3BottomLeft:   return cell(screen, col: 0, row: 2, cols: 3, rows: 3)
        case .grid3BottomCenter: return cell(screen, col: 1, row: 2, cols: 3, rows: 3)
        case .grid3BottomRight:  return cell(screen, col: 2, row: 2, cols: 3, rows: 3)

        // MARK: sizing
        case .fullscreen:
            return screen
        case .almostMaximize:
            return scaled(screen, fraction: almostMaximizeFraction)
        case .center:
            return centered(size: current.size, in: screen)
        case .largerSize:
            return resized(current, by: +resizeStep, in: screen)
        case .smallerSize:
            return resized(current, by: -resizeStep, in: screen)

        // MARK: non-geometric — caller handles
        case .nextDisplay, .previousDisplay, .undo, .redo:
            return nil
        }
    }

    // MARK: - Tiling primitives

    /// Integer boundary positions along `length` divided into `count` parts.
    /// Guarantees `boundaries[0] == 0` and `boundaries[count] == length`
    /// (after rounding), so adjacent cells share an edge exactly.
    static func boundaries(length: CGFloat, count: Int) -> [CGFloat] {
        precondition(count > 0)
        var result: [CGFloat] = []
        result.reserveCapacity(count + 1)
        for i in 0...count {
            result.append((length * CGFloat(i) / CGFloat(count)).rounded())
        }
        return result
    }

    /// Cell (col, row) of a `cols x rows` grid within `screen`.
    static func cell(_ screen: CGRect, col: Int, row: Int, cols: Int, rows: Int) -> CGRect {
        let xs = boundaries(length: screen.width, count: cols)
        let ys = boundaries(length: screen.height, count: rows)
        return CGRect(
            x: screen.minX + xs[col],
            y: screen.minY + ys[row],
            width: xs[col + 1] - xs[col],
            height: ys[row + 1] - ys[row]
        )
    }

    /// Horizontal slice: column `col` of `outOf` equal columns, full height.
    static func hSlice(_ screen: CGRect, col: Int, outOf: Int) -> CGRect {
        let xs = boundaries(length: screen.width, count: outOf)
        return CGRect(
            x: screen.minX + xs[col],
            y: screen.minY,
            width: xs[col + 1] - xs[col],
            height: screen.height
        )
    }

    /// Vertical slice: row `row` of `outOf` equal rows, full width.
    static func vSlice(_ screen: CGRect, row: Int, outOf: Int) -> CGRect {
        let ys = boundaries(length: screen.height, count: outOf)
        return CGRect(
            x: screen.minX,
            y: screen.minY + ys[row],
            width: screen.width,
            height: ys[row + 1] - ys[row]
        )
    }

    /// Range of columns `[startCol, endCol)` of `outOf` equal columns.
    static func hRange(_ screen: CGRect, startCol: Int, endCol: Int, outOf: Int) -> CGRect {
        let xs = boundaries(length: screen.width, count: outOf)
        return CGRect(
            x: screen.minX + xs[startCol],
            y: screen.minY,
            width: xs[endCol] - xs[startCol],
            height: screen.height
        )
    }

    /// Range of rows `[startRow, endRow)` of `outOf` equal rows, full width.
    static func vRange(_ screen: CGRect, startRow: Int, endRow: Int, outOf: Int) -> CGRect {
        let ys = boundaries(length: screen.height, count: outOf)
        return CGRect(
            x: screen.minX,
            y: screen.minY + ys[startRow],
            width: screen.width,
            height: ys[endRow] - ys[startRow]
        )
    }

    /// 2-D sub-rect: columns `[startCol, endCol)` × rows `[startRow, endRow)`
    /// of an `cols × rows` grid of equal cells.
    static func gridRange(
        _ screen: CGRect,
        startCol: Int, endCol: Int, cols: Int,
        startRow: Int, endRow: Int, rows: Int
    ) -> CGRect {
        let xs = boundaries(length: screen.width, count: cols)
        let ys = boundaries(length: screen.height, count: rows)
        return CGRect(
            x: screen.minX + xs[startCol],
            y: screen.minY + ys[startRow],
            width: xs[endCol] - xs[startCol],
            height: ys[endRow] - ys[startRow]
        )
    }

    // MARK: - Sizing helpers

    static func scaled(_ screen: CGRect, fraction: CGFloat) -> CGRect {
        let w = (screen.width * fraction).rounded()
        let h = (screen.height * fraction).rounded()
        let x = (screen.minX + (screen.width - w) / 2).rounded()
        let y = (screen.minY + (screen.height - h) / 2).rounded()
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func centered(size: CGSize, in screen: CGRect) -> CGRect {
        let w = min(size.width, screen.width)
        let h = min(size.height, screen.height)
        let x = (screen.minX + (screen.width - w) / 2).rounded()
        let y = (screen.minY + (screen.height - h) / 2).rounded()
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Grow (`delta > 0`) or shrink (`delta < 0`) `current` by `delta`
    /// fraction of screen on each axis, preserving center, then clamp
    /// into `screen` with a minimum edge.
    static func resized(_ current: CGRect, by delta: CGFloat, in screen: CGRect) -> CGRect {
        let dx = screen.width * delta
        let dy = screen.height * delta
        var w = current.width + dx
        var h = current.height + dy
        w = max(minimumWindowEdge, min(w, screen.width))
        h = max(minimumWindowEdge, min(h, screen.height))
        let cx = current.midX
        let cy = current.midY
        var x = cx - w / 2
        var y = cy - h / 2
        // Clamp into screen.
        x = max(screen.minX, min(x, screen.maxX - w))
        y = max(screen.minY, min(y, screen.maxY - h))
        return CGRect(x: x.rounded(), y: y.rounded(), width: w.rounded(), height: h.rounded())
    }
}

// MARK: - Coordinate conversion

/// Converts rectangles between Accessibility (top-left origin, y-down) and
/// Cocoa / NSScreen (bottom-left origin, y-up) conventions.
///
/// macOS multi-display coordinate space: the "global" origin is the
/// **bottom-left of the primary display** in Cocoa, and the **top-left of
/// the primary display** in AX. Converting requires the primary display's
/// frame (its height and origin in the target system).
public enum CoordinateConverter {

    /// Convert an AX (top-left origin) rect to Cocoa (bottom-left origin).
    /// - Parameter primaryHeight: height of the primary display (NSScreen.screens[0].frame.height).
    public static func axToCocoa(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Convert a Cocoa (bottom-left origin) rect to AX (top-left origin).
    public static func cocoaToAX(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}

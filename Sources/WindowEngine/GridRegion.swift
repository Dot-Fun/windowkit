import CoreGraphics
import Foundation

/// A rectangular screen region expressed as a sub-range of a uniform
/// `cols × rows` grid (top-left origin, row 0 = top). `colEnd`/`rowEnd`
/// are exclusive. Produced by `NumpadRegionResolver` and turned into a
/// concrete frame by `Geometry.frame(for:screen:)`.
///
/// Using a grid sub-range (rather than raw fractions) lets us reuse
/// `Geometry`'s integer boundary math, so regions tile the screen exactly.
public struct GridRegion: Equatable, Sendable {
    public let cols: Int
    public let rows: Int
    public let colStart: Int
    public let colEnd: Int
    public let rowStart: Int
    public let rowEnd: Int

    public init(cols: Int, rows: Int, colStart: Int, colEnd: Int, rowStart: Int, rowEnd: Int) {
        self.cols = cols
        self.rows = rows
        self.colStart = colStart
        self.colEnd = colEnd
        self.rowStart = rowStart
        self.rowEnd = rowEnd
    }

    /// Whole screen.
    public static let fullscreen = GridRegion(cols: 1, rows: 1, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 1)
}

public extension GridRegion {
    /// The region as `(x, y, w, h)` fractions of the screen (0...1, top-left
    /// origin). Used by the overlay to draw a 1:1 preview of the window's footprint.
    var fractions: (x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        (
            CGFloat(colStart) / CGFloat(cols),
            CGFloat(rowStart) / CGFloat(rows),
            CGFloat(colEnd - colStart) / CGFloat(cols),
            CGFloat(rowEnd - rowStart) / CGFloat(rows)
        )
    }

    /// A short human label for the region, e.g. "Left Half", "Top-Left Quarter",
    /// "Top Third", "Top-Left 2×2", "Fullscreen". Used as the overlay caption.
    func describe() -> String {
        let f = fractions
        let t: CGFloat = 1.0 / 3.0
        func approx(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.02 }
        let fullW = approx(f.w, 1), fullH = approx(f.h, 1)

        if fullW && fullH { return "Fullscreen" }
        // Halves
        if approx(f.w, 0.5) && fullH { return f.x < 0.25 ? "Left Half" : "Right Half" }
        if fullW && approx(f.h, 0.5) { return f.y < 0.25 ? "Top Half" : "Bottom Half" }
        // Quarters (½ × ½)
        if approx(f.w, 0.5) && approx(f.h, 0.5) {
            return "\(f.y < 0.25 ? "Top" : "Bottom")-\(f.x < 0.25 ? "Left" : "Right") Quarter"
        }
        // Vertical thirds (full-height columns)
        if approx(f.w, t) && fullH {
            return f.x < 0.1 ? "Left Third" : (f.x > 0.6 ? "Right Third" : "Center Third")
        }
        // Horizontal thirds (full-width bands)
        if fullW && approx(f.h, t) {
            return f.y < 0.1 ? "Top Third" : (f.y > 0.6 ? "Bottom Third" : "Middle Third")
        }
        // Two-thirds
        if approx(f.w, 2 * t) && fullH { return f.x < 0.1 ? "Left Two-Thirds" : "Right Two-Thirds" }
        if fullW && approx(f.h, 2 * t) { return f.y < 0.1 ? "Top Two-Thirds" : "Bottom Two-Thirds" }
        // Corner 2×2 block (⅔ × ⅔)
        if approx(f.w, 2 * t) && approx(f.h, 2 * t) {
            return "\(f.y < 0.1 ? "Top" : "Bottom")-\(f.x < 0.1 ? "Left" : "Right") 2×2"
        }
        // Single 1/9 cell
        if approx(f.w, t) && approx(f.h, t) {
            let v = f.y < 0.1 ? "Top" : (f.y > 0.6 ? "Bottom" : "Middle")
            let h = f.x < 0.1 ? "Left" : (f.x > 0.6 ? "Right" : "Center")
            return "\(v) \(h) Cell"
        }
        return "Region"
    }
}

/// Resolves a sequence of numeric-keypad digits into a screen region,
/// treating the numpad as a literal 3×3 map of the screen:
///
///     7 8 9        top-left   top-center  top-right
///     4 5 6   →    mid-left   center      mid-right
///     1 2 3        bot-left   bot-center  bot-right
///
/// Rules (order of the presses never matters):
///   • **Distinct keys** → the bounding box spanning them on the 3×3 grid.
///     This yields single cells, 2-cell dominoes, third bands (`7‑9`),
///     vertical thirds (`7‑1`), 2×2 blocks (`7‑5`), two-thirds (`7‑6`),
///     and fullscreen (opposite corners, `7‑3`).
///   • **One key repeated** → off-grid sizes anchored to that key:
///       – edge-center `8/4/6/2`: ×2 = half, ×3+ = third band
///       – corner `7/9/1/3`:      ×2+ = that ½×½ quadrant
///       – center `5`:            ×2+ = fullscreen (maximize)
///
/// Digits outside 1…9 (e.g. keypad `0`) are ignored. Returns `nil` for an
/// empty/invalid sequence.
public enum NumpadRegionResolver {
    public static func resolve(_ digits: [Int]) -> GridRegion? {
        let keys = digits.filter { (1...9).contains($0) }
        guard !keys.isEmpty else { return nil }

        let distinct = Set(keys)
        if distinct.count == 1 {
            return repeated(distinct.first!, count: keys.count)
        }
        return boundingBox(of: distinct)
    }

    /// `(row, col)` of a numpad digit on the 3×3 grid (row 0 = top, col 0 = left).
    static func cell(of digit: Int) -> (row: Int, col: Int) {
        (2 - (digit - 1) / 3, (digit - 1) % 3)
    }

    private static func boundingBox(of keys: Set<Int>) -> GridRegion {
        let cells = keys.map(cell(of:))
        let rowStart = cells.map(\.row).min()!
        let rowEnd = cells.map(\.row).max()! + 1
        let colStart = cells.map(\.col).min()!
        let colEnd = cells.map(\.col).max()! + 1
        return GridRegion(cols: 3, rows: 3, colStart: colStart, colEnd: colEnd, rowStart: rowStart, rowEnd: rowEnd)
    }

    private static func repeated(_ digit: Int, count: Int) -> GridRegion {
        let (row, col) = cell(of: digit)

        // Single tap → the 1/9 cell.
        if count == 1 {
            return GridRegion(cols: 3, rows: 3, colStart: col, colEnd: col + 1, rowStart: row, rowEnd: row + 1)
        }

        // Center repeated → maximize.
        if digit == 5 { return .fullscreen }

        let isCorner = (digit == 1 || digit == 3 || digit == 7 || digit == 9)
        if isCorner {
            // Corner ×2+ → that ½×½ quadrant. Corners sit at col/row 0 or 2.
            let qCol = col == 0 ? 0 : 1
            let qRow = row == 0 ? 0 : 1
            return GridRegion(cols: 2, rows: 2, colStart: qCol, colEnd: qCol + 1, rowStart: qRow, rowEnd: qRow + 1)
        }

        // Edge-center: ×2 = half, ×3+ = third band.
        return count == 2 ? half(of: digit) : thirdBand(of: digit)
    }

    /// Edge-center halves on a 2×2 grid (full extent on the perpendicular axis).
    private static func half(of digit: Int) -> GridRegion {
        switch digit {
        case 8: return GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 2, rowStart: 0, rowEnd: 1) // top half
        case 2: return GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 2, rowStart: 1, rowEnd: 2) // bottom half
        case 4: return GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 2) // left half
        case 6: return GridRegion(cols: 2, rows: 2, colStart: 1, colEnd: 2, rowStart: 0, rowEnd: 2) // right half
        default: return .fullscreen
        }
    }

    /// Edge-center third bands on the 3×3 grid (full extent on the other axis).
    private static func thirdBand(of digit: Int) -> GridRegion {
        switch digit {
        case 8: return GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 0, rowEnd: 1) // top third
        case 2: return GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 2, rowEnd: 3) // bottom third
        case 4: return GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 3) // left third
        case 6: return GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 0, rowEnd: 3) // right third
        default: return .fullscreen
        }
    }
}

import AppKit
import SwiftUI
import WindowEngine

/// Observable state for the grid overlay. `region` is the live preview of what
/// the focused window will become; `caption` names it.
@MainActor
final class GridOverlayModel: ObservableObject {
    @Published var region: GridRegion?
    @Published var caption: String = ""
}

/// Manages a click-through, non-activating glass panel that visualizes the
/// numpad sequence language: a 3×3 grid of the screen with a live preview
/// rectangle of the region the window will snap to.
///
/// The panel never becomes key and ignores mouse events, so it cannot steal
/// focus from the window you're arranging (which would break the whole feature).
@MainActor
final class GridOverlayController {
    private let model = GridOverlayModel()
    private var panel: NSPanel?

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Show the overlay covering `screen`'s visible area (where windows tile).
    func show(on screen: NSScreen) {
        let panel = ensurePanel()
        panel.setFrame(screen.visibleFrame, display: true)
        guard !panel.isVisible else { return }
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = reduceMotion ? 0 : 0.12
            panel.animator().alphaValue = 1
        }
    }

    /// Update the previewed region (nil = grid shown but nothing selected yet).
    func update(region: GridRegion?) {
        model.region = region
        model.caption = region?.describe() ?? ""
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = reduceMotion ? 0 : 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            // NSAnimationContext completions fire on the main thread.
            MainActor.assumeIsolated {
                self?.panel?.orderOut(nil)
                self?.model.region = nil
                self?.model.caption = ""
            }
        })
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = .screenSaver
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.ignoresMouseEvents = true
        p.isMovable = false
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        let host = NSHostingView(rootView: GridOverlayView(model: model))
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        panel = p
        return p
    }
}

/// The glass grid + live preview rectangle, drawn 1:1 over the screen's
/// visible area. Tiles use system materials (which render as Liquid Glass on
/// macOS 26) with the dotfun-orange accent for the active region.
struct GridOverlayView: View {
    @ObservedObject var model: GridOverlayModel

    /// Numpad labels laid out as the screen: top row 7/8/9.
    private let labels: [[Int]] = [[7, 8, 9], [4, 5, 6], [1, 2, 3]]
    private let gap: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                // Transparent filler so the ZStack always spans the full screen.
                // (.offset doesn't affect layout size, so without a filling child
                // the stack collapses to one tile and gets centered.)
                Color.clear
                gridTiles(w: w, h: h)

                if let region = model.region {
                    let f = region.fractions
                    previewTile
                        .frame(width: max(0, f.w * w), height: max(0, f.h * h))
                        .offset(x: f.x * w, y: f.y * h)
                }

                if !model.caption.isEmpty {
                    captionPill
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 44)
                }
            }
            .frame(width: w, height: h)
            .animation(.spring(response: 0.24, dampingFraction: 0.85), value: model.region)
        }
        .ignoresSafeArea()
    }

    private func gridTiles(w: CGFloat, h: CGFloat) -> some View {
        let cw = w / 3
        let ch = h / 3
        return ZStack(alignment: .topLeading) {
            ForEach(0..<3, id: \.self) { row in
                ForEach(0..<3, id: \.self) { col in
                    cellTile(label: labels[row][col])
                        .frame(width: cw - gap * 2, height: ch - gap * 2)
                        .offset(x: CGFloat(col) * cw + gap, y: CGFloat(row) * ch + gap)
                }
            }
        }
    }

    private func cellTile(label: Int) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.13), lineWidth: 1)
            )
            .overlay(
                Text("\(label)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.22))
            )
    }

    private var previewTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(dotfunOrange.opacity(0.16))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(dotfunOrange.opacity(0.75), lineWidth: 2)
        }
        .shadow(color: dotfunOrange.opacity(0.22), radius: 10, x: 0, y: 3)
        .padding(3)
    }

    private var captionPill: some View {
        Text(model.caption)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 6)
    }
}

// NotchPosition.swift
// Dynamically calculates where the notch panel should be placed on screen.

import AppKit

/// Describes the geometry needed to position the notch overlay panel.
struct NotchGeometry: Equatable {
    /// The screen this geometry belongs to.
    let screen: NSScreen
    /// Frame for the *compact* (collapsed) panel — pill shape.
    let compactFrame: NSRect
    /// Frame for the *expanded* panel — card shape.
    let expandedFrame: NSRect
    /// True when the screen actually has a hardware notch.
    let hasNotch: Bool
}

enum NotchPosition {

    // MARK: - Panel dimensions

    static let compactSize  = CGSize(width: 126, height: 32)
    static let expandedSize = CGSize(width: 440, height: 190)

    // MARK: - Public API

    /// Returns the geometry for the given screen, or `nil` if the screen is
    /// not suitable (e.g. very small external monitor that reported no safe area).
    static func geometry(for screen: NSScreen) -> NotchGeometry {
        // `safeAreaInsets.top` is > 0 only on notched MacBook displays (macOS 12+).
        let safeTop = screen.safeAreaInsets.top
        let hasNotch = safeTop > 0

        // The notch is horizontally centred on the screen's full frame.
        let screenFrame = screen.frame          // origin may be non-zero for secondary screens
        let midX = screenFrame.midX

        // ── Compact frame ────────────────────────────────────────────────────
        // We sit *inside* the notch area: vertically flush with the menu-bar
        // height so the black pill blends with the notch cutout.
        let compactOriginX = midX - compactSize.width / 2
        let compactOriginY = screenFrame.maxY - compactSize.height      // AppKit: Y grows upward

        let compactFrame = NSRect(
            x: compactOriginX,
            y: compactOriginY,
            width: compactSize.width,
            height: compactSize.height
        )

        // ── Expanded frame ───────────────────────────────────────────────────
        // Anchored at the same top-centre; drops down from there.
        let expandedOriginX = midX - expandedSize.width / 2
        let expandedOriginY = screenFrame.maxY - expandedSize.height

        let expandedFrame = NSRect(
            x: expandedOriginX,
            y: expandedOriginY,
            width: expandedSize.width,
            height: expandedSize.height
        )

        return NotchGeometry(
            screen: screen,
            compactFrame: compactFrame,
            expandedFrame: expandedFrame,
            hasNotch: hasNotch
        )
    }

    /// Returns the geometry for the screen that currently contains the mouse
    /// cursor, falling back to the main screen.
    static func geometryForMouseScreen() -> NotchGeometry {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
                     ?? NSScreen.main
                     ?? NSScreen.screens[0]
        return geometry(for: screen)
    }

    /// Returns the geometry for the main (built-in) screen.
    static func geometryForMainScreen() -> NotchGeometry {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        return geometry(for: screen)
    }
}

// NotchPanel.swift
// Transparent, borderless, always-on-top NSPanel that hosts the notch overlay.

import AppKit
import SwiftUI

final class NotchPanel: NSPanel {

    // MARK: - Init

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    // MARK: - Configuration

    private func configure() {
        // Visual
        backgroundColor   = .clear
        isOpaque          = false
        hasShadow         = false

        // Behaviour
        level                   = .statusBar        // floats above normal windows
        hidesOnDeactivate       = false
        isMovable               = false
        ignoresMouseEvents      = false             // we need hover / click events

        // Collection behaviour: sticky across spaces, invisible to Exposé / Mission Control
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]

        // Remove any default chrome
        titlebarAppearsTransparent = true
        titleVisibility            = .hidden
        isReleasedWhenClosed       = false
    }

    // MARK: - Overrides

    /// Allow the panel to become key so SwiftUI interactions (buttons, etc.) work.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Content

    /// Replaces the panel's content with a SwiftUI view hierarchy.
    func setSwiftUIContent<V: View>(_ view: V) {
        let host = NSHostingView(rootView: view)
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        contentView = host
    }

    // MARK: - Positioning

    func place(at geometry: NotchGeometry, expanded: Bool) {
        let targetFrame = expanded ? geometry.expandedFrame : geometry.compactFrame
        setFrame(targetFrame, display: true, animate: false)
    }
}

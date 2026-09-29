// MouseMonitor.swift
// Tracks global mouse movement and fires callbacks when the cursor enters/leaves
// the notch region.
//
// NSEvent global monitor callbacks are delivered on the main thread, so this
// class is confined to @MainActor for safe mutable-state access under Swift 6.

import AppKit

@MainActor
final class MouseMonitor {

    // MARK: - Public state

    /// Published whenever the hover state changes.
    /// Typed as @MainActor so callers can directly invoke @MainActor-isolated code.
    var onHoverChanged: (@MainActor (Bool) -> Void)?

    // MARK: - Private

    private var globalMonitor: Any?
    private var localMonitor:  Any?

    /// The rectangle (in screen coordinates) treated as the "hover zone".
    private(set) var hotRect: NSRect = .zero

    private var isHovering = false

    /// How long (seconds) to wait after the cursor leaves before collapsing.
    private let collapseDelay: TimeInterval = 0.35
    private var collapseTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func start(hotRect: NSRect) {
        self.hotRect = hotRect
        installMonitors()
    }

    func updateHotRect(_ rect: NSRect) {
        hotRect = rect
    }

    func stop() {
        removeMonitors()
        collapseTask?.cancel()
    }

    // MARK: - Monitor setup

    private func installMonitors() {
        removeMonitors()

        // Both global and local monitors deliver on the main thread.
        // The closure captures `self`; @MainActor ensures consistent access.
        let handler: @MainActor (NSEvent) -> Void = { [weak self] _ in
            self?.evaluateCursorPosition()
        }

        // Global monitor: fires when another app has focus.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .mouseEntered, .mouseExited]
        ) { event in
            // NSEvent global monitors call on main thread; bridge to @MainActor.
            Task { @MainActor in handler(event) }
        }

        // Local monitor: fires when our panel has focus.
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .mouseEntered, .mouseExited]
        ) { event in
            Task { @MainActor in handler(event) }
            return event
        }
    }

    private func removeMonitors() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor  { NSEvent.removeMonitor(l); localMonitor  = nil }
    }

    // MARK: - Hit testing

    private func evaluateCursorPosition() {
        let loc    = NSEvent.mouseLocation
        let inRect = NSMouseInRect(loc, hotRect, false)

        if inRect && !isHovering {
            // Cancel any pending collapse
            collapseTask?.cancel()
            collapseTask = nil

            isHovering = true
            onHoverChanged?(true)

        } else if !inRect && isHovering {
            // Debounce collapse — only schedule once.
            guard collapseTask == nil else { return }
            collapseTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(self?.collapseDelay ?? 0.35))
                guard let self, !Task.isCancelled else { return }
                self.isHovering   = false
                self.collapseTask = nil
                self.onHoverChanged?(false)
            }
        }
    }
}

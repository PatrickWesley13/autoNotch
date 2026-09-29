// NotchManager.swift
// Central controller — owns the panel, monitors mouse, drives expand/collapse.

import AppKit
import SwiftUI
import Observation

@MainActor
@Observable
final class NotchManager {

    // MARK: - Observable state

    private(set) var isExpanded: Bool = false
    private(set) var isVisible:  Bool = true

    // MARK: - Public state

    let projectStore = ProjectStore()

    // MARK: - Private

    private let panel        = NotchPanel()
    private let mouseMonitor = MouseMonitor()

    private var currentGeometry: NotchGeometry?

    // MARK: - Lifecycle

    func start() {
        updateGeometry()
        mountContent()
        showPanel()
        startMonitoring()
        projectStore.startPolling()

        // Re-evaluate geometry when screens change (plugging in a monitor, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func stop() {
        mouseMonitor.stop()
        projectStore.stopPolling()
        panel.close()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Visibility toggle

    func toggleVisibility() {
        isVisible.toggle()
        if isVisible {
            showPanel()
        } else {
            panel.orderOut(nil)
        }
    }

    // MARK: - Expand / Collapse

    func expand() {
        guard !isExpanded, let geo = currentGeometry else { return }
        isExpanded = true
        animatePanel(to: geo.expandedFrame)
        // Widen the hot rect so the cursor stays "inside" while card is open
        mouseMonitor.updateHotRect(geo.expandedFrame)
    }

    func collapse() {
        guard isExpanded, let geo = currentGeometry else { return }
        isExpanded = false
        animatePanel(to: geo.compactFrame)
        mouseMonitor.updateHotRect(hotRect(for: geo))
    }

    // MARK: - Private helpers

    private func updateGeometry() {
        let geo = NotchPosition.geometryForMainScreen()
        currentGeometry = geo

        let frame = isExpanded ? geo.expandedFrame : geo.compactFrame
        panel.setFrame(frame, display: false)
    }

    private func mountContent() {
        let view = NotchContainerView(manager: self)
        panel.setSwiftUIContent(view)
    }

    private func showPanel() {
        guard let geo = currentGeometry else { return }
        let frame = isExpanded ? geo.expandedFrame : geo.compactFrame
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    private func startMonitoring() {
        guard let geo = currentGeometry else { return }
        mouseMonitor.start(hotRect: hotRect(for: geo))
        mouseMonitor.onHoverChanged = { @MainActor [weak self] hovering in
            if hovering { self?.expand() }
            else        { self?.collapse() }
        }
    }

    /// The hot rect is always at least as large as the expanded frame
    /// so the monitor keeps tracking when the card is open.
    private func hotRect(for geo: NotchGeometry) -> NSRect {
        return geo.expandedFrame
    }

    private func animatePanel(to frame: NSRect) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration        = 0.38
            ctx.timingFunction  = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    @objc private func screensChanged() {
        updateGeometry()
        if isVisible { showPanel() }
    }
}

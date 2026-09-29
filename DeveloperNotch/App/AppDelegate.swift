// AppDelegate.swift
// macOS accessory-app entry point. No Dock icon.

import AppKit
import SwiftUI

// Entry point — AppKit lifecycle, no SwiftUI @main scene graph.
@main
struct DeveloperNotchEntry {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var notchManager: NotchManager?
    private var statusItem: NSStatusItem?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove from Dock and Application switcher.
        NSApp.setActivationPolicy(.accessory)

        let manager = NotchManager()
        self.notchManager = manager
        manager.start()

        setupStatusItem()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchManager?.stop()
    }

    // MARK: - Status Bar

    /// A minimal status-bar item so the user can quit / toggle the overlay.
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        if let button = item.button {
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "DeveloperNotch")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "DeveloperNotch", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: "Toggle Overlay",
            action: #selector(toggleOverlay),
            keyEquivalent: "t"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit DeveloperNotch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        item.menu = menu
    }

    @objc private func toggleOverlay() {
        notchManager?.toggleVisibility()
    }
}

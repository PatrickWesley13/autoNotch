// NotchContainerView.swift
// Top-level SwiftUI host that animates between compact and expanded states.

import SwiftUI

struct NotchContainerView: View {

    let manager: NotchManager

    var body: some View {
        ZStack {
            // Transparent fill makes the entire panel area hit-testable.
            Color.clear.contentShape(Rectangle())

            if manager.isExpanded {
                ExpandedNotchView(project: manager.projectStore.activeProject)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.90, anchor: .top)
                                .combined(with: .opacity),
                            removal:   .scale(scale: 0.90, anchor: .top)
                                .combined(with: .opacity)
                        )
                    )
            } else {
                CompactNotchView()
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.94, anchor: .top)
                                .combined(with: .opacity),
                            removal:   .scale(scale: 0.94, anchor: .top)
                                .combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(
            .spring(response: 0.38, dampingFraction: 0.78, blendDuration: 0),
            value: manager.isExpanded
        )
        .clipped()
    }
}

// CompactNotchView.swift
// The collapsed pill that blends into the MacBook notch area.

import SwiftUI

struct CompactNotchView: View {

    // MARK: - Constants
    private let pillWidth:  CGFloat = 126
    private let pillHeight: CGFloat = 32

    var body: some View {
        ZStack {
            // Black pill — matches the notch cutout colour
            Capsule()
                .fill(Color.black)
                .frame(width: pillWidth, height: pillHeight)

            // Subtle activity indicator row
            HStack(spacing: 6) {
                // Git branch dot
                Circle()
                    .fill(Color(nsColor: .systemGreen))
                    .frame(width: 7, height: 7)

                // Tiny label
                Text("DEV")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))

                Spacer()

                // PR indicator dot
                Circle()
                    .fill(Color(nsColor: .systemBlue))
                    .frame(width: 7, height: 7)
            }
            .padding(.horizontal, 16)
            .frame(width: pillWidth)
        }
        .frame(width: pillWidth, height: pillHeight)
    }
}

#Preview {
    CompactNotchView()
        .background(Color.gray)
        .preferredColorScheme(.dark)
}

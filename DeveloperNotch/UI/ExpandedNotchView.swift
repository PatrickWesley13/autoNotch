// ExpandedNotchView.swift
// The developer card shown when the notch overlay is expanded.
// Receives a live DeveloperProject from ProjectStore and renders real git data.

import SwiftUI

struct ExpandedNotchView: View {

    var project: DeveloperProject?

    // MARK: - Derived from project

    private var projectName: String  { project?.name ?? "No project" }
    private var branch: String       { project?.gitStatus.branch ?? "—" }
    private var gitStatus: GitStatus { project?.gitStatus ?? .placeholder }
    private var gitError: String?    { project?.gitError }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                divider.padding(.top, 10)

                gitSection
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                divider.padding(.top, 10)

                servicesRow
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
            }
        }
        .frame(width: 440, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            // Live dot
            Circle()
                .fill(gitError == nil ? Color.green : Color.orange)
                .frame(width: 7, height: 7)

            // Project name
            Text(projectName)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Branch badge
            if gitError == nil {
                branchBadge
            }
        }
    }

    private var branchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(branch)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.08), in: Capsule())
        .lineLimit(1)
    }

    // MARK: - Git section

    @ViewBuilder
    private var gitSection: some View {
        if let err = gitError {
            // Error state
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.orange.opacity(0.8))
                Text(err)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.orange.opacity(0.7))
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                gitStatusRow
                commitRow
            }
        }
    }

    private var gitStatusRow: some View {
        HStack(spacing: 10) {
            if gitStatus.isClean {
                statusChip(label: "Clean", color: .green)
            } else {
                if gitStatus.stagedCount    > 0 { statusChip(label: "+\(gitStatus.stagedCount) staged",   color: .green)  }
                if gitStatus.unstagedCount  > 0 { statusChip(label: "~\(gitStatus.unstagedCount) modified", color: .yellow) }
                if gitStatus.untrackedCount > 0 { statusChip(label: "?\(gitStatus.untrackedCount) new",    color: .gray)   }
            }

            Spacer()

            // Sync info (ahead/behind)
            let sync = gitStatus.syncSummary
            if !sync.isEmpty {
                Text(sync)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    private var commitRow: some View {
        HStack(spacing: 6) {
            if !gitStatus.shortHash.isEmpty {
                Text(gitStatus.shortHash)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
            }

            Text(gitStatus.lastCommitMessage.isEmpty ? "No commits yet" : gitStatus.lastCommitMessage)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    // MARK: - Services row

    private var servicesRow: some View {
        HStack(alignment: .center, spacing: 0) {
            servicesTile(
                icon: "arrow.triangle.pull",
                label: "GitHub",
                value: project != nil ? "\(project!.openPRCount) open PR\(project!.openPRCount == 1 ? "" : "s")" : "—",
                color: .blue
            )

            Divider()
                .frame(height: 28)
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 12)

            servicesTile(
                icon: "brain",
                label: "LiteLLM",
                value: project != nil ? project!.llmUsage.formattedCost : "—",
                color: .purple
            )
        }
    }

    // MARK: - Sub-components

    private func statusChip(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.9))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func servicesTile(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color.opacity(0.75))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("With project") {
    ExpandedNotchView(project: {
        let p = DeveloperProject(name: "autoNotch",
                                 directoryURL: URL(fileURLWithPath: "/Users/dev/autoNotch"))
        p.gitStatus = GitStatus(
            branch: "feat/notch-ui",
            isClean: false,
            aheadCount: 2,
            behindCount: 0,
            stagedCount: 3,
            unstagedCount: 5,
            untrackedCount: 1,
            lastCommitHash: "a1b2c3d",
            lastCommitMessage: "Add expanded notch view with git status"
        )
        return p
    }())
    .background(Color.gray.opacity(0.3))
    .preferredColorScheme(.dark)
}

#Preview("Clean repo") {
    ExpandedNotchView(project: DeveloperProject.placeholder)
        .background(Color.gray.opacity(0.3))
        .preferredColorScheme(.dark)
}

#Preview("Error state") {
    ExpandedNotchView(project: {
        let p = DeveloperProject(name: "my-project")
        p.gitError = "Not a git repository"
        return p
    }())
    .background(Color.gray.opacity(0.3))
    .preferredColorScheme(.dark)
}

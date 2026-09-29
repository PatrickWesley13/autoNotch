// GitStatus.swift
// Snapshot of a git repository's local state.

import Foundation

struct GitStatus: Equatable {
    var branch:           String
    var isClean:          Bool
    var aheadCount:       Int
    var behindCount:      Int
    var stagedCount:      Int
    var unstagedCount:    Int
    var untrackedCount:   Int
    var lastCommitHash:   String   // short 7-char hash, empty when no commits
    var lastCommitMessage: String  // subject line, empty when no commits

    // MARK: - Display helpers

    /// Single-line summary of dirty state.
    var statusSummary: String {
        if isClean { return "Clean" }
        var parts: [String] = []
        if stagedCount    > 0 { parts.append("+\(stagedCount)")  }
        if unstagedCount  > 0 { parts.append("~\(unstagedCount)") }
        if untrackedCount > 0 { parts.append("?\(untrackedCount)") }
        return parts.joined(separator: "  ")
    }

    /// Ahead/behind summary relative to tracking branch.
    var syncSummary: String {
        switch (aheadCount, behindCount) {
        case (0, 0): return ""
        case (let a, 0) where a > 0: return "↑\(a)"
        case (0, let b) where b > 0: return "↓\(b)"
        default: return "↑\(aheadCount) ↓\(behindCount)"
        }
    }

    /// Short commit hash for display (first 7 chars, already short from git).
    var shortHash: String {
        lastCommitHash.isEmpty ? "" : String(lastCommitHash.prefix(7))
    }

    // MARK: - Placeholder

    static let placeholder = GitStatus(
        branch: "main",
        isClean: true,
        aheadCount: 0,
        behindCount: 0,
        stagedCount: 0,
        unstagedCount: 0,
        untrackedCount: 0,
        lastCommitHash: "a1b2c3d",
        lastCommitMessage: "Initial commit"
    )
}

// PullRequest.swift
// Model representing a GitHub Pull Request.

import Foundation

struct PullRequest: Identifiable, Equatable {
    let id:         Int
    let number:     Int
    let title:      String
    let author:     String
    let state:      PRState
    let isDraft:    Bool
    let reviewState: ReviewState
    let url:        URL?
    let createdAt:  Date

    // MARK: - Enums

    enum PRState: String, Equatable {
        case open, closed, merged
    }

    enum ReviewState: String, Equatable {
        case pending        = "PENDING"
        case approved       = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case commented      = "COMMENTED"
        case dismissed      = "DISMISSED"
    }

    // MARK: - Placeholder

    static let placeholder = PullRequest(
        id: 1,
        number: 42,
        title: "Add notch overlay feature",
        author: "developer",
        state: .open,
        isDraft: false,
        reviewState: .pending,
        url: URL(string: "https://github.com/example/repo/pull/42"),
        createdAt: Date()
    )
}

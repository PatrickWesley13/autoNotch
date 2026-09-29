// GitHubService.swift
// Placeholder: fetches Pull Requests from the GitHub REST API.

import Foundation

/// Fetches open PRs for a repository via the GitHub REST API.
/// Set `token` to a personal access token with `repo` scope.
actor GitHubService {

    var token: String = ""   // Set via Settings UI or Keychain in production

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy  = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Public

    func openPullRequests(owner: String, repo: String) async throws -> [PullRequest] {
        // TODO: implement real GitHub API call
        // Stub returns placeholder until implemented.
        return [.placeholder]
    }
}

// DeveloperProject.swift
// Aggregate model combining all signals for one watched project.

import Foundation

@MainActor
@Observable
final class DeveloperProject: Identifiable {
    let id = UUID()

    var name:         String
    var directoryURL: URL?

    // Populated by background services
    var gitStatus:    GitStatus      = .placeholder
    var gitError:     String?        = nil
    var pullRequests: [PullRequest]  = []
    var llmUsage:     LiteLLMUsage  = .placeholder

    // MARK: - Computed

    var openPRCount: Int {
        pullRequests.filter { $0.state == .open && !$0.isDraft }.count
    }

    // MARK: - Init

    init(name: String, directoryURL: URL? = nil) {
        self.name         = name
        self.directoryURL = directoryURL
    }

    // MARK: - Placeholder

    static let placeholder: DeveloperProject = {
        let p = DeveloperProject(
            name: "autoNotch",
            directoryURL: URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Developer/pessoal/autoNotch")
        )
        p.pullRequests = [.placeholder]
        return p
    }()
}

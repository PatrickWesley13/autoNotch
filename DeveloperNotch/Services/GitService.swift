// GitService.swift
// Reads a git repository's status by shelling out to /usr/bin/git.
// Parses `git status --porcelain=v2 --branch` for branch and file info,
// then fetches the last commit via `git log`.

import Foundation

// MARK: - Error

enum GitServiceError: LocalizedError {
    case gitNotFound
    case notARepository(URL)
    case commandFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .gitNotFound:
            return "git not found at /usr/bin/git"
        case .notARepository(let url):
            return "Not a git repository: \(url.path)"
        case .commandFailed(let code, let err):
            return "git exited \(code): \(err)"
        }
    }
}

// MARK: - Service

actor GitService {

    static let shared = GitService()

    private let gitPath = "/usr/bin/git"

    // MARK: - Public API

    /// Full snapshot: branch + dirty state + last commit.
    func status(for directoryURL: URL) async throws -> GitStatus {
        let raw = try await run(
            ["status", "--porcelain=v2", "--branch"],
            at: directoryURL
        )
        var status = try Self.parsePortcelainV2(raw, directory: directoryURL)

        // Overlay commit info (best-effort; empty repo has no commits).
        if let (hash, message) = try? await lastCommit(for: directoryURL) {
            status.lastCommitHash    = hash
            status.lastCommitMessage = message
        }

        return status
    }

    // MARK: - Private parsers

    /// Parses `git status --porcelain=v2 --branch` output into a GitStatus.
    private static func parsePortcelainV2(
        _ output: String,
        directory: URL
    ) throws -> GitStatus {
        var branch        = "HEAD"
        var aheadCount    = 0
        var behindCount   = 0
        var stagedCount   = 0
        var unstagedCount = 0
        var untrackedCount = 0

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("# branch.head ") {
                // e.g. "# branch.head main" or "# branch.head (detached)"
                let raw = String(line.dropFirst("# branch.head ".count))
                branch = raw == "(detached)" ? "HEAD (detached)" : raw

            } else if line.hasPrefix("# branch.ab ") {
                // e.g. "# branch.ab +2 -1"
                let parts = line.components(separatedBy: " ")
                // parts: ["#", "branch.ab", "+2", "-1"]
                if parts.count >= 4 {
                    aheadCount  = Int(parts[2].dropFirst()) ?? 0  // drop "+"
                    behindCount = Int(parts[3].dropFirst()) ?? 0  // drop "-"
                }

            } else if line.hasPrefix("1 ") || line.hasPrefix("2 ") {
                // Ordinary or renamed changed entry: "1 XY ..."
                let chars = Array(line)
                guard chars.count >= 4 else { continue }
                let x = chars[2]   // staged status
                let y = chars[3]   // unstaged status
                if x != "." { stagedCount    += 1 }
                if y != "." { unstagedCount  += 1 }

            } else if line.hasPrefix("u ") {
                // Unmerged entry — counts as unstaged conflict
                unstagedCount += 1

            } else if line.hasPrefix("? ") {
                // Untracked file
                untrackedCount += 1
            }
        }

        let isClean = stagedCount == 0 && unstagedCount == 0 && untrackedCount == 0

        return GitStatus(
            branch:            branch,
            isClean:           isClean,
            aheadCount:        aheadCount,
            behindCount:       behindCount,
            stagedCount:       stagedCount,
            unstagedCount:     unstagedCount,
            untrackedCount:    untrackedCount,
            lastCommitHash:    "",
            lastCommitMessage: ""
        )
    }

    /// Returns (shortHash, subjectLine) for the most recent commit.
    private func lastCommit(for directoryURL: URL) async throws -> (String, String) {
        // %h = abbreviated hash, %s = subject, separated by NUL for safe splitting
        let output = try await run(
            ["log", "-1", "--pretty=format:%h%x00%s"],
            at: directoryURL
        )
        let parts = output.components(separatedBy: "\0")
        let hash    = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subject = parts.dropFirst().first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (hash, subject)
    }

    // MARK: - Shell runner

    /// Runs git with the given arguments in directoryURL, returns stdout.
    /// Throws GitServiceError on non-zero exit.
    private func run(_ args: [String], at url: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: gitPath) else {
            throw GitServiceError.gitNotFound
        }

        return try await Task.detached(priority: .utility) { [gitPath] in
            let proc = Process()
            proc.executableURL       = URL(fileURLWithPath: gitPath)
            proc.arguments           = args
            proc.currentDirectoryURL = url

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            proc.standardOutput = stdoutPipe
            proc.standardError  = stderrPipe

            do {
                try proc.run()
            } catch {
                throw GitServiceError.gitNotFound
            }

            proc.waitUntilExit()

            let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let output  = String(data: outData, encoding: .utf8) ?? ""

            let exitCode = proc.terminationStatus
            if exitCode != 0 {
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let errStr  = String(data: errData, encoding: .utf8) ?? ""

                // exit 128 = not a git repository
                if exitCode == 128 {
                    throw GitServiceError.notARepository(url)
                }
                throw GitServiceError.commandFailed(exitCode: exitCode, stderr: errStr)
            }

            return output
        }.value
    }
}

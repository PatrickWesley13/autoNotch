// ProjectStore.swift
// Manages the list of watched git projects and drives periodic git polling.
// Persists project paths in UserDefaults (no secrets, just directory paths).

import Foundation
import AppKit

@MainActor
@Observable
final class ProjectStore {

    // MARK: - Public state

    /// All configured projects, in display order.
    private(set) var projects: [DeveloperProject] = []

    /// Index of the currently focused project (shown in the notch).
    var activeIndex: Int = 0 {
        didSet {
            activeIndex = max(0, min(activeIndex, projects.count - 1))
            saveToDefaults()
            Task { await refreshActive() }
        }
    }

    /// The project currently shown in the notch, or nil if list is empty.
    var activeProject: DeveloperProject? {
        projects.indices.contains(activeIndex) ? projects[activeIndex] : nil
    }

    // MARK: - Private

    private let git = GitService.shared
    private var pollTask: Task<Void, Never>?
    private let pollInterval: TimeInterval = 30   // seconds between refreshes

    private enum DefaultsKey {
        static let paths       = "ProjectStore.paths"
        static let activeIndex = "ProjectStore.activeIndex"
    }

    // MARK: - Lifecycle

    init() {
        loadFromDefaults()
        if projects.isEmpty {
            seedDefaultProjects()
        }
    }

    /// Start periodic polling. Call from NotchManager.start().
    func startPolling() {
        stopPolling()
        pollTask = Task { [weak self] in
            // Refresh immediately on start, then on interval.
            await self?.refreshActive()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.pollInterval ?? 30))
                guard !Task.isCancelled else { break }
                await self?.refreshActive()
            }
        }
    }

    /// Stop periodic polling. Call from NotchManager.stop().
    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Project management

    /// Add a new project by directory URL. Ignores duplicates.
    func addProject(at url: URL) {
        let canonical = url.standardizedFileURL
        guard !projects.contains(where: { $0.directoryURL?.standardizedFileURL == canonical }) else { return }
        let name    = canonical.lastPathComponent
        let project = DeveloperProject(name: name, directoryURL: canonical)
        projects.append(project)
        saveToDefaults()
        Task { await refresh(project) }
    }

    /// Remove a project at the given index.
    func removeProject(at index: Int) {
        guard projects.indices.contains(index) else { return }
        projects.remove(at: index)
        // Keep activeIndex in bounds.
        if activeIndex >= projects.count {
            activeIndex = max(0, projects.count - 1)
        }
        saveToDefaults()
    }

    /// Cycle to the next project (wraps around).
    func selectNext() {
        guard projects.count > 1 else { return }
        activeIndex = (activeIndex + 1) % projects.count
    }

    // MARK: - Refresh

    /// Refresh git status for the active project only.
    func refreshActive() async {
        guard let project = activeProject else { return }
        await refresh(project)
    }

    /// Refresh git status for a specific project.
    private func refresh(_ project: DeveloperProject) async {
        guard let url = project.directoryURL else {
            project.gitError = "No directory configured"
            return
        }
        do {
            let status = try await git.status(for: url)
            project.gitStatus = status
            project.gitError  = nil
        } catch GitServiceError.notARepository {
            project.gitError = "Not a git repository"
        } catch GitServiceError.gitNotFound {
            project.gitError = "git not found"
        } catch {
            project.gitError = error.localizedDescription
        }
    }

    // MARK: - Persistence

    private func saveToDefaults() {
        let paths = projects.compactMap { $0.directoryURL?.path }
        UserDefaults.standard.set(paths, forKey: DefaultsKey.paths)
        UserDefaults.standard.set(activeIndex, forKey: DefaultsKey.activeIndex)
    }

    private func loadFromDefaults() {
        guard let paths = UserDefaults.standard.stringArray(forKey: DefaultsKey.paths) else { return }
        projects = paths.map { path in
            let url  = URL(fileURLWithPath: path)
            let name = url.lastPathComponent
            return DeveloperProject(name: name, directoryURL: url)
        }
        let saved = UserDefaults.standard.integer(forKey: DefaultsKey.activeIndex)
        activeIndex = projects.indices.contains(saved) ? saved : 0
    }

    // MARK: - Seeding

    /// Looks for git repos in common developer directories and adds the first one found.
    private func seedDefaultProjects() {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let candidates: [URL] = [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("dev"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("code"),
        ]

        let fm = FileManager.default
        for base in candidates {
            guard fm.fileExists(atPath: base.path) else { continue }
            // Add the base folder itself if it's a git repo…
            if fm.fileExists(atPath: base.appendingPathComponent(".git").path) {
                addProject(at: base)
                return
            }
            // …otherwise scan one level deep.
            let contents = (try? fm.contentsOfDirectory(
                at: base,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )) ?? []
            for sub in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if fm.fileExists(atPath: sub.appendingPathComponent(".git").path) {
                    addProject(at: sub)
                    return
                }
            }
        }
    }
}

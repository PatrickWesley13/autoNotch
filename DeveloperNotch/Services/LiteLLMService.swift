// LiteLLMService.swift
// Placeholder: queries a LiteLLM proxy for today's token usage.

import Foundation

/// Connects to a LiteLLM proxy (or any OpenAI-compatible endpoint) and
/// returns aggregated token usage for the current calendar day.
actor LiteLLMService {

    var baseURL: URL = URL(string: "http://localhost:4000")!
    var apiKey:  String = ""   // Set via Settings UI or Keychain in production

    private let session = URLSession.shared

    // MARK: - Public

    func todayUsage() async throws -> LiteLLMUsage {
        // TODO: implement real API call to /usage or /spend endpoints
        // Stub returns placeholder until implemented.
        return .placeholder
    }
}

// LiteLLMUsage.swift
// Model representing token usage from a LiteLLM proxy or OpenAI-compatible endpoint.

import Foundation

struct LiteLLMUsage: Equatable {

    // MARK: - Totals (today)

    var promptTokens:     Int
    var completionTokens: Int
    var totalTokens:      Int

    var estimatedCostUSD: Double   // rough estimate based on model pricing

    // MARK: - Per-model breakdown

    var modelBreakdown: [ModelUsage]

    // MARK: - Nested type

    struct ModelUsage: Identifiable, Equatable {
        let id = UUID()
        let modelName: String
        let tokens:    Int
        let costUSD:   Double
    }

    // MARK: - Formatting helpers

    var formattedTokens: String {
        let k = Double(totalTokens) / 1000.0
        if k >= 1 { return String(format: "%.1fk", k) }
        return "\(totalTokens)"
    }

    var formattedCost: String {
        String(format: "$%.4f", estimatedCostUSD)
    }

    // MARK: - Placeholder

    static let placeholder = LiteLLMUsage(
        promptTokens: 8_000,
        completionTokens: 4_480,
        totalTokens: 12_480,
        estimatedCostUSD: 0.0187,
        modelBreakdown: [
            ModelUsage(modelName: "gpt-4o", tokens: 9_000, costUSD: 0.015),
            ModelUsage(modelName: "gpt-4o-mini", tokens: 3_480, costUSD: 0.0037),
        ]
    )
}

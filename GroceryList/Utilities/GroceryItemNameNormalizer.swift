//
//  GroceryItemNameNormalizer.swift
//  GroceryList
//

import Foundation

/// Pure string normalization — safe to call from any isolation domain.
enum GroceryItemNameNormalizer: Sendable {
    /// Trims whitespace/newlines and collapses internal runs of whitespace for stable duplicate keys.
    nonisolated static func normalizedKey(for raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return collapsed.lowercased()
    }

    nonisolated static func displayName(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

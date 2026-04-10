//
//  GroceryAddItemResult.swift
//  GroceryList
//

import Foundation

/// Result of an add attempt. Top-level `Sendable` so it is safe to compare across isolation boundaries.
enum GroceryAddItemResult: Sendable, Equatable {
    case added
    case emptyName
    case duplicate
}

//
//  GroceryCategory.swift
//  GroceryList
//

import Foundation

enum GroceryCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case dairy
    case vegetables
    case fruits
    case breads
    case meats

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .dairy: return "🥛"
        case .vegetables: return "🥕"
        case .fruits: return "🍎"
        case .breads: return "🍞"
        case .meats: return "🥩"
        }
    }

    /// Full name used on item pills and statistics (UI tests accept "Dairy" or "Milk" for dairy).
    var displayName: String {
        switch self {
        case .dairy: return "Dairy"
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .breads: return "Breads"
        case .meats: return "Meats"
        }
    }

    /// Short label for compact category pickers (matches demo-style truncation targets).
    var shortPickerLabel: String {
        switch self {
        case .dairy: return "Milk"
        case .vegetables: return "Vegetab..."
        case .fruits: return "Fruits"
        case .breads: return "Breads"
        case .meats: return "Meats"
        }
    }

    /// Subtitle under the item name on the home list (aligned with chip labels, e.g. Milk vs Dairy).
    var homeRowCategoryLabel: String {
        switch self {
        case .dairy: return "Milk"
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .breads: return "Breads"
        case .meats: return "Meats"
        }
    }
}

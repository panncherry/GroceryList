//
//  GroceryKeywordInference.swift
//  GroceryList
//

import Foundation

/// Maps typed item names to categories using substring matching (longest keyword wins).
/// Mirrors the reference demo: e.g. “apple” → fruits, “milk” → dairy, “carrot” → vegetables.
enum GroceryKeywordInference {
    nonisolated static func inferredCategory(for rawText: String) -> GroceryCategory? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()

        var bestCategory: GroceryCategory?
        var bestLength = 0

        for pair in mappings {
            for keyword in pair.keywords {
                guard lower.contains(keyword) else { continue }
                if keyword.count > bestLength {
                    bestLength = keyword.count
                    bestCategory = pair.category
                }
            }
        }

        return bestCategory
    }

    private static let mappings: [(category: GroceryCategory, keywords: [String])] = [
        (
            .dairy,
            [
                "condensed milk", "cottage cheese", "cream cheese", "sour cream", "whipped cream",
                "heavy cream", "ice cream", "greek yogurt", "almond milk", "coconut milk", "soy milk",
                "oat milk", "whole milk", "skim milk", "butter", "yogurt", "cheese", "cream", "milk",
                "dairy", "cheddar", "mozzarella", "parmesan", "feta"
            ]
        ),
        (
            .vegetables,
            [
                "bell pepper", "brussels sprout", "sweet potato", "green bean", "snap pea",
                "bok choy", "zucchini", "asparagus", "cauliflower", "mushroom", "cucumber", "broccoli",
                "spinach", "lettuce", "cabbage", "kale", "carrot", "celery", "onion", "garlic",
                "tomato", "potato", "radish", "turnip", "beet", "pepper", "vegetable"
            ]
        ),
        (
            .fruits,
            [
                "dragon fruit", "passion fruit", "pineapple", "watermelon", "honeydew", "cantaloupe",
                "blueberry", "raspberry", "strawberry", "blackberry", "coconut", "avocado",
                "apple", "banana", "orange", "grape", "mango", "kiwi", "lemon", "lime", "pear",
                "peach", "plum", "cherry", "melon", "fruit"
            ]
        ),
        (
            .breads,
            [
                "sourdough", "baguette", "croissant", "pretzel", "bagel", "bread", "bun", "roll",
                "muffin", "biscuit", "toast", "tortilla", "pita", "naan"
            ]
        ),
        (
            .meats,
            [
                "ground beef", "chicken breast", "chicken wing", "chicken thigh", "pork chop",
                "lamb chop", "ribeye", "sirloin", "salmon", "tilapia", "shrimp", "turkey", "chicken",
                "steak", "beef", "pork", "bacon", "sausage", "ham", "lamb", "veal", "meat"
            ]
        )
    ]
}

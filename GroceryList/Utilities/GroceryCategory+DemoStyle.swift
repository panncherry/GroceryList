//
//  GroceryCategory+DemoStyle.swift
//  GroceryList
//

import SwiftUI

extension GroceryCategory {
    /// Solid fill when a category tile is selected (palette from the reference recording).
    var demoSelectedFillColor: Color {
        switch self {
        case .dairy: return Color(red: 0, green: 122 / 255, blue: 1) // #007AFF
        case .vegetables: return Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255) // #34C759
        case .fruits: return Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255) // #FF3B30
        case .breads: return Color(red: 255 / 255, green: 149 / 255, blue: 0) // #FF9500
        case .meats: return Color(red: 255 / 255, green: 45 / 255, blue: 85 / 255) // #FF2D55
        }
    }

    func demoUnselectedTileFillColor() -> Color {
        demoSelectedFillColor.opacity(0.22)
    }
}

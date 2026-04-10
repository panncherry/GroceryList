//
//  GroceryItem.swift
//  GroceryList
//

import Foundation

struct GroceryItem: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var name: String
    var category: GroceryCategory
    var isCompleted: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: GroceryCategory,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, isCompleted, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(GroceryCategory.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

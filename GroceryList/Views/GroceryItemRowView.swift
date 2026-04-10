//
//  GroceryItemRowView.swift
//  GroceryList
//

import SwiftUI

struct GroceryItemRowView: View {
    enum Style {
        /// Legacy compact row (emoji circle, name + category, square delete).
        case home
        /// Home “Recent Items” cards: color dot, name, category pill, circular delete.
        case homeCard
        /// Full list screen: large emoji, name, dot + pill, circular delete (mockup).
        case fullList
        /// Inline list with completion toggle and timestamp (non-card).
        case detailed
    }

    let item: GroceryItem
    let style: Style
    let onToggle: () -> Void
    var onDelete: (() -> Void)?

    init(
        item: GroceryItem,
        style: Style = .detailed,
        onDelete: (() -> Void)? = nil,
        onToggle: @escaping () -> Void
    ) {
        self.item = item
        self.style = style
        self.onDelete = onDelete
        self.onToggle = onToggle
    }

    var body: some View {
        switch style {
        case .home:
            homeRow
        case .homeCard:
            homeCardRow
        case .fullList:
            fullListCardRow
        case .detailed:
            detailedRow
        }
    }

    private var categoryAccent: Color {
        item.category.demoSelectedFillColor
    }

    private var homeRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(item.category.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(item.category.demoUnselectedTileFillColor())
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)

                Text(item.category.homeRowCategoryLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(item.name)")
            }
        }
        .padding(.vertical, 6)
    }

    private var homeCardRow: some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(categoryAccent)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.body.weight(.bold))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)

                Text(item.category.homeRowCategoryLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(categoryAccent.opacity(0.18))
                    )
                    .foregroundStyle(categoryAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(red: 0.96, green: 0.26, blue: 0.21)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(item.name)")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
        )
    }

    private var fullListCardRow: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(item.category.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline.weight(.bold))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)

                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryAccent)
                        .frame(width: 6, height: 6)
                    Text(item.category.homeRowCategoryLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(categoryAccent.opacity(0.16))
                        )
                        .foregroundStyle(categoryAccent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(red: 0.96, green: 0.26, blue: 0.21)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(item.name)")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
        )
    }

    private var detailedRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255) : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Mark as not purchased" : "Mark as purchased")

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)

                Text(item.createdAt.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            Text(item.category.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.category.demoSelectedFillColor)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

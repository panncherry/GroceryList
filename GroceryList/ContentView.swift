//
//  ContentView.swift
//  GroceryList
//

import SwiftUI

private enum GroceryListDemoStyle {
    /// Purple → blue (aligned with demo reference).
    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 0.557, green: 0.176, blue: 0.886),
            Color(red: 0.290, green: 0.0, blue: 0.878)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCornerRadius: CGFloat = 16
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowOpacity: Double = 0.1

    /// Text fields, full-width buttons, and category tiles share one radius so corners feel consistent.
    static let controlCornerRadius: CGFloat = 12

    /// Bottom of the “Add New Item” gradient strip — rounded so it meets the white body smoothly (not a sharp 90°).
    static let cardHeaderBottomCornerRadius: CGFloat = 12

    /// Add button when the name field has text (reference GIF).
    static let addButtonActiveGreen = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)

    static let addButtonDisabledFill = Color(red: 0.78, green: 0.78, blue: 0.80)

    /// Primary add action on card (mockup: dark grey).
    static let addButtonEnabledFill = Color(red: 0.42, green: 0.42, blue: 0.44)

    /// “View Full Grocery List” — green/teal → blue (mockup).
    static let viewFullListGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.72, blue: 0.58),
            Color(red: 0.22, green: 0.48, blue: 0.96)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let recentAllChipGradient = LinearGradient(
        colors: [
            Color(red: 0.557, green: 0.176, blue: 0.886),
            Color(red: 0.290, green: 0.0, blue: 0.878)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ContentView: View {
    @Environment(GroceryListStore.self) private var store

    @State private var itemName: String = ""
    @State private var selectedCategory: GroceryCategory = .dairy
    /// When true, typing no longer overwrites the category (user chose a tile manually).
    @State private var userPinnedCategory = false
    @State private var toastMessage: String?
    @State private var showDuplicateAlert = false
    @State private var navigationPath = NavigationPath()
    /// `nil` = All categories in Recent Items.
    @State private var recentListFilter: GroceryCategory?

    private let maxRecentShown = 10

    private var trimmedItemName: String {
        itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddItem: Bool {
        !trimmedItemName.isEmpty
    }

    private var recentItemsDisplayed: [GroceryItem] {
        let recent = Array(store.recentItems.prefix(maxRecentShown))
        guard let filter = recentListFilter else { return recent }
        return recent.filter { $0.category == filter }
    }

    private var recentStatusLine: String {
        if let c = recentListFilter {
            let n = recentItemsDisplayed.count
            return "Showing \(n) \(c.homeRowCategoryLabel.lowercased()) items"
        }
        return "Showing \(recentItemsDisplayed.count) of \(store.totalCount) items"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                mainList
                    .scrollContentBackground(.hidden)

                if let toastMessage {
                    toastBanner(toastMessage)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationDestination(for: FullListRoute.self) { _ in
                IngredientListView()
            }
            .alert("Duplicate Item", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This item is already in your list.")
            }
            .onChange(of: itemName) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    userPinnedCategory = false
                    selectedCategory = .dairy
                    return
                }
                guard !userPinnedCategory else { return }
                if let inferred = GroceryKeywordInference.inferredCategory(for: newValue) {
                    selectedCategory = inferred
                }
            }
        }
    }

    @ViewBuilder
    private var mainList: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 8, trailing: 4))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                addItemCard
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if store.items.isEmpty {
                Section {
                    emptyState
                        .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 24, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    fullListButton
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                .listRowSeparator(.hidden)

                Section {
                    recentFiltersBlock
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)

                    Text(recentStatusLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)

                    if recentItemsDisplayed.isEmpty, recentListFilter != nil, !store.items.isEmpty {
                        Text("No items in this category.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }

                    ForEach(recentItemsDisplayed) { item in
                        GroceryItemRowView(
                            item: item,
                            style: .homeCard,
                            onDelete: { store.deleteItem(id: item.id) }
                        ) {
                            store.toggleCompleted(id: item.id)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteItem(id: item.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Items")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.totalCount) items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .textCase(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section {
                    shoppingStatsBlock
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 16, trailing: 0))
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Shopping Stats")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GroceryListDemoStyle.brandGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

                Image(systemName: "cart.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Grocery List")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text("Add items to your shopping list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var shoppingStatsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Total items:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(store.totalCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.categoryCounts, id: \.0) { pair in
                        let pct = store.totalCount > 0
                            ? Int(round(Double(pair.1) / Double(store.totalCount) * 100))
                            : 0
                        Text("\(pair.0.displayName): \(pair.1) — \(pct)%")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(pair.0.demoSelectedFillColor.opacity(0.14))
                            )
                            .foregroundStyle(pair.0.demoSelectedFillColor)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addItemCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add New Item")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(GroceryListDemoStyle.brandGradient)
                .foregroundStyle(.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: GroceryListDemoStyle.cardCornerRadius,
                        bottomLeadingRadius: GroceryListDemoStyle.cardHeaderBottomCornerRadius,
                        bottomTrailingRadius: GroceryListDemoStyle.cardHeaderBottomCornerRadius,
                        topTrailingRadius: GroceryListDemoStyle.cardCornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Item Name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    TextField("Enter grocery item...", text: $itemName)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: GroceryListDemoStyle.controlCornerRadius, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("mainItemNameTextField")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(GroceryCategory.allCases) { category in
                                categoryPickerButton(category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button {
                    addTapped()
                } label: {
                    Text("+ Add Item")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: GroceryListDemoStyle.controlCornerRadius, style: .continuous)
                                .fill(canAddItem ? GroceryListDemoStyle.addButtonEnabledFill : GroceryListDemoStyle.addButtonDisabledFill)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canAddItem)
                .accessibilityLabel("Add Item")
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: GroceryListDemoStyle.cardCornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(GroceryListDemoStyle.cardShadowOpacity),
            radius: GroceryListDemoStyle.cardShadowRadius,
            y: 6
        )
    }

    private func categoryPickerButton(_ category: GroceryCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            userPinnedCategory = true
            selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.title2)
                Text(category.shortPickerLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.95) : Color.primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 84, height: 76)
            .background(
                RoundedRectangle(cornerRadius: GroceryListDemoStyle.controlCornerRadius, style: .continuous)
                    .fill(
                        isSelected
                            ? category.demoSelectedFillColor
                            : category.demoUnselectedTileFillColor()
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: GroceryListDemoStyle.controlCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.35) : Color.black.opacity(0.06),
                        lineWidth: isSelected ? 0 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName) category")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var fullListButton: some View {
        Button {
            navigationPath.append(FullListRoute.full)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet")
                    .font(.headline.weight(.semibold))
                Text("View Full Grocery List")
                    .font(.headline.weight(.semibold))
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GroceryListDemoStyle.controlCornerRadius, style: .continuous)
                    .fill(GroceryListDemoStyle.viewFullListGradient)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("viewFullGroceryListButton")
    }

    private var recentFiltersBlock: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                recentAllChip
                ForEach(GroceryCategory.allCases) { category in
                    recentCategoryChip(category)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var recentAllChip: some View {
        let selected = recentListFilter == nil
        return Button {
            recentListFilter = nil
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                Text("All")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if selected {
                        Capsule().fill(GroceryListDemoStyle.recentAllChipGradient)
                    } else {
                        Capsule().fill(Color(.secondarySystemGroupedBackground))
                    }
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All recent items")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func recentCategoryChip(_ category: GroceryCategory) -> some View {
        let selected = recentListFilter == category
        return Button {
            recentListFilter = selected ? nil : category
        } label: {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.homeRowCategoryLabel)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        selected
                            ? category.demoSelectedFillColor
                            : Color(.secondarySystemGroupedBackground)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName) filter")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Your grocery list is empty")
                .font(.headline)
            Text("Add items above to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func toastBanner(_ message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(GroceryListDemoStyle.addButtonActiveGreen.opacity(0.92))
            )
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func addTapped() {
        let result = store.addItem(rawName: itemName, category: selectedCategory)
        switch result {
        case .added:
            itemName = ""
            userPinnedCategory = false
            selectedCategory = .dairy
            showToast("Item added successfully!")
        case .emptyName:
            showToast("Please enter an item name.")
        case .duplicate:
            showDuplicateAlert = true
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                toastMessage = nil
            }
        }
    }
}

enum FullListRoute: Hashable {
    case full
}

#Preview {
    ContentView()
        .environment(GroceryListStore())
}

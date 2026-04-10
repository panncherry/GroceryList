//
//  IngredientListView.swift
//  GroceryList
//

import SwiftUI

private enum FullListTheme {
    static let headerGradient = LinearGradient(
        colors: [
            Color(red: 0.557, green: 0.329, blue: 0.91),
            Color(red: 0.278, green: 0.467, blue: 0.90)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let allChipGradient = LinearGradient(
        colors: [
            Color(red: 0.557, green: 0.176, blue: 0.886),
            Color(red: 0.290, green: 0.0, blue: 0.878)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct IngredientListView: View {
    @Environment(GroceryListStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var listSearchModel = IngredientListSearchModel()
    @State private var showClearConfirm = false

    var body: some View {
        @Bindable var searchModel = listSearchModel

        GeometryReader { _ in
            VStack(spacing: 0) {
                fullListHeader

                searchAndFilters(searchModel: searchModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                listSummaryRow(searchModel: searchModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                listBody(searchModel: searchModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            searchModel.recomputeImmediately(store: store)
        }
        .onChange(of: searchModel.searchFieldText) { _, _ in
            searchModel.onSearchFieldChanged(store: store)
        }
        .onChange(of: searchModel.selectedCategory) { _, _ in
            searchModel.recomputeImmediately(store: store)
        }
        .onChange(of: store.dataRevision) { _, _ in
            searchModel.recomputeImmediately(store: store)
        }
        .alert("Clear All Items", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("Are you sure you want to remove all \(store.totalCount) items from your grocery list?")
        }
    }

    /// Background is only as tall as the header; content uses safe area so Back sits just under the status bar.
    private var fullListHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text("Full Grocery List")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 0) {
                headerStatColumn(value: "\(store.totalCount)", caption: "Total Items")
                headerStatColumn(value: "\(store.distinctCategoryCount)", caption: "Categories")
                headerStatColumn(value: store.recentActivityHeadline, caption: "Recent")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background {
            FullListTheme.headerGradient
                .ignoresSafeArea(edges: .top)
        }
    }

    private func headerStatColumn(value: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(caption)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity)
    }

    private func searchAndFilters(searchModel: IngredientListSearchModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search items...", text: Bindable(searchModel).searchFieldText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("fullListSearchTextField")

                if searchModel.isFilteringLargeList {
                    ProgressView()
                        .accessibilityLabel("Filtering list")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            if searchModel.isSearchDebouncePending,
               !searchModel.searchFieldText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Updating results…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    allFilterChip(selected: searchModel.selectedCategory == nil) {
                        searchModel.selectedCategory = nil
                    }
                    ForEach(GroceryCategory.allCases) { cat in
                        categoryFilterChip(
                            category: cat,
                            selected: searchModel.selectedCategory == cat
                        ) {
                            searchModel.selectedCategory = cat
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func allFilterChip(selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
                        Capsule().fill(FullListTheme.allChipGradient)
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
        .accessibilityLabel("All categories")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func categoryFilterChip(category: GroceryCategory, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    private func listSummaryRow(searchModel: IngredientListSearchModel) -> some View {
        HStack(alignment: .center) {
            Text("Showing \(searchModel.visibleItemCount) of \(store.totalCount) items")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Button {
                showClearConfirm = true
            } label: {
                Text("Clear All")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .disabled(store.totalCount == 0)
        }
    }

    private func listBody(searchModel: IngredientListSearchModel) -> some View {
        Group {
            if searchModel.groupedSections.isEmpty {
                emptyFiltered
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(searchModel.groupedSections, id: \.0) { section in
                        Section {
                            ForEach(section.1) { item in
                                GroceryItemRowView(
                                    item: item,
                                    style: .fullList,
                                    onDelete: { store.deleteItem(id: item.id) }
                                ) {
                                    store.toggleCompleted(id: item.id)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            categorySectionHeader(category: section.0, count: section.1.count)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func categorySectionHeader(category: GroceryCategory, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(category.emoji)
                .font(.title3)
            Text(category.homeRowCategoryLabel)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(minWidth: 28, minHeight: 28)
                .background(Circle().fill(category.demoSelectedFillColor))
        }
        .padding(.top, 4)
    }

    private var emptyFiltered: some View {
        ContentUnavailableView(
            "No matches",
            systemImage: "magnifyingglass",
            description: Text("Try a different search or category filter.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview("Sample") {
    NavigationStack {
        IngredientListView()
    }
    .environment(GroceryListStore(items: [
        GroceryItem(name: "Milk", category: .dairy),
        GroceryItem(name: "Carrot", category: .vegetables)
    ]))
}

#Preview("Large list (5k) — scroll performance") {
    NavigationStack {
        IngredientListView()
    }
    .environment(GroceryListStore.previewLargeList(itemCount: 5_000))
}

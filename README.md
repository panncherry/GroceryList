# Grocery List

Native **iOS** app for building a categorized grocery list: add items with type-aware categories, track completion, filter and search at scale, and review aggregate stats. Built to demonstrate solid **SwiftUI**, **Observation**, and **test-backed** list logic—not a toy CRUD demo.

![2124365-ios-grocery-list-app-medium-demo](https://github.com/user-attachments/assets/a7fc3c03-089c-4202-a3fe-7b89876a9a35)


## What it does

- **Add flow** — Item name + category picker (dairy, vegetables, fruits, breads, meats). Optional keyword-based category suggestion while typing. Duplicate names rejected with explicit result handling (empty / duplicate / success).
- **Home** — Branded card UI, recent items with category filters, shopping stats (totals and per-category share), navigation to the full list.
- **Full list** — Search (debounced), category chips, grouped sections by category, completion toggle, delete, bulk clear with confirmation. Summary header (totals, distinct categories, recency).
- **Quality bar** — UI test covers add → filter → full list → search → back. Unit tests cover normalization, duplicates, stats, filtering, grouping, and search behavior.

## Engineering notes

| Area | Approach |
|------|----------|
| **State** | Single `@Observable` store on the main actor; mutations invalidate memoized tallies; `dataRevision` lets dependent models coalesce work. |
| **Scale** | Full-list filter/group is pure `Sendable` code; above a threshold, recomputation runs off the main thread with generation tokens to avoid stale updates. Search is debounced to limit churn while typing. |
| **Correctness** | Duplicate detection uses normalized keys (trimmed, case/whitespace-insensitive). Add API returns a typed result instead of silent failures. |
| **UI** | `NavigationStack` + typed route for full list; environment-injected store; list rows split by context (home cards vs. full-list layout). |

## Requirements

- Xcode compatible with the project’s deployment target (see `GroceryList.xcodeproj`).
- Run **GroceryList** scheme on Simulator or device; run **GroceryListTests** / **GroceryListUITests** from the Test navigator.

## Repository layout

```
GroceryList/
├── GroceryList/           # App target — views, view models, store, models, utilities
├── GroceryListTests/      # Unit tests (core + large-list/search model)
└── GroceryListUITests/    # UI tests (navigation and full-list search)
```

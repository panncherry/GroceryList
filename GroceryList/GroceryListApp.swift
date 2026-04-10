//
//  GroceryListApp.swift
//  GroceryList
//
//  Created by Pann Cherry on 4/9/26.
//

import SwiftUI

@main
struct GroceryListApp: App {
    @State private var groceryStore = GroceryListStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(groceryStore)
        }
    }
}

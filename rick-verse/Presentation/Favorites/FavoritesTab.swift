//
//  FavoritesTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Favorites tab.
struct FavoritesTab: View {
    @Bindable var coordinator: FavoritesCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlaceholderView(title: "Favorites")
                .navigationDestination(for: FavoritesCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    FavoritesTab(coordinator: FavoritesCoordinator())
}

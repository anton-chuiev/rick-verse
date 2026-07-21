//
//  FavoritesTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Favorites tab. Wraps the list in a `NavigationStack` bound
/// to the flow coordinator's path, and pushes Character Detail on row tap —
/// within this tab's own stack (not cross-tab).
struct FavoritesTab: View {
    @Bindable var coordinator: FavoritesCoordinator
    let container: AppContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            FavoritesListView(
                onSelect: { id in coordinator.showCharacterDetail(id: id) }
            )
            .navigationDestination(for: FavoritesCoordinator.Route.self) { route in
                switch route {
                case let .characterDetail(id):
                    CharacterDetailView(
                        viewModel: container.makeCharacterDetailViewModel(id: id)
                    )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    FavoritesTab(coordinator: FavoritesCoordinator(), container: .preview)
        .environment(AppContainer.preview.favoritesStore)
}
#endif

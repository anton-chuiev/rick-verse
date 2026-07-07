//
//  CharactersTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Characters tab. Wraps its content in a `NavigationStack`
/// bound to the flow coordinator's path, and builds the list screen's view
/// model from the app's dependency container.
struct CharactersTab: View {
    @Bindable var coordinator: CharactersCoordinator
    let container: AppContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            CharactersListView(
                viewModel: container.makeCharactersListViewModel(),
                onSelect: { id in coordinator.showCharacterDetail(id: id) }
            )
            .navigationDestination(for: CharactersCoordinator.Route.self) { route in
                switch route {
                case let .characterDetail(id):
                    CharacterDetailPlaceholderView(characterID: id)
                }
            }
        }
    }
}

#Preview {
    CharactersTab(coordinator: CharactersCoordinator(), container: .live)
}

//
//  TabBarView.swift
//  rick-verse
//

import SwiftUI

/// Root `TabView` with the app's five tabs. Each tab hosts its own flow
/// coordinator and `NavigationStack`.
struct TabBarView: View {
    @Bindable var coordinator: AppCoordinator
    let container: AppContainer

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab(AppCoordinator.Tab.characters.title,
                systemImage: AppCoordinator.Tab.characters.systemImage,
                value: .characters) {
                CharactersTab(coordinator: coordinator.characters, container: container)
            }

            Tab(AppCoordinator.Tab.episodes.title,
                systemImage: AppCoordinator.Tab.episodes.systemImage,
                value: .episodes) {
                EpisodesTab(coordinator: coordinator.episodes, container: container)
            }

            Tab(AppCoordinator.Tab.locations.title,
                systemImage: AppCoordinator.Tab.locations.systemImage,
                value: .locations) {
                LocationsTab(coordinator: coordinator.locations, container: container)
            }

            Tab(AppCoordinator.Tab.favorites.title,
                systemImage: AppCoordinator.Tab.favorites.systemImage,
                value: .favorites) {
                FavoritesTab(coordinator: coordinator.favorites, container: container)
            }

            Tab(AppCoordinator.Tab.settings.title,
                systemImage: AppCoordinator.Tab.settings.systemImage,
                value: .settings) {
                SettingsTab(coordinator: coordinator.settings)
            }
        }
    }
}

#Preview {
    TabBarView(coordinator: AppCoordinator(), container: .preview)
}

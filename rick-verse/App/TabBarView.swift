//
//  TabBarView.swift
//  rick-verse
//

import SwiftUI

/// Root `TabView` with the app's five tabs. Each tab hosts its own flow
/// coordinator and `NavigationStack`.
struct TabBarView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            CharactersTab(coordinator: coordinator.characters)
                .tabItem { tabLabel(.characters) }
                .tag(AppCoordinator.Tab.characters)

            EpisodesTab(coordinator: coordinator.episodes)
                .tabItem { tabLabel(.episodes) }
                .tag(AppCoordinator.Tab.episodes)

            LocationsTab(coordinator: coordinator.locations)
                .tabItem { tabLabel(.locations) }
                .tag(AppCoordinator.Tab.locations)

            FavoritesTab(coordinator: coordinator.favorites)
                .tabItem { tabLabel(.favorites) }
                .tag(AppCoordinator.Tab.favorites)

            SettingsTab(coordinator: coordinator.settings)
                .tabItem { tabLabel(.settings) }
                .tag(AppCoordinator.Tab.settings)
        }
    }

    private func tabLabel(_ tab: AppCoordinator.Tab) -> some View {
        Label(tab.title, systemImage: tab.systemImage)
    }
}

#Preview {
    TabBarView(coordinator: AppCoordinator())
}

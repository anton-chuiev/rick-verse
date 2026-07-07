//
//  EpisodesTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Episodes tab.
struct EpisodesTab: View {
    @Bindable var coordinator: EpisodesCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlaceholderView(title: "Episodes")
                .navigationDestination(for: EpisodesCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    EpisodesTab(coordinator: EpisodesCoordinator())
}

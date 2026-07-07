//
//  CharactersTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Characters tab. Wraps its content in a `NavigationStack`
/// bound to the flow coordinator's path. Real content arrives in a follow-up.
struct CharactersTab: View {
    @Bindable var coordinator: CharactersCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlaceholderView(title: "Characters")
                .navigationDestination(for: CharactersCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    CharactersTab(coordinator: CharactersCoordinator())
}

//
//  SettingsTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Settings tab.
struct SettingsTab: View {
    @Bindable var coordinator: SettingsCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlaceholderView(title: "Settings")
                .navigationDestination(for: SettingsCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    SettingsTab(coordinator: SettingsCoordinator())
}

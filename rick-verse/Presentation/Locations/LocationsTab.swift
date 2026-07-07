//
//  LocationsTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Locations tab.
struct LocationsTab: View {
    @Bindable var coordinator: LocationsCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlaceholderView(title: "Locations")
                .navigationDestination(for: LocationsCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    LocationsTab(coordinator: LocationsCoordinator())
}

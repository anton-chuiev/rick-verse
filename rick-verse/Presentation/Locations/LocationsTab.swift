//
//  LocationsTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Locations tab.
struct LocationsTab: View {
    @Bindable var coordinator: LocationsCoordinator
    let container: AppContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            LocationsListView(viewModel: container.makeLocationsListViewModel())
                .navigationDestination(for: LocationsCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#Preview {
    LocationsTab(coordinator: LocationsCoordinator(), container: .preview)
}

//
//  EpisodesTab.swift
//  rick-verse
//

import SwiftUI

/// Root view for the Episodes tab: hosts the flow's `NavigationStack` and the
/// Episodes list. Rows are non-tappable in this phase, so the coordinator's
/// `Route` (and this stack's destinations) stay empty.
struct EpisodesTab: View {
    @Bindable var coordinator: EpisodesCoordinator
    let container: AppContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            EpisodesListView(viewModel: container.makeEpisodesListViewModel())
                .navigationDestination(for: EpisodesCoordinator.Route.self) { _ in
                    EmptyView()
                }
        }
    }
}

#if DEBUG
#Preview {
    EpisodesTab(coordinator: EpisodesCoordinator(), container: .preview)
}
#endif

//
//  FavoritesCoordinator.swift
//  rick-verse
//

import Observation

/// Flow coordinator for the Favorites tab. Owns the tab's navigation state.
/// Tapping a favorite pushes Character Detail within *this* tab's own stack —
/// not cross-tab — so `AppCoordinator` isn't involved.
@Observable
final class FavoritesCoordinator {
    enum Route: Hashable {
        case characterDetail(id: Int)
    }

    var path: [Route] = []

    /// Pushes the Character Detail screen for the given character id.
    func showCharacterDetail(id: Int) {
        path.append(.characterDetail(id: id))
    }
}

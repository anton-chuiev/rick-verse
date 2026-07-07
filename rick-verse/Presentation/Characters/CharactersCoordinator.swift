//
//  CharactersCoordinator.swift
//  rick-verse
//

import Observation

/// Flow coordinator for the Characters tab. Owns the tab's navigation `path`
/// and `Route` enum, and decides navigation on the view models' behalf.
@Observable
final class CharactersCoordinator {
    enum Route: Hashable {
        case characterDetail(id: Int)
    }

    var path: [Route] = []

    /// Pushes the Character Detail screen for the given character id.
    func showCharacterDetail(id: Int) {
        path.append(.characterDetail(id: id))
    }
}

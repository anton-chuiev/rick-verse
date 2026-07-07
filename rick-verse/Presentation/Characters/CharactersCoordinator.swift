//
//  CharactersCoordinator.swift
//  rick-verse
//

import Observation

/// Flow coordinator for the Characters tab.
///
/// Owns the tab's navigation `path` and `Route` enum. Screen content will be
/// added as follow-up features; for now the enum is empty.
@Observable
final class CharactersCoordinator {
    enum Route: Hashable {}

    var path: [Route] = []
}

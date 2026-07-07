//
//  AppCoordinator.swift
//  rick-verse
//

import Observation

/// Root coordinator. Stays thin: owns splash → tabs routing, the selected tab,
/// and the five child flow coordinators. Cross-tab navigation will be added
/// here later — it is the only place it is allowed.
@Observable
final class AppCoordinator {
    /// Top-level app phase driving what the root view shows.
    enum Phase {
        case splash
        case tabs
    }

    /// The five root tabs of the app shell.
    enum Tab: Hashable, CaseIterable {
        case characters
        case episodes
        case locations
        case favorites
        case settings
    }

    var phase: Phase = .splash
    var selectedTab: Tab = .characters

    let characters = CharactersCoordinator()
    let episodes = EpisodesCoordinator()
    let locations = LocationsCoordinator()
    let favorites = FavoritesCoordinator()
    let settings = SettingsCoordinator()

    /// Leaves the splash screen and shows the tab bar. Called once the splash
    /// has finished (currently just a short delay; warm-up logic comes later).
    func finishSplash() {
        phase = .tabs
    }
}

extension AppCoordinator.Tab {
    /// Title shown in the tab bar. Single source of truth for tab labels.
    var title: String {
        switch self {
        case .characters: "Characters"
        case .episodes: "Episodes"
        case .locations: "Locations"
        case .favorites: "Favorites"
        case .settings: "Settings"
        }
    }

    /// SF Symbol shown in the tab bar. Single source of truth for tab icons.
    var systemImage: String {
        switch self {
        case .characters: "person.3"
        case .episodes: "tv"
        case .locations: "globe"
        case .favorites: "star"
        case .settings: "gearshape"
        }
    }
}

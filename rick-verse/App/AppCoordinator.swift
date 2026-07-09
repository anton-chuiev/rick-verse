//
//  AppCoordinator.swift
//  rick-verse
//

import Foundation
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

    /// How long the splash stays up before routing to the tabs. No warm-up
    /// work happens yet — this is a placeholder duration.
    private let splashDuration: Duration = .seconds(1.5)

    /// A deep link that arrived before the tabs were ready. Applied once the
    /// splash finishes so navigation isn't set on a screen that isn't shown yet.
    private var pendingDeepLink: DeepLink?

    /// Runs the splash phase, then routes to the tabs. Currently just a delay;
    /// data/config warm-up will be added here as a separate feature.
    func runSplash() async {
        do {
            try await Task.sleep(for: splashDuration)
        } catch {
            // Cancelled (e.g. the splash view went away) — don't route.
            return
        }
        phase = .tabs

        // Apply any link that arrived during the splash, now that the tabs
        // exist to navigate.
        if let link = pendingDeepLink {
            pendingDeepLink = nil
            apply(link)
        }
    }

    // MARK: - Deep links

    /// Entry point for an incoming deep link. This is the only place cross-flow
    /// navigation is decided (like cross-tab navigation), so links funnel here.
    /// During the splash the link is buffered and replayed once the tabs appear.
    func handle(_ link: DeepLink) {
        guard phase == .tabs else {
            pendingDeepLink = link
            return
        }
        apply(link)
    }

    /// Translates a deep-link intent into concrete navigation state: selects the
    /// owning tab and sets that flow coordinator's stack. SwiftUI renders the
    /// stack from the assigned value — no imperative screen-by-screen pushing.
    private func apply(_ link: DeepLink) {
        switch link {
        case .charactersList:
            selectedTab = .characters
            characters.path = []
        case let .characterDetail(id):
            selectedTab = .characters
            characters.path = [.characterDetail(id: id)]
        }
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

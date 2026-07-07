# Tab Bar (App Shell) Spec

## Overview

This is the app skeleton feature: root `TabView` with 5 tabs, `AppCoordinator`, and a minimal splash screen. Each tab shows a placeholder — real tab content (Characters, Episodes, etc.) will come as separate follow-up features. Follow the Module Structure, Coordinator Convention, and UI/UX sections of the project overview.

## Requirements

- Minimal splash screen (app name / logo placeholder, no warm-up logic yet) shown on launch, then routes to the tab bar via `AppCoordinator`
- `AppCoordinator` (`@Observable`): splash → tabs routing, tab selection state, owns the five child coordinators
- Root `TabView` with 5 tabs: Characters, Episodes, Locations, Favorites, Settings (SF Symbols for icons)
- One flow coordinator per tab (`CharactersCoordinator`, `EpisodesCoordinator`, `LocationsCoordinator`, `FavoritesCoordinator`, `SettingsCoordinator`), each an `@Observable` owning `path: [Route]` with an empty `Route` enum for now
- Each tab wraps its content in a `NavigationStack` bound to its coordinator's path
- Placeholder view inside each tab: just the tab name as a title for now
- Folder structure per the Module Structure section: `App/` for `rick_verseApp` + `AppCoordinator`, `Presentation/<Feature>/` for each flow coordinator and placeholder view
- Light and dark mode supported (system default, no theme switcher yet)

## Out of Scope

- Splash warm-up logic (data/config preload) — separate feature
- Any real screen content, networking, or SwiftData
- Cross-tab navigation

## References

- @context/project-overview.md (Module Structure, Coordinator Convention, UI/UX)
- @context/coding-standards.md
- @context/screenshots/characters-ui-light.png
- @context/screenshots/characters-ui-dark.png

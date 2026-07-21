//
//  AppShellView.swift
//  rick-verse
//

import SwiftData
import SwiftUI

/// Root view of the app. Shows the splash screen, then transitions to the tab
/// bar once `AppCoordinator` reports the splash is finished.
struct AppShellView: View {
    @State private var coordinator = AppCoordinator()
    let container: AppContainer

    /// The app root passes `.live`; previews pass `.preview` to stay networkless.
    /// No default argument: `.live` is a main-actor-isolated static, so it's
    /// referenced explicitly from a main-actor call site instead.
    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            switch coordinator.phase {
            case .splash:
                SplashView()
                    .task { await coordinator.runSplash() }
            case .tabs:
                TabBarView(coordinator: coordinator, container: container)
            }
        }
        // The favorites SwiftData container and the shared store are installed
        // app-wide so every tab observes the same favorites state.
        .modelContainer(container.modelContainer)
        .environment(container.favoritesStore)
        // Warm the favorite-id set so hearts render correctly on first appearance
        // of the Characters screens, before the Favorites tab is ever opened.
        .task { await container.favoritesStore.load() }
        .animation(.default, value: coordinator.phase)
        // Deep-link entry point. Parses the incoming URL and hands the intent
        // to the coordinator, which decides tab + navigation state (or buffers
        // it until the splash finishes).
        .onOpenURL { url in
            if let link = DeepLink(url: url) {
                coordinator.handle(link)
            }
        }
    }
}

extension AppCoordinator.Phase: Equatable {}

#Preview {
    AppShellView(container: .preview)
}

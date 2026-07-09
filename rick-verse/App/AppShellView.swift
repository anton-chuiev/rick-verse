//
//  AppShellView.swift
//  rick-verse
//

import SwiftUI

/// Root view of the app. Shows the splash screen, then transitions to the tab
/// bar once `AppCoordinator` reports the splash is finished.
struct AppShellView: View {
    @State private var coordinator = AppCoordinator()
    let container: AppContainer

    /// Defaults to the live container for the running app; previews pass
    /// `.preview` to stay networkless.
    init(container: AppContainer = .live) {
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

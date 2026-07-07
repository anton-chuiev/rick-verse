//
//  AppShellView.swift
//  rick-verse
//

import SwiftUI

/// Root view of the app. Shows the splash screen, then transitions to the tab
/// bar once `AppCoordinator` reports the splash is finished.
struct AppShellView: View {
    @State private var coordinator = AppCoordinator()

    /// How long the splash stays up before routing to the tabs. No warm-up
    /// work happens yet — this is a placeholder duration.
    private static let splashDuration: Duration = .seconds(1.5)

    var body: some View {
        Group {
            switch coordinator.phase {
            case .splash:
                SplashView()
                    .task {
                        try? await Task.sleep(for: Self.splashDuration)
                        coordinator.finishSplash()
                    }
            case .tabs:
                TabBarView(coordinator: coordinator)
            }
        }
        .animation(.default, value: coordinator.phase)
    }
}

extension AppCoordinator.Phase: Equatable {}

#Preview {
    AppShellView()
}

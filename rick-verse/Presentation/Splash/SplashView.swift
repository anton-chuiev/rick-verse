//
//  SplashView.swift
//  rick-verse
//

import SwiftUI

/// Minimal launch screen: app name / logo placeholder. No warm-up logic yet —
/// that arrives as a separate feature. `AppCoordinator` decides when to route
/// away from it.
struct SplashView: View {
    var body: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "atom")
                .font(.system(size: 72))
                .foregroundStyle(AppColor.accent)
                .symbolRenderingMode(.hierarchical)

            Text("RickVerse")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

#Preview {
    SplashView()
}

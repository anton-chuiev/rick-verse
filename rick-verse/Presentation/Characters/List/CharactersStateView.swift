//
//  CharactersStateView.swift
//  rick-verse
//

import SwiftUI

/// Centered empty / error state for the Characters list. When `retry` is
/// provided, shows a Retry button that runs it.
struct CharactersStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let retry: (() async -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(AppColor.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            if let retry {
                Button("Retry") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.statusAlive)
                .padding(.top, AppSpacing.s)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CharactersStateView(
        systemImage: "wifi.slash",
        title: "Something went wrong",
        message: "We couldn't load characters.",
        retry: {}
    )
}

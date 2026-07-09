//
//  CharacterFiltersPlaceholderView.swift
//  rick-verse
//

import SwiftUI

/// Placeholder contents for the filters sheet. Exists to demonstrate modal
/// (present) navigation alongside the push stack — the real filters UI is a
/// separate follow-up feature. Presented at half height via
/// `.presentationDetents` where the sheet is attached.
struct CharacterFiltersPlaceholderView: View {
    /// Dismisses the sheet. The coordinator owns the presentation state.
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.largeTitle)
                .foregroundStyle(AppColor.textSecondary)
            Text("Filters")
                .font(.title2)
                .foregroundStyle(AppColor.textPrimary)
            Text("Filters UI coming soon")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)

            Button("Done", action: onClose)
                .buttonStyle(.borderedProminent)
                .tint(AppColor.statusAlive)
                .padding(.top, AppSpacing.s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        CharacterFiltersPlaceholderView(onClose: {})
            .presentationDetents([.medium, .large])
    }
}

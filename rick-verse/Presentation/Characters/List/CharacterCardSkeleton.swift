//
//  CharacterCardSkeleton.swift
//  rick-verse
//

import SwiftUI

/// Shimmering placeholder shown for the first-page load, shaped like a
/// `CharacterCardView` so the transition to real content is calm.
struct CharacterCardSkeleton: View {
    var body: some View {
        HStack(spacing: AppSpacing.m) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).frame(width: 140, height: 16)
                RoundedRectangle(cornerRadius: 4).frame(width: 100, height: 12)
                RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.m)
        .foregroundStyle(AppColor.textSecondary.opacity(0.25))
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        CharacterCardSkeleton()
        CharacterCardSkeleton()
    }
    .padding()
}

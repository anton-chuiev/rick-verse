//
//  EpisodeListRowSkeleton.swift
//  rick-verse
//

import SwiftUI

/// Shimmering placeholder shown while the episode list loads, shaped like an
/// `EpisodeRowView` so the transition to real content is calm. Named distinctly
/// from Character Detail's `EpisodeRowSkeleton`, which is a different shape.
struct EpisodeListRowSkeleton: View {
    var body: some View {
        HStack(spacing: AppSpacing.m) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .frame(width: 52, height: 28)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4).frame(width: 90, height: 11)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.m)
        .foregroundStyle(AppColor.textSecondary.opacity(0.25))
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

#Preview {
    VStack(spacing: AppSpacing.s) {
        EpisodeListRowSkeleton()
        EpisodeListRowSkeleton()
    }
    .padding()
}

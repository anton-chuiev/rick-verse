//
//  LocationRowSkeleton.swift
//  rick-verse
//

import SwiftUI

/// Shimmering placeholder shown while the location list loads, shaped like a
/// `LocationRowView` so the transition to real content is calm.
struct LocationRowSkeleton: View {
    var body: some View {
        HStack(spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).frame(width: 150, height: 14)
                RoundedRectangle(cornerRadius: 4).frame(width: 110, height: 11)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 4).frame(width: 32, height: 12)
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
    VStack(spacing: AppSpacing.m) {
        LocationRowSkeleton()
        LocationRowSkeleton()
    }
    .padding()
}

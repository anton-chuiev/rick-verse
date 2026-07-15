//
//  CharacterDetailSkeleton.swift
//  rick-verse
//

import SwiftUI

/// Full-screen skeleton shown while the character loads: a placeholder hero
/// block with an overlaid title bar and a redacted About card, shaped like the
/// real content so the transition is calm.
struct CharacterDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                hero
                VStack(alignment: .leading, spacing: AppSpacing.s) {
                    RoundedRectangle(cornerRadius: 4).frame(width: 60, height: 12)
                    aboutCard
                }
                .padding(.horizontal, AppSpacing.m)
            }
        }
        .foregroundStyle(AppColor.textSecondary.opacity(0.25))
        .ignoresSafeArea(edges: .top)
        .redacted(reason: .placeholder)
        .shimmer()
    }

    private var hero: some View {
        Rectangle()
            .fill(AppColor.textSecondary.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).frame(width: 200, height: 30)
                    RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 14)
                }
                .padding(AppSpacing.m)
            }
    }

    private var aboutCard: some View {
        VStack(spacing: AppSpacing.m) {
            ForEach(0..<5, id: \.self) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 4).frame(width: 80, height: 12)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4).frame(width: 100, height: 12)
                }
            }
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    CharacterDetailSkeleton()
}

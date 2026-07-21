//
//  EpisodeRowView.swift
//  rick-verse
//

import SwiftUI

/// One episode row in the Episodes list: a code badge, the episode name, and its
/// air date. Non-interactive in this phase — Episode Detail is a later feature.
struct EpisodeRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Text(episode.episodeCode)
                .font(.caption.weight(.bold).monospaced())
                .foregroundStyle(AppColor.statusAlive)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, 6)
                .background(AppColor.statusAlive.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(episode.airDate)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: AppSpacing.m) {
        EpisodeRowView(episode: PreviewEpisodeBatchRepository.sample[0])
        EpisodeRowView(episode: PreviewEpisodeBatchRepository.sample[1])
    }
    .padding()
    .background(AppColor.background)
}
#endif

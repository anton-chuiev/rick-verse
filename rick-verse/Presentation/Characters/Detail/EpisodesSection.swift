//
//  EpisodesSection.swift
//  rick-verse
//

import SwiftUI

/// Container for the Episodes section: an uppercase header ("EPISODES · N") over
/// a card that holds whatever rows the caller supplies (real rows, skeletons, an
/// empty message, or an inline error).
struct EpisodesSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            VStack(spacing: 0) {
                content
            }
            .padding(AppSpacing.m)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

/// One episode row: a monospaced code badge, the episode name, and its air date.
/// Not tappable in this phase — Episode Detail is a separate feature.
struct EpisodeRow: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Text(episode.episodeCode)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(AppColor.statusAlive)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, 4)
                .background(AppColor.statusAlive.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColor.textPrimary)
                Text(episode.airDate)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.s)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(episode.episodeCode), \(episode.name), \(episode.airDate)")
    }
}

/// Shimmering placeholder shaped like an `EpisodeRow`, shown while the batch
/// request runs.
struct EpisodeRowSkeleton: View {
    var body: some View {
        HStack(spacing: AppSpacing.m) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .frame(width: 52, height: 22)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).frame(width: 140, height: 13)
                RoundedRectangle(cornerRadius: 4).frame(width: 90, height: 11)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(AppColor.textSecondary.opacity(0.25))
        .padding(.vertical, AppSpacing.s)
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

#Preview {
    EpisodesSection(title: "EPISODES · 2") {
        EpisodeRow(episode: PreviewEpisodeRepository.sample[0])
        Divider()
        EpisodeRow(episode: PreviewEpisodeRepository.sample[1])
        Divider()
        EpisodeRowSkeleton()
    }
    .padding()
    .background(AppColor.background)
}

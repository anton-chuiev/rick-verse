//
//  CharacterCardView.swift
//  rick-verse
//

import Kingfisher
import SwiftUI

/// One character row: rounded image, name, status + species, location, and a
/// static (non-interactive) outline heart plus chevron. Real favorites arrive
/// with the Favorites feature.
struct CharacterCardView: View {
    let character: RMCharacter

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                Text(character.name)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                statusLine

                locationLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                // Static, display-only heart in this phase; real favorites
                // arrive later. Chevron just hints at the push. Both are
                // decorative — the enclosing button conveys the action.
                Image(systemName: "heart")
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary.opacity(0.6))
                Spacer()
            }
            .accessibilityHidden(true)
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(character.name), \(character.status.title), \(character.species), \(character.locationName)"
        )
    }

    /// Character thumbnail. A fixed-size placeholder holds the layout (and shows
    /// during load), while `.fade` avoids a hard pop-in. Loads are deliberately
    /// *not* retried here: the Rick and Morty API rate-limits (HTTP 429) under a
    /// fast scroll, and a per-image retry would keep hammering it, sustaining the
    /// throttle for every other card too. Instead concurrency is capped hard in
    /// `KingfisherConfig` so the burst stays under the limit; a card that still
    /// misses fills in from cache the next time it scrolls back on screen.
    private var avatar: some View {
        KFImage(character.imageURL)
            .placeholder {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColor.textSecondary.opacity(0.15))
            }
            .fade(duration: 0.2)
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusLine: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(character.status.tint)
                .frame(width: 8, height: 8)
            Text(character.status.title)
                .foregroundStyle(character.status.tint)
            Text("·")
                .foregroundStyle(AppColor.textSecondary)
            Text(character.species)
                .foregroundStyle(AppColor.textSecondary)
        }
        .font(.subheadline)
    }

    private var locationLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
            Text(character.locationName)
        }
        .font(.subheadline)
        .foregroundStyle(AppColor.textSecondary)
    }
}

extension RMCharacter.Status {
    /// Display label for the status.
    var title: String {
        switch self {
        case .alive: "Alive"
        case .dead: "Dead"
        case .unknown: "Unknown"
        }
    }

    /// Color used for the status dot and text.
    var tint: Color {
        switch self {
        case .alive: AppColor.statusAlive
        case .dead: AppColor.statusDead
        case .unknown: AppColor.statusUnknown
        }
    }
}

#Preview {
    CharacterCardView(
        character: RMCharacter(
            id: 1,
            name: "Rick Sanchez",
            status: .alive,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"),
            episodeIDs: [1, 2, 3],
            locationName: "Citadel of Ricks",
            gender: "Male",
            type: "",
            originName: "Earth (C-137)"
        )
    )
    .padding()
}

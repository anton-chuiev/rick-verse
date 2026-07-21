//
//  FavoriteRowView.swift
//  rick-verse
//

import Kingfisher
import SwiftUI

/// One favorite row: rounded image, name, and status. Trimmed relative to
/// `CharacterCardView` — the snapshot has no location or episode data, so no
/// location line. Purely presentational: the row is tappable (opens Character
/// Detail) and removal is handled by the list's swipe-to-delete.
struct FavoriteRowView: View {
    let favorite: FavoriteCharacterSnapshot

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.name)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                statusLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(favorite.name), \(favorite.status.title)")
    }

    private var avatar: some View {
        KFImage(favorite.imageURL)
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
                .fill(favorite.status.tint)
                .frame(width: 8, height: 8)
            Text(favorite.status.title)
                .foregroundStyle(favorite.status.tint)
        }
        .font(.subheadline)
    }
}

#Preview {
    FavoriteRowView(
        favorite: FavoriteCharacterSnapshot(
            id: 1,
            name: "Rick Sanchez",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"),
            status: .alive,
            dateAdded: .now
        )
    )
    .padding()
}

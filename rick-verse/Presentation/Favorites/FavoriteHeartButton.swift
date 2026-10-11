//
//  FavoriteHeartButton.swift
//  rick-verse
//

import SwiftUI

/// The favorite toggle shown on character cards and Character Detail. Filled +
/// red when favorited. It reads the shared `FavoritesStore` in its own `body`,
/// so a toggle re-evaluates only this heart — not the card or screen around it
/// (Observation tracks dependencies per `body`).
struct FavoriteHeartButton: View {
    let character: RMCharacter
    /// Heart tint when not favorited; varies by the surface the heart sits on.
    let offColor: Color
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let isFavorite = favorites.isFavorite(id: character.id)
        Button(action: toggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? AppColor.statusDead : offColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isFavorite ? "Unfavorite \(character.name)" : "Favorite \(character.name)")
    }

    private func toggle() {
        Task { await favorites.toggle(character) }
    }
}

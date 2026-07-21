//
//  FavoriteCharacterSnapshot.swift
//  rick-verse
//

import Foundation

/// A stored favorite, as the app displays it — a lightweight snapshot of a
/// character captured when it was favorited. Pure domain value type: the
/// SwiftData `@Model` (`FavoriteCharacter`) never leaves the Data layer, so the
/// Presentation layer works with this instead and doesn't import SwiftData.
///
/// It carries only what the Favorites screen renders offline (id, name, image,
/// status) — not `episodeIDs` / `gender` / `origin` — so it can't be rebuilt
/// into a full `RMCharacter`. Tapping a favorite opens Character Detail by `id`,
/// which re-fetches the full character.
struct FavoriteCharacterSnapshot: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let imageURL: URL?
    let status: RMCharacter.Status
    let dateAdded: Date
}

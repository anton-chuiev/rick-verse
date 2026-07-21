//
//  FavoriteCharacter.swift
//  rick-verse
//

import Foundation
import SwiftData

/// SwiftData persistence model for a favorited character. Stays inside the Data
/// layer — the rest of the app works with the domain `FavoriteCharacterSnapshot`
/// (see `FavoriteCharacter+Mapping`). Stores a snapshot (id, name, image URL,
/// status) so the Favorites list renders fully offline.
@Model
final class FavoriteCharacter {
    /// The Rick and Morty character id. Unique so favoriting the same character
    /// twice upserts rather than inserting a duplicate.
    @Attribute(.unique) var id: Int
    var name: String
    /// Image URL stored as a `String` (SwiftData persists `String` cleanly); the
    /// mapping converts to `URL?` on the way out. Empty when the character had no
    /// image.
    var imageURLString: String
    /// Raw API status string (`"Alive"` / `"Dead"` / `"unknown"`), mapped back to
    /// `RMCharacter.Status` case-insensitively when read.
    var status: String
    /// When the favorite was added; drives newest-first ordering.
    var dateAdded: Date

    init(id: Int, name: String, imageURLString: String, status: String, dateAdded: Date = .now) {
        self.id = id
        self.name = name
        self.imageURLString = imageURLString
        self.status = status
        self.dateAdded = dateAdded
    }
}

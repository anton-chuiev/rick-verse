//
//  FavoriteCharacter+Mapping.swift
//  rick-verse
//

import Foundation

/// Maps between the SwiftData `@Model` and the domain snapshot, and builds a
/// snapshot from a full `RMCharacter` (the add path). Mirrors the `…DTO+Mapping`
/// pattern used on the network side, keeping the `@Model` confined to the Data
/// layer.
extension FavoriteCharacter {
    /// The stored favorite as a domain value. An empty/invalid image string maps
    /// to `nil`; the raw status string maps case-insensitively to `Status`.
    func toDomain() -> FavoriteCharacterSnapshot {
        FavoriteCharacterSnapshot(
            id: id,
            name: name,
            imageURL: URL(string: imageURLString),
            status: RMCharacter.Status(apiValue: status),
            dateAdded: dateAdded
        )
    }
}

extension FavoriteCharacterSnapshot {
    /// Builds a snapshot from a full character on screen — the toggle's add path.
    /// No fetch needed: everything comes from the in-memory `RMCharacter`.
    init(character: RMCharacter) {
        self.init(
            id: character.id,
            name: character.name,
            imageURL: character.imageURL,
            status: character.status,
            dateAdded: .now
        )
    }
}

extension RMCharacter.Status {
    /// The string persisted for this status. `Status(apiValue:)` reads it back
    /// case-insensitively, so this only needs to round-trip through that init.
    /// Kept in the persistence layer so it doesn't couple to the network
    /// endpoint's query-param mapping.
    var storedValue: String {
        switch self {
        case .alive: "Alive"
        case .dead: "Dead"
        case .unknown: "unknown"
        }
    }
}

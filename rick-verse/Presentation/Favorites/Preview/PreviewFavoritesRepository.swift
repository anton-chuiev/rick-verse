//
//  PreviewFavoritesRepository.swift
//  rick-verse
//

import Foundation

#if DEBUG
/// In-memory `FavoritesRepository` for SwiftUI previews. Networkless and
/// diskless — seeded with a couple of favorites so preview screens have content.
/// `@MainActor` to mirror the live repository's isolation.
@MainActor
final class PreviewFavoritesRepository: FavoritesRepository {
    private var stored: [FavoriteCharacterSnapshot]

    init(seed: [FavoriteCharacterSnapshot] = PreviewFavoritesRepository.sample) {
        self.stored = seed
    }

    func favorites() async throws -> [FavoriteCharacterSnapshot] {
        stored.sorted { $0.dateAdded > $1.dateAdded }
    }

    func favoriteIDs() async throws -> Set<Int> {
        Set(stored.map(\.id))
    }

    func add(_ character: FavoriteCharacterSnapshot) async throws {
        stored.removeAll { $0.id == character.id }
        stored.append(character)
    }

    func remove(id: Int) async throws {
        stored.removeAll { $0.id == id }
    }

    nonisolated static let sample: [FavoriteCharacterSnapshot] = [
        FavoriteCharacterSnapshot(
            id: 1,
            name: "Rick Sanchez",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"),
            status: .alive,
            dateAdded: Date(timeIntervalSince1970: 2)
        ),
        FavoriteCharacterSnapshot(
            id: 2,
            name: "Morty Smith",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/2.jpeg"),
            status: .alive,
            dateAdded: Date(timeIntervalSince1970: 1)
        )
    ]
}
#endif

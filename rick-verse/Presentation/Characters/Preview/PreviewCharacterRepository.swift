//
//  PreviewCharacterRepository.swift
//  rick-verse
//

#if DEBUG
import Foundation

/// `CharacterRepository` for SwiftUI previews: serves a fixed set of domain
/// characters with no network access, applying the query's status/name filters
/// so filter-chip and search previews stay live. Only the data source is
/// stubbed — the use case and view model above it run their real logic.
struct PreviewCharacterRepository: CharacterRepository {
    var characters: [RMCharacter] = PreviewCharacterRepository.sample

    func characters(matching request: CharactersRequest) async throws -> CharactersResponse {
        var filtered = characters

        if let status = request.status {
            filtered = filtered.filter { $0.status == status }
        }
        if let name = request.name, !name.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(name) }
        }

        return CharactersResponse(
            characters: filtered,
            totalCount: filtered.count,
            hasNextPage: false
        )
    }
}

extension PreviewCharacterRepository {
    /// A small mix of alive/dead characters for previewing the list, cards,
    /// status colors, and filter chips.
    static let sample: [RMCharacter] = [
        RMCharacter(
            id: 1,
            name: "Rick Sanchez",
            status: .alive,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"),
            episodeIDs: [1, 2, 3],
            locationName: "Citadel of Ricks"
        ),
        RMCharacter(
            id: 2,
            name: "Morty Smith",
            status: .alive,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/2.jpeg"),
            episodeIDs: [1, 2],
            locationName: "Earth (Replacement Dimension)"
        ),
        RMCharacter(
            id: 8,
            name: "Adjudicator Rick",
            status: .dead,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/8.jpeg"),
            episodeIDs: [28],
            locationName: "Citadel of Ricks"
        ),
        RMCharacter(
            id: 183,
            name: "Mr. Meeseeks",
            status: .unknown,
            species: "Alien",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/244.jpeg"),
            episodeIDs: [6],
            locationName: "unknown"
        ),
    ]
}
#endif

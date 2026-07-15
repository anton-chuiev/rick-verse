//
//  PreviewCharactersRepository.swift
//  rick-verse
//

#if DEBUG
import Foundation

/// `CharactersRepository` for SwiftUI previews: serves a fixed set of domain
/// characters with no network access, applying the query's status/name filters
/// so filter-chip and search previews stay live. Only the data source is
/// stubbed — the view model above it runs its real logic.
struct PreviewCharactersRepository: CharactersRepository {
    var characters: [RMCharacter] = PreviewCharactersRepository.sample

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

extension PreviewCharactersRepository {
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
            locationName: "Citadel of Ricks",
            gender: "Male",
            type: "",
            originName: "Earth (C-137)"
        ),
        RMCharacter(
            id: 2,
            name: "Morty Smith",
            status: .alive,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/2.jpeg"),
            episodeIDs: [1, 2],
            locationName: "Earth (Replacement Dimension)",
            gender: "Male",
            type: "",
            originName: "unknown"
        ),
        RMCharacter(
            id: 8,
            name: "Adjudicator Rick",
            status: .dead,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/8.jpeg"),
            episodeIDs: [28],
            locationName: "Citadel of Ricks",
            gender: "Male",
            type: "",
            originName: "unknown"
        ),
        RMCharacter(
            id: 183,
            name: "Mr. Meeseeks",
            status: .unknown,
            species: "Alien",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/244.jpeg"),
            episodeIDs: [6],
            locationName: "unknown",
            gender: "Male",
            type: "Alien parasite",
            originName: "unknown"
        ),
    ]
}
#endif

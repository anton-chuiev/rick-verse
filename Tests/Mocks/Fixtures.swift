//
//  Fixtures.swift
//  Tests
//

import Foundation
@testable import rick_verse

extension RMCharacter {
    /// Minimal character for tests that only care about identity (and, for the
    /// detail screen, which episodes it appears in).
    static func fixture(id: Int, name: String = "Rick Sanchez", episodeIDs: [Int] = [1]) -> RMCharacter {
        RMCharacter(
            id: id,
            name: name,
            status: .alive,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg"),
            episodeIDs: episodeIDs,
            locationName: "Citadel of Ricks",
            gender: "Male",
            type: "",
            originName: "Earth (C-137)"
        )
    }
}

extension CharactersResponse {
    /// Page carrying characters with the given IDs.
    static func fixture(
        ids: [Int],
        totalCount: Int? = nil,
        hasNextPage: Bool = false
    ) -> CharactersResponse {
        CharactersResponse(
            characters: ids.map { RMCharacter.fixture(id: $0) },
            totalCount: totalCount ?? ids.count,
            hasNextPage: hasNextPage
        )
    }
}

extension Episode {
    /// Minimal episode for tests. `code` drives season/episode grouping.
    static func fixture(id: Int, code: String, name: String = "Episode") -> Episode {
        Episode(
            id: id,
            name: name,
            airDate: "December 2, 2013",
            episodeCode: code,
            characterIDs: [1]
        )
    }
}

extension EpisodesListResponse {
    /// One page of episodes built from `(id, code)` pairs.
    static func fixture(
        _ episodes: [(id: Int, code: String)],
        totalCount: Int? = nil,
        hasNextPage: Bool = false
    ) -> EpisodesListResponse {
        EpisodesListResponse(
            episodes: episodes.map { Episode.fixture(id: $0.id, code: $0.code) },
            totalCount: totalCount ?? episodes.count,
            hasNextPage: hasNextPage
        )
    }
}

extension Location {
    /// Minimal location for tests that only care about identity.
    static func fixture(id: Int, name: String = "Earth (C-137)") -> Location {
        Location(
            id: id,
            name: name,
            type: "Planet",
            dimension: "Dimension C-137",
            residentIDs: [1]
        )
    }
}

extension LocationsResponse {
    /// Page carrying locations with the given IDs.
    static func fixture(
        ids: [Int],
        totalCount: Int? = nil,
        hasNextPage: Bool = false
    ) -> LocationsResponse {
        LocationsResponse(
            locations: ids.map { Location.fixture(id: $0) },
            totalCount: totalCount ?? ids.count,
            hasNextPage: hasNextPage
        )
    }
}

/// Stand-in for a real failure (network, decoding) in tests that only care that
/// *something* went wrong.
struct TestError: Error {}

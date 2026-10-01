//
//  CharacterMappingTests.swift
//  Tests
//

import Foundation
import Testing
@testable import rick_verse

/// Tests for `CharacterDTO` → `RMCharacter` mapping and `RMCharacter.Status`
/// parsing.
///
/// DTOs are decoded from API-shaped JSON rather than hand-constructed, so these
/// cover the coding keys alongside the mapping itself.
struct CharacterMappingTests {

    /// One character object, shaped exactly as the API returns it.
    private func characterJSON(
        status: String = "Alive",
        type: String = "",
        image: String = "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
        episodes: [String] = [
            "https://rickandmortyapi.com/api/episode/1",
            "https://rickandmortyapi.com/api/episode/2",
        ]
    ) -> String {
        let episodeList = episodes.map { "\"\($0)\"" }.joined(separator: ",")
        return """
        {
          "id": 1,
          "name": "Rick Sanchez",
          "status": "\(status)",
          "species": "Human",
          "type": "\(type)",
          "gender": "Male",
          "origin": {
            "name": "Earth (C-137)",
            "url": "https://rickandmortyapi.com/api/location/1"
          },
          "location": {
            "name": "Citadel of Ricks",
            "url": "https://rickandmortyapi.com/api/location/3"
          },
          "image": "\(image)",
          "episode": [\(episodeList)],
          "url": "https://rickandmortyapi.com/api/character/1",
          "created": "2017-11-04T18:48:46.250Z"
        }
        """
    }

    private func decode(_ json: String) throws -> CharacterDTO {
        try JSONDecoder().decode(CharacterDTO.self, from: Data(json.utf8))
    }

    // MARK: - Mapping

    @Test("Maps a full character from API JSON to the domain entity")
    func mapsFullCharacter() throws {
        let character = try decode(characterJSON()).toDomain()

        #expect(character.id == 1)
        #expect(character.name == "Morty Smith")
        #expect(character.status == .alive)
        #expect(character.species == "Human")
        #expect(character.gender == "Male")
        #expect(character.imageURL?.absoluteString == "https://rickandmortyapi.com/api/character/avatar/1.jpeg")
    }

    @Test("Lifts nested origin and location names to flat fields")
    func liftsNestedNames() throws {
        let character = try decode(characterJSON()).toDomain()

        #expect(character.originName == "Earth (C-137)")
        #expect(character.locationName == "Citadel of Ricks")
    }

    @Test("Turns episode URLs into IDs")
    func mapsEpisodeURLsToIDs() throws {
        let character = try decode(characterJSON()).toDomain()

        #expect(character.episodeIDs == [1, 2])
    }

    @Test("Drops unparseable episode URLs instead of failing")
    func dropsUnparseableEpisodeURLs() throws {
        let json = characterJSON(episodes: [
            "https://rickandmortyapi.com/api/episode/1",
            "https://rickandmortyapi.com/api/episode/bogus",
            "https://rickandmortyapi.com/api/episode/3",
        ])

        let character = try decode(json).toDomain()

        #expect(character.episodeIDs == [1, 3], "A bad entry must be dropped, not fatal")
    }

    @Test("An empty type maps through untouched")
    func emptyTypeMapsThrough() throws {
        // Rendering "" as "—" is the view's job, not the mapper's.
        let character = try decode(characterJSON(type: "")).toDomain()

        #expect(character.type == "")
    }

    @Test("A malformed image URL yields nil")
    func malformedImageURLIsNil() throws {
        let character = try decode(characterJSON(image: "")).toDomain()

        #expect(character.imageURL == nil)
    }

    // MARK: - Status parsing

    @Test("Status parsing is case-insensitive")
    func statusIsCaseInsensitive() throws {
        #expect(try decode(characterJSON(status: "Alive")).toDomain().status == .alive)
        #expect(try decode(characterJSON(status: "alive")).toDomain().status == .alive)
        #expect(try decode(characterJSON(status: "ALIVE")).toDomain().status == .alive)
        #expect(try decode(characterJSON(status: "Dead")).toDomain().status == .dead)
        #expect(try decode(characterJSON(status: "dead")).toDomain().status == .dead)
    }

    @Test("An unrecognized status falls back to unknown")
    func unrecognizedStatusFallsBackToUnknown() throws {
        #expect(try decode(characterJSON(status: "unknown")).toDomain().status == .unknown)
        #expect(try decode(characterJSON(status: "Schrodinger")).toDomain().status == .unknown)
        #expect(try decode(characterJSON(status: "")).toDomain().status == .unknown)
    }
}

//
//  DefaultCharacterDetailRepositoryTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `DefaultCharacterDetailRepository` — fetching one character by ID.
/// Its contract differs from the list repository: a 404 is a real error ("no
/// such character"), not an empty result. Driven through `StubAPIClient` with
/// real wire JSON.
///
/// `@MainActor` to match `StubAPIClient`, whose isolation is what makes it
/// `Sendable`.
@MainActor
struct DefaultCharacterDetailRepositoryTests {

    /// A `GET /character/{id}` response, shaped as the API returns it.
    private let characterJSON = """
    {
      "id": 2,
      "name": "Morty Smith",
      "status": "Alive",
      "species": "Human",
      "type": "",
      "gender": "Male",
      "origin": { "name": "unknown", "url": "" },
      "location": {
        "name": "Citadel of Ricks",
        "url": "https://rickandmortyapi.com/api/location/3"
      },
      "image": "https://rickandmortyapi.com/api/character/avatar/2.jpeg",
      "episode": [
        "https://rickandmortyapi.com/api/episode/1",
        "https://rickandmortyapi.com/api/episode/2"
      ],
      "url": "https://rickandmortyapi.com/api/character/2",
      "created": "2017-11-04T18:50:21.651Z"
    }
    """

    @Test("Fetches the character by ID and maps it to the domain")
    func fetchesAndMapsCharacter() async throws {
        let client = StubAPIClient(json: characterJSON)
        let repository = DefaultCharacterDetailRepository(apiClient: client)

        let response = try await repository.character(matching: CharacterDetailRequest(id: 2))

        #expect(response.character.id == 2)
        #expect(response.character.name == "Morty Smith")
        #expect(response.character.episodeIDs == [1, 2])

        let endpoint = try #require(client.receivedEndpoints.first)
        #expect(endpoint.path == "character/2")
        #expect(endpoint.queryParameters == nil)
    }

    @Test("Errors propagate, including 404 (unlike the list)", arguments: [
        APIError.notFound,
        APIError.httpStatus(500),
        APIError.transport,
        APIError.decoding,
    ])
    func errorsPropagate(error: APIError) async {
        let client = StubAPIClient(error: error)
        let repository = DefaultCharacterDetailRepository(apiClient: client)

        await #expect(throws: error) {
            try await repository.character(matching: CharacterDetailRequest(id: 2))
        }
    }
}

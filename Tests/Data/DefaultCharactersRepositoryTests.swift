//
//  DefaultCharactersRepositoryTests.swift
//  Tests
//

import Foundation
import Testing
@testable import rick_verse

/// Tests for `DefaultCharactersRepository` — mapping a page response to the
/// domain, and the API quirk it absorbs: a 404 means "no results match the
/// filter", not an error.
///
/// `@MainActor` to match `StubAPIClient`, whose isolation is what makes it
/// `Sendable`.
@MainActor
struct DefaultCharactersRepositoryTests {

    /// A paginated `GET /character` response, shaped as the API returns it.
    private func pageJSON(count: Int = 2, next: String?) -> String {
        let nextValue = next.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "info": {
            "count": \(count),
            "pages": 42,
            "next": \(nextValue),
            "prev": null
          },
          "results": [
            {
              "id": 1,
              "name": "Rick Sanchez",
              "status": "Alive",
              "species": "Human",
              "type": "",
              "gender": "Male",
              "origin": { "name": "Earth (C-137)", "url": "https://rickandmortyapi.com/api/location/1" },
              "location": { "name": "Citadel of Ricks", "url": "https://rickandmortyapi.com/api/location/3" },
              "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
              "episode": ["https://rickandmortyapi.com/api/episode/1"],
              "url": "https://rickandmortyapi.com/api/character/1",
              "created": "2017-11-04T18:48:46.250Z"
            },
            {
              "id": 2,
              "name": "Morty Smith",
              "status": "Alive",
              "species": "Human",
              "type": "",
              "gender": "Male",
              "origin": { "name": "unknown", "url": "" },
              "location": { "name": "Citadel of Ricks", "url": "https://rickandmortyapi.com/api/location/3" },
              "image": "https://rickandmortyapi.com/api/character/avatar/2.jpeg",
              "episode": ["https://rickandmortyapi.com/api/episode/1"],
              "url": "https://rickandmortyapi.com/api/character/2",
              "created": "2017-11-04T18:50:21.651Z"
            }
          ]
        }
        """
    }

    // MARK: - Mapping

    @Test("Maps a page response to the domain")
    func mapsPageResponse() async throws {
        let client = StubAPIClient(json: pageJSON(count: 826, next: "https://rickandmortyapi.com/api/character?page=2"))
        let repository = DefaultCharactersRepository(apiClient: client)

        let response = try await repository.characters(matching: CharactersRequest())

        #expect(response.characters.map(\.id) == [1, 2])
        #expect(response.characters.first?.name == "Rick Sanchez")
        #expect(response.totalCount == 826, "totalCount comes from info.count, not the page size")
    }

    @Test("A next link means there is a next page")
    func nextLinkMeansHasNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: "https://rickandmortyapi.com/api/character?page=2"))
        let repository = DefaultCharactersRepository(apiClient: client)

        let response = try await repository.characters(matching: CharactersRequest())

        #expect(response.hasNextPage)
    }

    @Test("The last page reports no next page")
    func lastPageHasNoNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultCharactersRepository(apiClient: client)

        let response = try await repository.characters(matching: CharactersRequest())

        #expect(response.hasNextPage == false)
    }

    // MARK: - The 404 quirk

    @Test("A 404 becomes an empty page, not an error")
    func notFoundBecomesEmptyPage() async throws {
        // The API answers "nothing matched your filter" with a 404.
        let client = StubAPIClient(error: APIError.notFound)
        let repository = DefaultCharactersRepository(apiClient: client)

        let response = try await repository.characters(matching: CharactersRequest(name: "nobody"))

        #expect(response.characters.isEmpty)
        #expect(response.totalCount == 0)
        #expect(response.hasNextPage == false)
    }

    @Test("Other errors propagate instead of being swallowed as empty", arguments: [
        APIError.httpStatus(500),
        APIError.transport,
        APIError.decoding,
        APIError.invalidURL,
    ])
    func otherErrorsPropagate(error: APIError) async {
        // A too-broad catch here would show "no results" whenever the network
        // fails — the mirror image of the 404 behavior, and just as important.
        let client = StubAPIClient(error: error)
        let repository = DefaultCharactersRepository(apiClient: client)

        await #expect(throws: error) {
            try await repository.characters(matching: CharactersRequest())
        }
    }

    @Test("Cancellation propagates")
    func cancellationPropagates() async {
        let client = StubAPIClient(error: CancellationError())
        let repository = DefaultCharactersRepository(apiClient: client)

        await #expect(throws: CancellationError.self) {
            try await repository.characters(matching: CharactersRequest())
        }
    }

    // MARK: - Endpoint building

    @Test("Builds the character endpoint with page, name and status")
    func buildsEndpointWithAllFilters() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultCharactersRepository(apiClient: client)

        _ = try await repository.characters(
            matching: CharactersRequest(page: 3, name: "Rick", status: .alive)
        )

        let endpoint = try #require(client.receivedEndpoints.first)
        #expect(endpoint.path == "character")

        let query = try endpoint.encodedQueryParameters()
        #expect(query["page"] == "3")
        #expect(query["name"] == "Rick")
        #expect(query["status"] == "alive", "The domain status maps to the API's lowercase value")
    }

    @Test("Absent filters are omitted from the query")
    func absentFiltersAreOmitted() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultCharactersRepository(apiClient: client)

        _ = try await repository.characters(matching: CharactersRequest(page: 1, name: nil, status: nil))

        let endpoint = try #require(client.receivedEndpoints.first)
        let query = try endpoint.encodedQueryParameters()
        #expect(query["page"] == "1")
        #expect(query["name"] == nil)
        #expect(query["status"] == nil)
    }

    @Test("An empty name is dropped rather than sent blank")
    func emptyNameIsDropped() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultCharactersRepository(apiClient: client)

        _ = try await repository.characters(matching: CharactersRequest(name: ""))

        let endpoint = try #require(client.receivedEndpoints.first)
        let query = try endpoint.encodedQueryParameters()
        #expect(query["name"] == nil)
    }
}

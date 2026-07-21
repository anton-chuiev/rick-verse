//
//  DefaultEpisodesRepositoryTests.swift
//  Tests
//

import Foundation
import Testing
@testable import rick_verse

/// Tests for `DefaultEpisodesRepository` — mapping a paginated `GET /episode`
/// response to the domain and deriving the paging metadata. Driven through
/// `StubAPIClient` with real wire JSON, so `EpisodeDTO` decoding (including the
/// `air_date` / `episode` coding keys) is exercised too.
///
/// `@MainActor` to match `StubAPIClient`, whose isolation is what makes it
/// `Sendable`.
@MainActor
struct DefaultEpisodesRepositoryTests {

    /// A paginated `GET /episode` response, shaped as the API returns it.
    private func pageJSON(count: Int = 51, next: String?) -> String {
        let nextValue = next.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "info": {
            "count": \(count),
            "pages": 3,
            "next": \(nextValue),
            "prev": null
          },
          "results": [
            {
              "id": 1,
              "name": "Pilot",
              "air_date": "December 2, 2013",
              "episode": "S01E01",
              "characters": [
                "https://rickandmortyapi.com/api/character/1",
                "https://rickandmortyapi.com/api/character/2"
              ],
              "url": "https://rickandmortyapi.com/api/episode/1",
              "created": "2017-11-10T12:56:33.798Z"
            },
            {
              "id": 2,
              "name": "Lawnmower Dog",
              "air_date": "December 9, 2013",
              "episode": "S01E02",
              "characters": ["https://rickandmortyapi.com/api/character/1"],
              "url": "https://rickandmortyapi.com/api/episode/2",
              "created": "2017-11-10T12:56:33.916Z"
            }
          ]
        }
        """
    }

    // MARK: - Mapping

    @Test("Maps a page response to the domain, decoding snake_case keys")
    func mapsPageResponse() async throws {
        let client = StubAPIClient(json: pageJSON(next: "https://rickandmortyapi.com/api/episode?page=2"))
        let repository = DefaultEpisodesRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodesListRequest())

        #expect(response.episodes.map(\.id) == [1, 2])
        #expect(response.episodes.first?.name == "Pilot")
        #expect(response.episodes.first?.airDate == "December 2, 2013", "air_date maps to airDate")
        #expect(response.episodes.first?.episodeCode == "S01E01", "episode maps to episodeCode")
        #expect(response.episodes.first?.characterIDs == [1, 2], "character URLs map to trailing IDs")
        #expect(response.totalCount == 51, "totalCount comes from info.count, not the page size")
    }

    @Test("A next link means there is a next page")
    func nextLinkMeansHasNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: "https://rickandmortyapi.com/api/episode?page=2"))
        let repository = DefaultEpisodesRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodesListRequest())

        #expect(response.hasNextPage)
    }

    @Test("The last page reports no next page")
    func lastPageHasNoNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultEpisodesRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodesListRequest())

        #expect(response.hasNextPage == false)
    }

    // MARK: - Errors propagate

    @Test("Errors propagate rather than being swallowed", arguments: [
        APIError.httpStatus(500),
        APIError.transport,
        APIError.decoding,
    ])
    func errorsPropagate(error: APIError) async {
        // Unlike the characters list, the episode list applies no filters, so
        // there is no 404→empty translation — every error is a real error.
        let client = StubAPIClient(error: error)
        let repository = DefaultEpisodesRepository(apiClient: client)

        await #expect(throws: error) {
            try await repository.episodes(matching: EpisodesListRequest())
        }
    }

    // MARK: - Endpoint building

    @Test("Builds the episode list endpoint carrying the page number")
    func buildsEndpointWithPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultEpisodesRepository(apiClient: client)

        _ = try await repository.episodes(matching: EpisodesListRequest(page: 2))

        let endpoint = try #require(client.receivedEndpoints.first)
        #expect(endpoint.path == "episode")
        #expect(try endpoint.encodedQueryParameters()["page"] == "2")
    }
}

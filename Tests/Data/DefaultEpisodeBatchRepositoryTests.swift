//
//  DefaultEpisodeBatchRepositoryTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `DefaultEpisodeBatchRepository` — the two API quirks it hides from
/// callers: `GET /episode/{ids}` returns a lone object for one ID but an array
/// for several, and an empty ID list must not hit the network at all. Driven
/// through `StubAPIClient` with real wire JSON, so `EpisodeDTO` decoding is
/// exercised too.
///
/// `@MainActor` to match `StubAPIClient`, whose isolation is what makes it
/// `Sendable`.
@MainActor
struct DefaultEpisodeBatchRepositoryTests {

    /// One episode object, shaped as the API returns it.
    private func episodeJSON(id: Int, name: String, code: String) -> String {
        """
        {
          "id": \(id),
          "name": "\(name)",
          "air_date": "December 2, 2013",
          "episode": "\(code)",
          "characters": ["https://rickandmortyapi.com/api/character/1"],
          "url": "https://rickandmortyapi.com/api/episode/\(id)",
          "created": "2017-11-10T12:56:33.798Z"
        }
        """
    }

    // MARK: - Response shapes

    @Test("Several IDs: the array response maps to the domain")
    func severalIDsDecodeArray() async throws {
        let json = "[\(episodeJSON(id: 1, name: "Pilot", code: "S01E01")),"
            + "\(episodeJSON(id: 2, name: "Lawnmower Dog", code: "S01E02"))]"
        let client = StubAPIClient(json: json)
        let repository = DefaultEpisodeBatchRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodeBatchRequest(ids: [1, 2]))

        #expect(response.episodes.map(\.id) == [1, 2])
        #expect(response.episodes.map(\.episodeCode) == ["S01E01", "S01E02"])
    }

    @Test("One ID: the single-object response decodes into a one-element list")
    func singleIDDecodesLoneObject() async throws {
        let client = StubAPIClient(json: episodeJSON(id: 1, name: "Pilot", code: "S01E01"))
        let repository = DefaultEpisodeBatchRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodeBatchRequest(ids: [1]))

        #expect(response.episodes.map(\.id) == [1], "The API returns an object, not an array, for one ID")
        #expect(response.episodes.first?.name == "Pilot")
    }

    // MARK: - Empty request

    @Test("Empty IDs return an empty response without a network call")
    func emptyIDsSkipNetwork() async throws {
        // Any call would throw: the stub is scripted to fail.
        let client = StubAPIClient(error: TestError())
        let repository = DefaultEpisodeBatchRepository(apiClient: client)

        let response = try await repository.episodes(matching: EpisodeBatchRequest(ids: []))

        #expect(response.episodes.isEmpty)
        #expect(client.receivedEndpoints.isEmpty)
    }

    // MARK: - Endpoint building

    @Test("Builds one batch endpoint with comma-separated IDs")
    func buildsBatchEndpoint() async throws {
        let client = StubAPIClient(json: "[]")
        let repository = DefaultEpisodeBatchRepository(apiClient: client)

        _ = try await repository.episodes(matching: EpisodeBatchRequest(ids: [1, 2, 3]))

        let endpoint = try #require(client.receivedEndpoints.first)
        #expect(client.receivedEndpoints.count == 1, "One request for all IDs, not one per ID")
        #expect(endpoint.path == "episode/1,2,3")
        #expect(endpoint.queryParameters == nil)
    }

    // MARK: - Errors propagate

    @Test("Errors propagate rather than being swallowed", arguments: [
        APIError.notFound,
        APIError.httpStatus(500),
        APIError.transport,
        APIError.decoding,
    ])
    func errorsPropagate(error: APIError) async {
        let client = StubAPIClient(error: error)
        let repository = DefaultEpisodeBatchRepository(apiClient: client)

        await #expect(throws: error) {
            try await repository.episodes(matching: EpisodeBatchRequest(ids: [1, 2]))
        }
    }
}

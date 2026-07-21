//
//  DefaultLocationsRepositoryTests.swift
//  Tests
//

import Foundation
import Testing
@testable import rick_verse

/// Tests for `DefaultLocationsRepository` — mapping a page response to the
/// domain (including the `residents` URL → ID parse and empty `type`/`dimension`
/// passthrough), the paging metadata it derives, and the API quirk it absorbs: a
/// 404 means "no results match the filter", not an error.
///
/// `@MainActor` to match `StubAPIClient`, whose isolation is what makes it
/// `Sendable`.
@MainActor
struct DefaultLocationsRepositoryTests {

    /// A paginated `GET /location` response, shaped as the API returns it. The
    /// second location has empty `type`/`dimension` to exercise the passthrough.
    private func pageJSON(count: Int = 2, next: String?) -> String {
        let nextValue = next.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "info": {
            "count": \(count),
            "pages": 7,
            "next": \(nextValue),
            "prev": null
          },
          "results": [
            {
              "id": 1,
              "name": "Earth (C-137)",
              "type": "Planet",
              "dimension": "Dimension C-137",
              "residents": [
                "https://rickandmortyapi.com/api/character/38",
                "https://rickandmortyapi.com/api/character/45"
              ],
              "url": "https://rickandmortyapi.com/api/location/1",
              "created": "2017-11-10T12:42:04.162Z"
            },
            {
              "id": 3,
              "name": "Citadel of Ricks",
              "type": "",
              "dimension": "",
              "residents": [],
              "url": "https://rickandmortyapi.com/api/location/3",
              "created": "2017-11-10T13:08:13.191Z"
            }
          ]
        }
        """
    }

    // MARK: - Mapping

    @Test("Maps a page response to the domain")
    func mapsPageResponse() async throws {
        let client = StubAPIClient(json: pageJSON(count: 126, next: "https://rickandmortyapi.com/api/location?page=2"))
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        #expect(response.locations.map(\.id) == [1, 3])
        #expect(response.locations.first?.name == "Earth (C-137)")
        #expect(response.locations.first?.type == "Planet")
        #expect(response.locations.first?.dimension == "Dimension C-137")
        #expect(response.totalCount == 126, "totalCount comes from info.count, not the page size")
    }

    @Test("Parses resident URLs into trailing IDs")
    func parsesResidentIDs() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        #expect(response.locations.first?.residentIDs == [38, 45])
    }

    @Test("Empty type and dimension carry through as empty strings")
    func emptyTypeAndDimensionPassThrough() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        let citadel = try #require(response.locations.first { $0.id == 3 })
        #expect(citadel.type == "")
        #expect(citadel.dimension == "")
        #expect(citadel.residentIDs.isEmpty)
    }

    @Test("A next link means there is a next page")
    func nextLinkMeansHasNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: "https://rickandmortyapi.com/api/location?page=2"))
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        #expect(response.hasNextPage)
    }

    @Test("The last page reports no next page")
    func lastPageHasNoNextPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        #expect(response.hasNextPage == false)
    }

    // MARK: - The 404 quirk

    @Test("A 404 becomes an empty page, not an error")
    func notFoundBecomesEmptyPage() async throws {
        // The API answers "nothing matched your filter" with a 404. This feature
        // sends no filters, but the behavior is mirrored from the characters
        // repository so the future Search & Filter feature inherits it.
        let client = StubAPIClient(error: APIError.notFound)
        let repository = DefaultLocationsRepository(apiClient: client)

        let response = try await repository.locations(matching: LocationsRequest())

        #expect(response.locations.isEmpty)
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
        let repository = DefaultLocationsRepository(apiClient: client)

        await #expect(throws: error) {
            try await repository.locations(matching: LocationsRequest())
        }
    }

    @Test("Cancellation propagates")
    func cancellationPropagates() async {
        let client = StubAPIClient(error: CancellationError())
        let repository = DefaultLocationsRepository(apiClient: client)

        await #expect(throws: CancellationError.self) {
            try await repository.locations(matching: LocationsRequest())
        }
    }

    // MARK: - Endpoint building

    @Test("Builds the location endpoint with the page number")
    func buildsEndpointWithPage() async throws {
        let client = StubAPIClient(json: pageJSON(next: nil))
        let repository = DefaultLocationsRepository(apiClient: client)

        _ = try await repository.locations(matching: LocationsRequest(page: 3))

        let endpoint = try #require(client.receivedEndpoints.first)
        #expect(endpoint.path == "location")

        let query = try endpoint.encodedQueryParameters()
        #expect(query["page"] == "3")
    }
}

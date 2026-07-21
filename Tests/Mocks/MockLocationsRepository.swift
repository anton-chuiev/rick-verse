//
//  MockLocationsRepository.swift
//  Tests
//

@testable import rick_verse

/// `LocationsRepository` spy: hands out scripted results and records what it was
/// asked for.
///
/// Recording the requests proves page numbers reach the API correctly. The race
/// tests need a repository that can also *hold a call open* to force out-of-order
/// completion — that lives in ``SuspendingLocationsRepository`` rather than
/// complicating this one.
///
/// `@MainActor` because the view model under test is — no extra isolation hop, so
/// a test can inspect `receivedRequests` right after awaiting the view model.
@MainActor
final class MockLocationsRepository: LocationsRepository {
    /// Results handed out one per call, in order. When exhausted, calls fall back
    /// to ``defaultResult``.
    var results: [Result<LocationsResponse, Error>] = []

    /// Used once `results` runs out, so tests that don't care about later pages
    /// don't have to script every call.
    var defaultResult: Result<LocationsResponse, Error> = .success(
        LocationsResponse(locations: [], totalCount: 0, hasNextPage: false)
    )

    /// Every request received, oldest first.
    private(set) var receivedRequests: [LocationsRequest] = []

    var callCount: Int { receivedRequests.count }

    func locations(matching request: LocationsRequest) async throws -> LocationsResponse {
        receivedRequests.append(request)
        let result = results.isEmpty ? defaultResult : results.removeFirst()
        return try result.get()
    }
}

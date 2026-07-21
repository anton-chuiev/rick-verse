//
//  MockEpisodesRepository.swift
//  Tests
//

@testable import rick_verse

/// `EpisodesRepository` spy: hands out one scripted page per call, in order, and
/// records the requests so a test can prove `FetchAllEpisodesUseCase` walks the
/// pages in sequence and stops when a page reports no next page.
///
/// `@MainActor` to match the other test doubles and the view model under test.
@MainActor
final class MockEpisodesRepository: EpisodesRepository {
    /// Pages handed out one per call, in order. When exhausted, calls fall back
    /// to an empty final page.
    var results: [Result<EpisodesListResponse, Error>] = []

    /// Every request received, oldest first.
    private(set) var receivedRequests: [EpisodesListRequest] = []

    var callCount: Int { receivedRequests.count }

    func episodes(matching request: EpisodesListRequest) async throws -> EpisodesListResponse {
        receivedRequests.append(request)
        let result = results.isEmpty
            ? .success(EpisodesListResponse(episodes: [], totalCount: 0, hasNextPage: false))
            : results.removeFirst()
        return try result.get()
    }
}

//
//  MockFetchEpisodeBatchUseCase.swift
//  Tests
//

@testable import rick_verse

/// `FetchEpisodeBatchUseCase` spy for `CharacterDetailViewModel` tests: hands
/// out one scripted result per call, in order, and records the requests so a
/// test can check which episode IDs were asked for — or that none were.
///
/// `@MainActor` because the view model under test is.
@MainActor
final class MockFetchEpisodeBatchUseCase: FetchEpisodeBatchUseCase {
    /// Results handed out one per call, in order. When exhausted, calls fail
    /// with `TestError` so an unexpected extra fetch is loud, not silent.
    var results: [Result<EpisodeBatchResponse, Error>] = []

    /// Every request received, oldest first.
    private(set) var receivedRequests: [EpisodeBatchRequest] = []

    var callCount: Int { receivedRequests.count }

    func execute(_ request: EpisodeBatchRequest) async throws -> EpisodeBatchResponse {
        receivedRequests.append(request)
        let result = results.isEmpty ? .failure(TestError()) : results.removeFirst()
        return try result.get()
    }
}

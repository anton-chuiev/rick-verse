//
//  MockCharacterDetailRepository.swift
//  Tests
//

@testable import rick_verse

/// `CharacterDetailRepository` spy for `CharacterDetailViewModel` tests: hands
/// out one scripted result per call, in order, and records the requests.
///
/// `@MainActor` to match the other test doubles and the view model under test.
@MainActor
final class MockCharacterDetailRepository: CharacterDetailRepository {
    /// Results handed out one per call, in order. When exhausted, calls fail
    /// with `TestError` so an unexpected extra fetch is loud, not silent.
    var results: [Result<CharacterDetailResponse, Error>] = []

    /// Every request received, oldest first.
    private(set) var receivedRequests: [CharacterDetailRequest] = []

    var callCount: Int { receivedRequests.count }

    func character(matching request: CharacterDetailRequest) async throws -> CharacterDetailResponse {
        receivedRequests.append(request)
        let result = results.isEmpty ? .failure(TestError()) : results.removeFirst()
        return try result.get()
    }
}

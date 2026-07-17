//
//  MockCharactersRepository.swift
//  Tests
//

@testable import rick_verse

/// `CharactersRepository` spy: hands out scripted results and records what it
/// was asked for.
///
/// Recording the requests is what proves the debounce (three keystrokes must
/// produce a single request) and that filters and page numbers reach the API
/// correctly.
///
/// The two race tests need a repository that can also *hold a call open* to
/// force out-of-order completion — that lives in
/// ``SuspendingCharactersRepository`` rather than complicating this one.
///
/// `@MainActor` because the view model under test is — no extra isolation hop,
/// so a test can inspect `receivedRequests` right after awaiting the view model.
@MainActor
final class MockCharactersRepository: CharactersRepository {
    /// Results handed out one per call, in order. When exhausted, calls fall
    /// back to ``defaultResult``.
    var results: [Result<CharactersResponse, Error>] = []

    /// Used once `results` runs out, so tests that don't care about later pages
    /// don't have to script every call.
    var defaultResult: Result<CharactersResponse, Error> = .success(
        CharactersResponse(characters: [], totalCount: 0, hasNextPage: false)
    )

    /// Every request received, oldest first.
    private(set) var receivedRequests: [CharactersRequest] = []

    var callCount: Int { receivedRequests.count }

    func characters(matching request: CharactersRequest) async throws -> CharactersResponse {
        receivedRequests.append(request)
        let result = results.isEmpty ? defaultResult : results.removeFirst()
        return try result.get()
    }
}

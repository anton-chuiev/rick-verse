//
//  SuspendingCharactersRepository.swift
//  Tests
//

@testable import rick_verse

/// `CharactersRepository` whose calls hang until the test releases them.
///
/// Exists for one job: proving the view model's race guards (a superseded load
/// never applies its result). To test them, a test has to reproduce the very
/// situation they defend against — load A starts, load B supersedes it, and
/// **A's response arrives last**. A plain spy (``MockCharactersRepository``)
/// can't do that: it returns immediately, so calls always finish in the order
/// they were made and the race never happens.
///
/// So calls here suspend instead of returning, and the test decides the order
/// they complete in:
///
///     let repository = SuspendingCharactersRepository()
///     repository.results = [.success(stalepage), .success(freshPage)]
///
///     let loadA = Task { await sut.reload() }
///     while repository.pendingCount < 1 { await Task.yield() }
///     let loadB = Task { await sut.reload() }
///     while repository.pendingCount < 2 { await Task.yield() }
///
///     repository.resume(at: 1)   // B finishes first…
///     await loadB.value
///     repository.resume(at: 0)   // …then the stale A lands
///     await loadA.value
///
/// The alternative — sleeping in the mock to stagger the responses — would make
/// the tests timing-dependent and flaky. Suspending is deterministic: the test
/// waits for an observed condition (`pendingCount`), never for a duration.
///
/// `@MainActor` for the same reason as the spy: the view model under test is.
@MainActor
final class SuspendingCharactersRepository: CharactersRepository {
    /// Results handed out one per call, in order — the result is picked when the
    /// call arrives, and delivered when the test resumes it.
    var results: [Result<CharactersResponse, Error>] = []

    /// Every request received, oldest first.
    private(set) var receivedRequests: [CharactersRequest] = []

    var callCount: Int { receivedRequests.count }

    /// Continuations of the calls held open, indexed by call order. An entry is
    /// cleared once resumed — the slot stays so indices remain stable, which is
    /// what lets a test resume calls out of order by their original position.
    private var pending: [CheckedContinuation<Void, Never>?] = []

    /// Number of calls currently suspended awaiting ``resume(at:)``. Tests poll
    /// this to know a load is genuinely in flight before starting the next one.
    var pendingCount: Int { pending.count { $0 != nil } }

    func characters(matching request: CharactersRequest) async throws -> CharactersResponse {
        receivedRequests.append(request)
        let result = results.isEmpty
            ? .success(CharactersResponse(characters: [], totalCount: 0, hasNextPage: false))
            : results.removeFirst()

        await withCheckedContinuation { continuation in
            pending.append(continuation)
        }

        return try result.get()
    }

    /// Releases the held call at `index` (in call order), letting it return its
    /// scripted result. Resuming the same call twice is a no-op — a checked
    /// continuation traps if resumed more than once.
    func resume(at index: Int) {
        guard index < pending.count, let continuation = pending[index] else { return }
        pending[index] = nil
        continuation.resume()
    }
}

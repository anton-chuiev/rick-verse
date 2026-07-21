//
//  MockFetchAllEpisodesUseCase.swift
//  Tests
//

@testable import rick_verse

/// `FetchAllEpisodesUseCase` spy for `EpisodesListViewModel` tests: returns a
/// scripted result and records how many times it ran.
///
/// The race test needs a use case that can *hold a call open* to force
/// out-of-order completion — that lives in
/// ``SuspendingFetchAllEpisodesUseCase`` rather than complicating this one.
///
/// `@MainActor` because the view model under test is.
@MainActor
final class MockFetchAllEpisodesUseCase: FetchAllEpisodesUseCase {
    /// Results handed out one per call, in order. When exhausted, calls fall
    /// back to ``defaultResult``.
    var results: [Result<[Episode], Error>] = []

    /// Used once `results` runs out.
    var defaultResult: Result<[Episode], Error> = .success([])

    private(set) var callCount = 0

    func execute() async throws -> [Episode] {
        callCount += 1
        let result = results.isEmpty ? defaultResult : results.removeFirst()
        return try result.get()
    }
}

/// `FetchAllEpisodesUseCase` whose calls hang until the test releases them, so a
/// test can reproduce the race the view model's generation token defends
/// against: load A starts, load B supersedes it, and A's response arrives last.
/// Same technique as ``SuspendingCharactersRepository``.
@MainActor
final class SuspendingFetchAllEpisodesUseCase: FetchAllEpisodesUseCase {
    /// Results handed out one per call, in order — picked when the call arrives,
    /// delivered when the test resumes it.
    var results: [Result<[Episode], Error>] = []

    /// Continuations of the calls held open, indexed by call order. A slot is
    /// cleared once resumed but kept so indices stay stable, letting a test
    /// resume calls out of order by their original position.
    private var pending: [CheckedContinuation<Void, Never>?] = []

    /// Number of calls currently suspended awaiting ``resume(at:)``.
    var pendingCount: Int { pending.count { $0 != nil } }

    func execute() async throws -> [Episode] {
        let result = results.isEmpty ? .success([]) : results.removeFirst()
        await withCheckedContinuation { continuation in
            pending.append(continuation)
        }
        return try result.get()
    }

    /// Releases the held call at `index` (in call order).
    func resume(at index: Int) {
        guard index < pending.count, let continuation = pending[index] else { return }
        pending[index] = nil
        continuation.resume()
    }
}

//
//  SuspendingLocationsRepository.swift
//  Tests
//

@testable import rick_verse

/// `LocationsRepository` whose calls hang until the test releases them.
///
/// Exists for one job: proving the view model's generation-token race guard. To
/// test that guard, a test has to reproduce the very situation it defends
/// against — load A starts, load B supersedes it, and **A's response arrives
/// last**. A plain spy (``MockLocationsRepository``) can't do that: it returns
/// immediately, so calls always finish in the order they were made and the race
/// never happens.
///
/// So calls here suspend instead of returning, and the test decides the order
/// they complete in via ``resume(at:)``, polling ``pendingCount`` to know a load
/// is genuinely in flight before starting the next one. This keeps the tests
/// deterministic — they wait for an observed condition, never for a duration.
///
/// `@MainActor` for the same reason as the spy: the view model under test is.
@MainActor
final class SuspendingLocationsRepository: LocationsRepository {
    /// Results handed out one per call, in order — the result is picked when the
    /// call arrives, and delivered when the test resumes it.
    var results: [Result<LocationsResponse, Error>] = []

    /// Every request received, oldest first.
    private(set) var receivedRequests: [LocationsRequest] = []

    var callCount: Int { receivedRequests.count }

    /// Continuations of the calls held open, indexed by call order. An entry is
    /// cleared once resumed — the slot stays so indices remain stable, which is
    /// what lets a test resume calls out of order by their original position.
    private var pending: [CheckedContinuation<Void, Never>?] = []

    /// Number of calls currently suspended awaiting ``resume(at:)``. Tests poll
    /// this to know a load is genuinely in flight before starting the next one.
    var pendingCount: Int { pending.count { $0 != nil } }

    func locations(matching request: LocationsRequest) async throws -> LocationsResponse {
        receivedRequests.append(request)
        let result = results.isEmpty
            ? .success(LocationsResponse(locations: [], totalCount: 0, hasNextPage: false))
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

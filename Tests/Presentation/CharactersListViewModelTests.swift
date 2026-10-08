//
//  CharactersListViewModelTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `CharactersListViewModel` — the most subtle logic in the codebase:
/// race guarding, cancellation-vs-failure, debounced search, and pagination.
///
/// Timing is never driven by sleeping: the debounce interval is injected, and
/// out-of-order completion is forced by holding mocked calls open.
@MainActor
struct CharactersListViewModelTests {

    /// Debounce short enough that waiting it out is instant, but non-zero so the
    /// debounce path is still exercised.
    static let testDebounce: Duration = .milliseconds(1)

    /// No back-off after a failed next page, so failure tests don't wait out the
    /// production rate-limit delay.
    static let testRetryBackOff: Duration = .zero

    /// Takes any `CharactersRepository` so the race tests can pass
    /// ``SuspendingCharactersRepository`` and everything else the plain spy.
    private func makeSUT(
        repository: some CharactersRepository
    ) -> CharactersListViewModel {
        CharactersListViewModel(
            repository: repository,
            searchDebounce: Self.testDebounce,
            retryBackOff: Self.testRetryBackOff
        )
    }

    /// Waits for a debounced reload to run to completion. Yields repeatedly
    /// rather than sleeping a fixed duration, so it resolves as soon as the work
    /// lands instead of racing a hard-coded interval.
    private func waitForDebouncedReload(
        on repository: MockCharactersRepository,
        toReach expectedCalls: Int
    ) async {
        for _ in 0..<200 where repository.callCount < expectedCalls {
            try? await Task.sleep(for: .milliseconds(1))
        }
    }

    // MARK: - First-page load & state transitions

    @Test("Loads the first page on appear")
    func loadsFirstPageOnAppear() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: [1, 2], totalCount: 826, hasNextPage: true))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.characters.map(\.id) == [1, 2])
        #expect(sut.totalCount == 826)
        #expect(sut.hasNextPage)
        #expect(sut.loadState == .loaded)
    }

    @Test("Empty results land in the empty state")
    func emptyResultsShowEmptyState() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: []))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .empty)
        #expect(sut.characters.isEmpty)
    }

    @Test("A failed first page clears content and shows the error state")
    func failedFirstPageShowsError() async {
        let repository = MockCharactersRepository()
        repository.results = [.failure(TestError())]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .failed)
        #expect(sut.characters.isEmpty)
        #expect(sut.totalCount == 0)
        #expect(sut.hasNextPage == false)
    }

    @Test("Appearing again does not reload once content is loaded")
    func secondAppearDoesNotReload() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: [1]))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        await sut.onAppear()

        #expect(repository.callCount == 1)
    }

    @Test("Retry after a failure reloads and recovers")
    func retryAfterFailureRecovers() async {
        let repository = MockCharactersRepository()
        repository.results = [.failure(TestError()), .success(.fixture(ids: [1]))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        #expect(sut.loadState == .failed)

        await sut.retry()

        #expect(sut.loadState == .loaded)
        #expect(sut.characters.map(\.id) == [1])
    }

    // MARK: - Cancellation is not failure

    @Test("A cancelled first load returns to idle so re-appearing retries")
    func cancelledFirstLoadReturnsToIdle() async {
        let repository = MockCharactersRepository()
        repository.results = [.failure(CancellationError())]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .idle, "Cancellation must not surface as a failure")
    }

    @Test("A cancelled reload keeps the content already on screen")
    func cancelledReloadKeepsContent() async {
        let repository = MockCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2])),
            .failure(CancellationError()),
        ]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        await sut.reload()

        #expect(sut.loadState == .loaded)
        #expect(sut.characters.map(\.id) == [1, 2])
    }

    // MARK: - Search debounce

    @Test("Rapid typing collapses into one request carrying the last value")
    func rapidTypingCollapsesToOneRequest() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.searchText = "R"
        sut.searchText = "Ri"
        sut.searchText = "Rick"

        await waitForDebouncedReload(on: repository, toReach: 1)

        #expect(repository.callCount == 1, "Three keystrokes must debounce into a single request")
        #expect(repository.receivedRequests.last?.name == "Rick")
    }

    @Test("Setting the same search text does not reload")
    func sameSearchTextDoesNotReload() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.searchText = "Rick"
        await waitForDebouncedReload(on: repository, toReach: 1)
        sut.searchText = "Rick"
        await waitForDebouncedReload(on: repository, toReach: 2)

        #expect(repository.callCount == 1)
    }

    @Test("Search text is trimmed before it reaches the request")
    func searchTextIsTrimmed() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.searchText = "  Rick  "
        await waitForDebouncedReload(on: repository, toReach: 1)

        #expect(repository.receivedRequests.last?.name == "Rick")
    }

    @Test("A whitespace-only search sends no name filter")
    func whitespaceOnlySearchSendsNoName() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.searchText = "   "
        await waitForDebouncedReload(on: repository, toReach: 1)

        #expect(repository.receivedRequests.last?.name == nil)
    }

    // MARK: - Filter changes

    @Test("Changing the filter reloads immediately with the mapped status")
    func filterChangeReloadsWithMappedStatus() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.statusFilter = .dead
        await waitForDebouncedReload(on: repository, toReach: 1)

        #expect(repository.receivedRequests.last?.status == .dead)
    }

    @Test("The All filter sends no status")
    func allFilterSendsNoStatus() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.statusFilter = .alive
        await waitForDebouncedReload(on: repository, toReach: 1)
        sut.statusFilter = .all
        await waitForDebouncedReload(on: repository, toReach: 2)

        #expect(repository.receivedRequests.last?.status == nil)
    }

    @Test("Re-selecting the current filter does not reload")
    func sameFilterDoesNotReload() async {
        let repository = MockCharactersRepository()
        let sut = makeSUT(repository: repository)

        sut.statusFilter = .alive
        await waitForDebouncedReload(on: repository, toReach: 1)
        sut.statusFilter = .alive
        await waitForDebouncedReload(on: repository, toReach: 2)

        #expect(repository.callCount == 1)
    }

    // MARK: - Race guarding

    @Test("A superseded load is discarded even when it completes last")
    func supersededLoadIsDiscardedWhenItLandsLast() async {
        let repository = SuspendingCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2])),   // load A — stale
            .success(.fixture(ids: [9])),      // load B — current
        ]
        let sut = makeSUT(repository: repository)

        // Load A: in flight, held open by the repository.
        let loadA = Task { await sut.reload() }
        while repository.pendingCount < 1 { await Task.yield() }

        // Load B supersedes it, also held open.
        let loadB = Task { await sut.reload() }
        while repository.pendingCount < 2 { await Task.yield() }

        // Finish B first, then A — so the *stale* response lands last.
        repository.resume(at: 1)
        await loadB.value
        repository.resume(at: 0)
        await loadA.value

        #expect(sut.characters.map(\.id) == [9], "The stale response must not overwrite fresher results")
        #expect(sut.loadState == .loaded)
    }

    @Test("A stale next page is not appended after a reload")
    func staleNextPageIsNotAppended() async {
        let repository = SuspendingCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2], hasNextPage: true)),  // first page
            .success(.fixture(ids: [3, 4], hasNextPage: true)),  // stale page 2
            .success(.fixture(ids: [7])),                        // the reload
        ]
        let sut = makeSUT(repository: repository)

        // Every call suspends here, so the first page has to be released too.
        let firstPage = Task { await sut.onAppear() }
        while repository.pendingCount < 1 { await Task.yield() }
        repository.resume(at: 0)
        await firstPage.value

        // Page 2 starts and is held open.
        let nextPage = Task { await sut.loadNextPageIfNeeded() }
        while repository.pendingCount < 1 { await Task.yield() }

        // A reload supersedes it and finishes first.
        let reload = Task { await sut.reload() }
        while repository.pendingCount < 2 { await Task.yield() }
        repository.resume(at: 2)
        await reload.value

        // Now the stale page 2 lands.
        repository.resume(at: 1)
        await nextPage.value

        #expect(sut.characters.map(\.id) == [7], "A stale page must not append to the fresh list")
    }

    @Test("No next page is requested while a filter reload is in flight")
    func noNextPageDuringReload() async throws {
        let repository = SuspendingCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2], hasNextPage: true)),  // All, page 1
            .success(.fixture(ids: [3, 4], hasNextPage: true)),  // All, page 2
            .success(.fixture(ids: [7], hasNextPage: true)),     // Dead, page 1
            .success(.fixture(ids: [8])),                        // Dead, page 2
        ]
        let sut = makeSUT(repository: repository)

        // Scroll All down to page 2.
        let firstPage = Task { await sut.onAppear() }
        while repository.pendingCount < 1 { await Task.yield() }
        repository.resume(at: 0)
        await firstPage.value
        let secondPage = Task { await sut.loadNextPageIfNeeded() }
        while repository.pendingCount < 1 { await Task.yield() }
        repository.resume(at: 1)
        await secondPage.value

        // Switching to Dead starts a reload, held open.
        sut.statusFilter = .dead
        while repository.pendingCount < 1 { await Task.yield() }

        // The footer sentinel fires mid-reload. Without the guard this would
        // request "Dead, page 3" — the old page number with the new filter.
        let finished = Flag()
        let midReload = Task {
            await sut.loadNextPageIfNeeded()
            finished.isSet = true
        }
        while !finished.isSet, repository.pendingCount < 2 { await Task.yield() }
        let callsMidReload = repository.callCount

        // Release the reload (and anything leaked) before checking, so a
        // regression fails here rather than hanging on a held call.
        for index in 0..<repository.callCount { repository.resume(at: index) }
        await midReload.value
        try #require(callsMidReload == 3, "No next-page request while the first page is reloading")

        // Once the Dead page 1 lands, paging resumes from it.
        while sut.characters.first?.id != 7 { await Task.yield() }

        let nextPage = Task { await sut.loadNextPageIfNeeded() }
        while repository.pendingCount < 1 { await Task.yield() }
        repository.resume(at: repository.callCount - 1)
        await nextPage.value

        #expect(repository.receivedRequests.last == CharactersRequest(page: 2, status: .dead))
        #expect(sut.characters.map(\.id) == [7, 8])
    }

    // MARK: - Pagination

    @Test("No next-page request when there is no next page")
    func noNextPageRequestWhenExhausted() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: [1], hasNextPage: false))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        await sut.loadNextPageIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test("A successful next page appends and advances the page number")
    func nextPageAppends() async {
        let repository = MockCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2], totalCount: 4, hasNextPage: true)),
            .success(.fixture(ids: [3, 4], totalCount: 4, hasNextPage: false)),
        ]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        await sut.loadNextPageIfNeeded()

        #expect(sut.characters.map(\.id) == [1, 2, 3, 4], "Page 2 must append, not replace")
        #expect(repository.receivedRequests.last?.page == 2)
        #expect(sut.hasNextPage == false)
    }

    @Test("A failed next page keeps the characters already loaded")
    func failedNextPageKeepsContent() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: [1, 2], hasNextPage: true))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        repository.results = [.failure(TestError())]
        await sut.loadNextPageIfNeeded()

        #expect(sut.characters.map(\.id) == [1, 2], "A failed page must not discard loaded items")
        #expect(sut.loadState == .loaded)
    }

    @Test("The pagination token advances after a failed next page so the footer re-arms")
    func paginationTokenAdvancesOnFailure() async {
        let repository = MockCharactersRepository()
        repository.results = [.success(.fixture(ids: [1], hasNextPage: true))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()
        let tokenBefore = sut.paginationToken

        repository.results = [.failure(TestError())]
        await sut.loadNextPageIfNeeded()

        #expect(sut.paginationToken != tokenBefore, "Pagination must not silently stall after a failure")
    }

    @Test("The pagination token advances after a successful next page")
    func paginationTokenAdvancesOnSuccess() async {
        let repository = MockCharactersRepository()
        repository.results = [
            .success(.fixture(ids: [1], hasNextPage: true)),
            .success(.fixture(ids: [2], hasNextPage: true)),
        ]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()
        let tokenBefore = sut.paginationToken

        await sut.loadNextPageIfNeeded()

        #expect(sut.paginationToken != tokenBefore, "The footer sentinel must re-arm")
    }
}

/// Lets a test observe that a `Task` ran to completion without awaiting it —
/// for when awaiting would hang if the behavior under test regressed.
@MainActor
private final class Flag {
    var isSet = false
}

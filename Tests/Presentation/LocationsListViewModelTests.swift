//
//  LocationsListViewModelTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `LocationsListViewModel` — the paginated-list logic it shares with
/// the Characters list (minus search/filter): state transitions, race guarding,
/// cancellation-vs-failure, and pagination.
///
/// Timing is never driven by sleeping: out-of-order completion is forced by
/// holding mocked calls open, and the next-page back-off is cut short by
/// cancelling the load.
@MainActor
struct LocationsListViewModelTests {

    /// Takes any `LocationsRepository` so the race tests can pass
    /// ``SuspendingLocationsRepository`` and everything else the plain spy.
    private func makeSUT(
        repository: some LocationsRepository
    ) -> LocationsListViewModel {
        LocationsListViewModel(repository: repository)
    }

    // MARK: - First-page load & state transitions

    @Test("Loads the first page on appear")
    func loadsFirstPageOnAppear() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: [1, 2], totalCount: 126, hasNextPage: true))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.locations.map(\.id) == [1, 2])
        #expect(sut.totalCount == 126)
        #expect(sut.hasNextPage)
        #expect(sut.loadState == .loaded)
    }

    @Test("Empty results land in the empty state")
    func emptyResultsShowEmptyState() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: []))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .empty)
        #expect(sut.locations.isEmpty)
    }

    @Test("A failed first page clears content and shows the error state")
    func failedFirstPageShowsError() async {
        let repository = MockLocationsRepository()
        repository.results = [.failure(TestError())]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .failed)
        #expect(sut.locations.isEmpty)
        #expect(sut.totalCount == 0)
        #expect(sut.hasNextPage == false)
    }

    @Test("Appearing again does not reload once content is loaded")
    func secondAppearDoesNotReload() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: [1]))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        await sut.onAppear()

        #expect(repository.callCount == 1)
    }

    @Test("Retry after a failure reloads and recovers")
    func retryAfterFailureRecovers() async {
        let repository = MockLocationsRepository()
        repository.results = [.failure(TestError()), .success(.fixture(ids: [1]))]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        #expect(sut.loadState == .failed)

        await sut.retry()

        #expect(sut.loadState == .loaded)
        #expect(sut.locations.map(\.id) == [1])
    }

    @Test("A reload over loaded content does not flash back to the skeleton")
    func reloadKeepsLoadedStateWhileRefetching() async {
        // Proves the `isFirstLoad = loadState != .loaded` guard: a pull-to-refresh
        // over existing content must stay `.loaded` (content on screen) rather
        // than dropping to `.loading` (skeleton flash). A suspended reload lets us
        // observe the state *during* the in-flight fetch.
        let repository = SuspendingLocationsRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2])),
            .success(.fixture(ids: [3, 4])),
        ]
        let sut = makeSUT(repository: repository)

        let firstLoad = Task { await sut.onAppear() }
        while repository.pendingCount < 1 { await Task.yield() }
        repository.resume(at: 0)
        await firstLoad.value
        #expect(sut.loadState == .loaded)

        let reload = Task { await sut.reload() }
        while repository.pendingCount < 1 { await Task.yield() }

        // The reload is in flight; the previous content must still be shown.
        #expect(sut.loadState == .loaded, "A reload must not flash the skeleton")
        #expect(sut.locations.map(\.id) == [1, 2])

        // `resume(at:)` indexes by absolute call order, and the slot for the
        // first (already-resumed) load is retained, so the reload's call is at
        // index 1, not 0.
        repository.resume(at: 1)
        await reload.value
        #expect(sut.locations.map(\.id) == [3, 4])
    }

    // MARK: - Cancellation is not failure

    @Test("A cancelled first load returns to idle so re-appearing retries")
    func cancelledFirstLoadReturnsToIdle() async {
        let repository = MockLocationsRepository()
        repository.results = [.failure(CancellationError())]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()

        #expect(sut.loadState == .idle, "Cancellation must not surface as a failure")
    }

    @Test("A cancelled reload keeps the content already on screen")
    func cancelledReloadKeepsContent() async {
        let repository = MockLocationsRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2])),
            .failure(CancellationError()),
        ]
        let sut = makeSUT(repository: repository)

        await sut.onAppear()
        await sut.reload()

        #expect(sut.loadState == .loaded)
        #expect(sut.locations.map(\.id) == [1, 2])
    }

    // MARK: - Race guarding

    @Test("A superseded load is discarded even when it completes last")
    func supersededLoadIsDiscardedWhenItLandsLast() async {
        let repository = SuspendingLocationsRepository()
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

        #expect(sut.locations.map(\.id) == [9], "The stale response must not overwrite fresher results")
        #expect(sut.loadState == .loaded)
    }

    @Test("A stale next page is not appended after a reload")
    func staleNextPageIsNotAppended() async {
        let repository = SuspendingLocationsRepository()
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

        #expect(sut.locations.map(\.id) == [7], "A stale page must not append to the fresh list")
    }

    // MARK: - Pagination

    @Test("No next-page request when there is no next page")
    func noNextPageRequestWhenExhausted() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: [1], hasNextPage: false))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        await sut.loadNextPageIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test("A successful next page appends and advances the page number")
    func nextPageAppends() async {
        let repository = MockLocationsRepository()
        repository.results = [
            .success(.fixture(ids: [1, 2], totalCount: 4, hasNextPage: true)),
            .success(.fixture(ids: [3, 4], totalCount: 4, hasNextPage: false)),
        ]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        await sut.loadNextPageIfNeeded()

        #expect(sut.locations.map(\.id) == [1, 2, 3, 4], "Page 2 must append, not replace")
        #expect(repository.receivedRequests.last?.page == 2)
        #expect(sut.hasNextPage == false)
    }

    @Test("A failed next page keeps the locations already loaded")
    func failedNextPageKeepsContent() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: [1, 2], hasNextPage: true))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()

        repository.results = [.failure(TestError())]
        await loadNextPageSkippingBackOff(on: sut, repository: repository)

        #expect(sut.locations.map(\.id) == [1, 2], "A failed page must not discard loaded items")
        #expect(sut.loadState == .loaded)
    }

    @Test("The pagination token advances after a failed next page so the footer re-arms")
    func paginationTokenAdvancesOnFailure() async {
        let repository = MockLocationsRepository()
        repository.results = [.success(.fixture(ids: [1], hasNextPage: true))]
        let sut = makeSUT(repository: repository)
        await sut.onAppear()
        let tokenBefore = sut.paginationToken

        repository.results = [.failure(TestError())]
        await loadNextPageSkippingBackOff(on: sut, repository: repository)

        #expect(sut.paginationToken != tokenBefore, "Pagination must not silently stall after a failure")
        #expect(sut.isLoadingNextPage == false)
    }

    @Test("The pagination token advances after a successful next page")
    func paginationTokenAdvancesOnSuccess() async {
        let repository = MockLocationsRepository()
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

    /// Runs a next-page load that is expected to fail, without waiting out the
    /// production back-off.
    ///
    /// The failure path sleeps ~1s (an API rate-limit back-off) with a hard-coded
    /// interval — it isn't injectable. Rather than stalling the suite for a second
    /// per test, this cancels the load once the repository call has been made: the
    /// back-off uses `try? Task.sleep`, so cancellation cuts it short and the
    /// `defer` block still runs, which is the behavior under test. The observable
    /// outcome is identical, it just doesn't take a second.
    private func loadNextPageSkippingBackOff(
        on sut: LocationsListViewModel,
        repository: MockLocationsRepository
    ) async {
        let callsBefore = repository.callCount
        let load = Task { await sut.loadNextPageIfNeeded() }
        while repository.callCount == callsBefore { await Task.yield() }
        load.cancel()
        await load.value
    }
}

//
//  EpisodesListViewModelTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `EpisodesListViewModel` — load-state transitions, retry, the
/// season-grouping logic (section ordering, episode ordering, the "Unknown"
/// bucket), and the generation-token race guard.
///
/// Mocks the `FetchAllEpisodesUseCase` protocol. Out-of-order completion is
/// forced by holding a mocked call open, never by sleeping.
@MainActor
struct EpisodesListViewModelTests {

    private func makeSUT(useCase: some FetchAllEpisodesUseCase) -> EpisodesListViewModel {
        EpisodesListViewModel(fetchAllEpisodes: useCase)
    }

    // MARK: - Load state transitions

    @Test("Loads on appear and lands in the loaded state")
    func loadsOnAppear() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([.fixture(id: 1, code: "S01E01")])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.loadState == .loaded)
        #expect(sut.totalCount == 1)
    }

    @Test("An empty result lands in the empty state")
    func emptyResultShowsEmptyState() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.loadState == .empty)
        #expect(sut.sections.isEmpty)
        #expect(sut.totalCount == 0)
    }

    @Test("A failed load clears content and shows the error state")
    func failedLoadShowsError() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.failure(TestError())]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.loadState == .failed)
        #expect(sut.sections.isEmpty)
        #expect(sut.totalCount == 0)
    }

    @Test("Appearing again does not reload once content is loaded")
    func secondAppearDoesNotReload() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([.fixture(id: 1, code: "S01E01")])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()
        await sut.onAppear()

        #expect(useCase.callCount == 1)
    }

    @Test("Retry after a failure reloads and recovers")
    func retryAfterFailureRecovers() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [
            .failure(TestError()),
            .success([.fixture(id: 1, code: "S01E01")]),
        ]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()
        #expect(sut.loadState == .failed)

        await sut.retry()

        #expect(sut.loadState == .loaded)
        #expect(sut.totalCount == 1)
    }

    @Test("A cancelled first load returns to idle so re-appearing retries")
    func cancelledFirstLoadReturnsToIdle() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.failure(CancellationError())]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.loadState == .idle, "Cancellation must not surface as a failure")
    }

    // MARK: - Season grouping

    @Test("Groups episodes into season sections ordered ascending")
    func groupsIntoSeasonSectionsAscending() async {
        let useCase = MockFetchAllEpisodesUseCase()
        // Deliberately out of order to prove the view model sorts.
        useCase.results = [.success([
            .fixture(id: 4, code: "S02E01"),
            .fixture(id: 1, code: "S01E01"),
            .fixture(id: 5, code: "S03E01"),
        ])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.sections.map(\.season) == [1, 2, 3], "Seasons must be ordered ascending")
        #expect(sut.sections.map(\.title) == ["Season 1", "Season 2", "Season 3"])
    }

    @Test("Orders episodes ascending within a season")
    func ordersEpisodesWithinSeason() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([
            .fixture(id: 3, code: "S01E03"),
            .fixture(id: 1, code: "S01E01"),
            .fixture(id: 2, code: "S01E02"),
        ])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        let section = sut.sections.first
        #expect(section?.episodes.map(\.id) == [1, 2, 3], "Episodes must be ordered by episode number")
    }

    @Test("Episode ordering is numeric, not lexicographic")
    func episodeOrderingIsNumeric() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([
            .fixture(id: 10, code: "S01E10"),
            .fixture(id: 2, code: "S01E02"),
        ])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.sections.first?.episodes.map(\.id) == [2, 10], "E10 must sort after E02, not before")
    }

    @Test("An unparseable code lands in a trailing Unknown section, not dropped")
    func unparseableCodeGoesToUnknownBucket() async {
        let useCase = MockFetchAllEpisodesUseCase()
        useCase.results = [.success([
            .fixture(id: 1, code: "S01E01"),
            .fixture(id: 99, code: "???"),
        ])]
        let sut = makeSUT(useCase: useCase)

        await sut.onAppear()

        #expect(sut.sections.count == 2)
        #expect(sut.sections.last?.season == nil, "The unparseable episode goes to the nil bucket")
        #expect(sut.sections.last?.title == "Unknown")
        #expect(sut.sections.last?.episodes.map(\.id) == [99])
        #expect(sut.totalCount == 2, "The Unknown episode is still counted, not dropped")
    }

    // MARK: - Race guarding

    @Test("A superseded load is discarded even when it completes last")
    func supersededLoadIsDiscardedWhenItLandsLast() async {
        let useCase = SuspendingFetchAllEpisodesUseCase()
        useCase.results = [
            .success([.fixture(id: 1, code: "S01E01")]),  // load A — stale
            .success([.fixture(id: 9, code: "S09E09")]),  // load B — current
        ]
        let sut = makeSUT(useCase: useCase)

        let loadA = Task { await sut.reload() }
        while useCase.pendingCount < 1 { await Task.yield() }

        let loadB = Task { await sut.reload() }
        while useCase.pendingCount < 2 { await Task.yield() }

        // Finish B first, then A — so the stale response lands last.
        useCase.resume(at: 1)
        await loadB.value
        useCase.resume(at: 0)
        await loadA.value

        #expect(sut.sections.map(\.season) == [9], "The stale response must not overwrite fresher results")
        #expect(sut.loadState == .loaded)
    }
}

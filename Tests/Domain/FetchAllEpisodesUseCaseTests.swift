//
//  FetchAllEpisodesUseCaseTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `DefaultFetchAllEpisodesUseCase` — the multi-page accumulation that
/// walks the API's pages until none remain and concatenates them into one flat
/// list, in order. Mocks the `EpisodesRepository` protocol.
@MainActor
struct FetchAllEpisodesUseCaseTests {

    private func makeSUT(repository: MockEpisodesRepository) -> DefaultFetchAllEpisodesUseCase {
        DefaultFetchAllEpisodesUseCase(repository: repository)
    }

    @Test("Fetches every page and concatenates them in order")
    func fetchesAllPagesInOrder() async throws {
        let repository = MockEpisodesRepository()
        repository.results = [
            .success(.fixture([(1, "S01E01"), (2, "S01E02")], hasNextPage: true)),
            .success(.fixture([(3, "S01E03"), (4, "S02E01")], hasNextPage: true)),
            .success(.fixture([(5, "S02E02")], hasNextPage: false)),
        ]
        let sut = makeSUT(repository: repository)

        let episodes = try await sut.execute()

        #expect(episodes.map(\.id) == [1, 2, 3, 4, 5], "Pages must concatenate in fetch order")
        #expect(repository.callCount == 3)
        #expect(repository.receivedRequests.map(\.page) == [1, 2, 3], "Pages requested 1, 2, 3 in sequence")
    }

    @Test("Stops after the first page when it reports no next page")
    func stopsWhenNoNextPage() async throws {
        let repository = MockEpisodesRepository()
        repository.results = [.success(.fixture([(1, "S01E01")], hasNextPage: false))]
        let sut = makeSUT(repository: repository)

        let episodes = try await sut.execute()

        #expect(episodes.map(\.id) == [1])
        #expect(repository.callCount == 1, "A single page with no next must not trigger a second request")
    }

    @Test("An error on any page propagates and stops paging")
    func errorPropagates() async {
        let repository = MockEpisodesRepository()
        repository.results = [
            .success(.fixture([(1, "S01E01")], hasNextPage: true)),
            .failure(TestError()),
        ]
        let sut = makeSUT(repository: repository)

        await #expect(throws: TestError.self) {
            _ = try await sut.execute()
        }
        #expect(repository.callCount == 2, "Paging stops at the failing page")
    }
}

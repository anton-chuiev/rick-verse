//
//  CharacterDetailViewModelTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `CharacterDetailViewModel` — the two independent load states
/// (character, then episodes), the derived `firstSeenIn`, retry of either part,
/// and cancellation being treated as "not loaded yet" rather than an error.
///
/// Mocks the `CharacterDetailRepository` and `FetchEpisodeBatchUseCase`
/// protocols. Unscripted calls fail, so an unexpected extra fetch is loud.
/// Swift Testing creates a fresh suite instance per test, so the mocks held
/// here never leak between tests.
@MainActor
struct CharacterDetailViewModelTests {

    private let characterID = 1
    private let repository = MockCharacterDetailRepository()
    private let fetchEpisodes = MockFetchEpisodeBatchUseCase()

    private func makeSUT(
        character: [Result<CharacterDetailResponse, Error>] = [],
        episodes: [Result<EpisodeBatchResponse, Error>] = []
    ) -> CharacterDetailViewModel {
        repository.results = character
        fetchEpisodes.results = episodes
        return CharacterDetailViewModel(
            characterID: characterID,
            repository: repository,
            fetchEpisodes: fetchEpisodes
        )
    }

    private func characterResponse(episodeIDs: [Int] = [1, 2]) -> CharacterDetailResponse {
        CharacterDetailResponse(character: .fixture(id: characterID, episodeIDs: episodeIDs))
    }

    private let pilot = Episode.fixture(id: 1, code: "S01E01", name: "Pilot")
    private let lawnmowerDog = Episode.fixture(id: 2, code: "S01E02", name: "Lawnmower Dog")

    // MARK: - Loading

    @Test("Appearing loads the character, then its episodes")
    func loadsCharacterThenEpisodes() async {
        let sut = makeSUT(
            character: [.success(characterResponse(episodeIDs: [1, 2]))],
            episodes: [.success(EpisodeBatchResponse(episodes: [pilot, lawnmowerDog]))]
        )

        await sut.onAppear()

        #expect(sut.characterState == .loaded(.fixture(id: characterID, episodeIDs: [1, 2])))
        #expect(sut.episodesState == .loaded([pilot, lawnmowerDog]))
        #expect(repository.receivedRequests == [CharacterDetailRequest(id: characterID)])
        #expect(
            fetchEpisodes.receivedRequests == [EpisodeBatchRequest(ids: [1, 2])],
            "Episodes are fetched in one batch for the character's episode IDs"
        )
    }

    @Test("First seen in is the first episode's name")
    func firstSeenInIsFirstEpisode() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.success(EpisodeBatchResponse(episodes: [pilot, lawnmowerDog]))]
        )

        await sut.onAppear()

        #expect(sut.firstSeenIn == "Pilot")
    }

    @Test("Appearing again after a load does not refetch")
    func secondAppearDoesNotRefetch() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.success(EpisodeBatchResponse(episodes: [pilot]))]
        )

        await sut.onAppear()
        await sut.onAppear()

        #expect(repository.callCount == 1)
        #expect(fetchEpisodes.callCount == 1)
    }

    // MARK: - Character failure

    @Test("A failed character load shows the error and never requests episodes")
    func characterFailureSkipsEpisodes() async {
        let sut = makeSUT(character: [.failure(APIError.notFound)])

        await sut.onAppear()

        #expect(sut.characterState == .failed)
        #expect(sut.character == nil)
        #expect(fetchEpisodes.callCount == 0)
    }

    @Test("Retrying after a character failure recovers the whole screen")
    func retryCharacterRecovers() async {
        let sut = makeSUT(
            character: [.failure(TestError()), .success(characterResponse())],
            episodes: [.success(EpisodeBatchResponse(episodes: [pilot]))]
        )
        await sut.onAppear()

        await sut.retryCharacter()

        #expect(sut.characterState == .loaded(.fixture(id: characterID, episodeIDs: [1, 2])))
        #expect(sut.episodesState == .loaded([pilot]))
        #expect(repository.callCount == 2)
    }

    // MARK: - Episodes

    @Test("A character with no episodes shows the empty section without a request")
    func noEpisodeIDsShowsEmptyWithoutRequest() async {
        let sut = makeSUT(character: [.success(characterResponse(episodeIDs: []))])

        await sut.onAppear()

        #expect(sut.episodesState == .empty)
        #expect(fetchEpisodes.callCount == 0)
    }

    @Test("An empty batch response shows the empty section")
    func emptyBatchShowsEmpty() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.success(EpisodeBatchResponse(episodes: []))]
        )

        await sut.onAppear()

        #expect(sut.episodesState == .empty)
        #expect(sut.firstSeenIn == nil)
    }

    @Test("A failed episodes load keeps the character on screen")
    func episodesFailureKeepsCharacter() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.failure(TestError())]
        )

        await sut.onAppear()

        #expect(sut.character != nil)
        #expect(sut.episodesState == .failed)
        #expect(sut.firstSeenIn == nil)
    }

    @Test("Retrying episodes recovers them without refetching the character")
    func retryEpisodesRecovers() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.failure(TestError()), .success(EpisodeBatchResponse(episodes: [pilot]))]
        )
        await sut.onAppear()

        await sut.retryEpisodes()

        #expect(sut.episodesState == .loaded([pilot]))
        #expect(repository.callCount == 1)
        #expect(fetchEpisodes.callCount == 2)
    }

    @Test("Retrying episodes before the character has loaded does nothing")
    func retryEpisodesWithoutCharacterIsNoOp() async {
        let sut = makeSUT(character: [.failure(TestError())])
        await sut.onAppear()

        await sut.retryEpisodes()

        #expect(sut.episodesState == .loading)
        #expect(fetchEpisodes.callCount == 0)
    }

    // MARK: - Cancellation

    @Test("A cancelled character load stays loading, so the next appear refetches")
    func cancelledCharacterLoadRefetchesOnAppear() async {
        let sut = makeSUT(
            character: [.failure(CancellationError()), .success(characterResponse())],
            episodes: [.success(EpisodeBatchResponse(episodes: [pilot]))]
        )

        await sut.onAppear()
        #expect(sut.characterState == .loading, "Cancellation is not a failure")

        await sut.onAppear()

        #expect(sut.character != nil)
        #expect(repository.callCount == 2)
    }

    @Test("A cancelled episodes load stays loading rather than failing")
    func cancelledEpisodesLoadStaysLoading() async {
        let sut = makeSUT(
            character: [.success(characterResponse())],
            episodes: [.failure(CancellationError())]
        )

        await sut.onAppear()

        #expect(sut.episodesState == .loading)
    }
}

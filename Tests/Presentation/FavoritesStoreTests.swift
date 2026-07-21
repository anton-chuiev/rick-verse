//
//  FavoritesStoreTests.swift
//  Tests
//

import Foundation
import Testing
@testable import rick_verse

/// Tests for `FavoritesStore` — the shared favorites state the three screens
/// observe. Covers: toggle add/remove, the optimistic update + revert-on-error,
/// and that `favoriteIDs` and `favorites` stay in agreement on every mutation
/// (the seam the cross-screen reactivity rests on). Timing is driven by gating
/// the mock, never by sleeping.
///
/// `@MainActor` to match the store under test.
@MainActor
struct FavoritesStoreTests {

    private func makeSUT(
        seed: [FavoriteCharacterSnapshot] = []
    ) -> (FavoritesStore, MockFavoritesRepository) {
        let repository = MockFavoritesRepository(seed: seed)
        return (FavoritesStore(repository: repository), repository)
    }

    // MARK: - Load

    @Test("Load populates both views, newest-first")
    func loadPopulatesNewestFirst() async {
        let older = FavoriteCharacterSnapshot(id: 1, name: "Rick", imageURL: nil, status: .alive, dateAdded: Date(timeIntervalSince1970: 1))
        let newer = FavoriteCharacterSnapshot(id: 2, name: "Morty", imageURL: nil, status: .alive, dateAdded: Date(timeIntervalSince1970: 2))
        let (sut, _) = makeSUT(seed: [older, newer])

        await sut.load()

        #expect(sut.favorites.map(\.id) == [2, 1], "newest dateAdded first")
        #expect(sut.favoriteIDs == [1, 2])
    }

    // MARK: - Toggle add

    @Test("Toggling an unfavorited character adds it to both views")
    func toggleAddsWhenAbsent() async {
        let (sut, repository) = makeSUT()

        await sut.toggle(.fixture(id: 7, name: "Birdperson"))

        #expect(sut.isFavorite(id: 7))
        #expect(sut.favoriteIDs == [7])
        #expect(sut.favorites.map(\.id) == [7])
        #expect(sut.favorites.first?.name == "Birdperson")
        #expect(repository.addCallCount == 1)
        #expect(repository.removeCallCount == 0)
    }

    @Test("A newly added favorite goes to the front (newest-first)")
    func addInsertsAtFront() async {
        let existing = FavoriteCharacterSnapshot(id: 1, name: "Rick", imageURL: nil, status: .alive, dateAdded: Date(timeIntervalSince1970: 1))
        let (sut, _) = makeSUT(seed: [existing])
        await sut.load()

        await sut.toggle(.fixture(id: 2, name: "Morty"))

        #expect(sut.favorites.map(\.id) == [2, 1], "the just-added id is first")
    }

    // MARK: - Toggle remove

    @Test("Toggling a favorited character removes it from both views")
    func toggleRemovesWhenPresent() async {
        let seed = FavoriteCharacterSnapshot(id: 7, name: "Birdperson", imageURL: nil, status: .alive, dateAdded: .now)
        let (sut, repository) = makeSUT(seed: [seed])
        await sut.load()

        await sut.toggle(.fixture(id: 7))

        #expect(sut.isFavorite(id: 7) == false)
        #expect(sut.favoriteIDs.isEmpty)
        #expect(sut.favorites.isEmpty)
        #expect(repository.removeCallCount == 1)
    }

    @Test("remove(id:) drops the favorite from both views")
    func removeByIDUpdatesBothViews() async {
        let a = FavoriteCharacterSnapshot(id: 1, name: "Rick", imageURL: nil, status: .alive, dateAdded: Date(timeIntervalSince1970: 2))
        let b = FavoriteCharacterSnapshot(id: 2, name: "Morty", imageURL: nil, status: .alive, dateAdded: Date(timeIntervalSince1970: 1))
        let (sut, _) = makeSUT(seed: [a, b])
        await sut.load()

        await sut.remove(id: 1)

        #expect(sut.favoriteIDs == [2])
        #expect(sut.favorites.map(\.id) == [2])
    }

    // MARK: - Optimistic revert on error

    @Test("An add that fails reverts both views")
    func addFailureReverts() async {
        let (sut, repository) = makeSUT()
        repository.addError = TestError()

        await sut.toggle(.fixture(id: 7))

        #expect(sut.isFavorite(id: 7) == false, "id rolled back")
        #expect(sut.favorites.isEmpty, "snapshot rolled back")
    }

    @Test("A remove that fails restores both views")
    func removeFailureRestores() async {
        let seed = FavoriteCharacterSnapshot(id: 7, name: "Birdperson", imageURL: nil, status: .dead, dateAdded: .now)
        let (sut, repository) = makeSUT(seed: [seed])
        await sut.load()
        repository.removeError = TestError()

        await sut.remove(id: 7)

        #expect(sut.isFavorite(id: 7), "id restored")
        #expect(sut.favorites.map(\.id) == [7], "snapshot restored")
    }

    // MARK: - Optimistic timing (state flips before the write resolves)

    @Test("The heart flips optimistically, before the repository call resolves")
    func optimisticUpdateHappensBeforeWriteCompletes() async {
        let (sut, repository) = makeSUT()
        repository.gateCalls = true

        let toggle = Task { await sut.toggle(.fixture(id: 7)) }
        // Wait until the add is in flight (gated) — the optimistic update has run
        // by now, but the repository write has not completed.
        while repository.gatedCount < 1 { await Task.yield() }

        #expect(sut.isFavorite(id: 7), "state is already favorited while the write is still pending")
        #expect(sut.favorites.map(\.id) == [7])

        repository.release()
        await toggle.value
        #expect(sut.isFavorite(id: 7), "stays favorited after the write succeeds")
    }

    // MARK: - Double-tap consistency

    @Test("A rapid double-tap ends consistent (add then remove → not favorited)")
    func doubleTapEndsConsistent() async {
        let (sut, repository) = makeSUT()
        repository.gateCalls = true
        let character = RMCharacter.fixture(id: 7)

        // First tap: not favorite → add, gated in flight.
        let first = Task { await sut.toggle(character) }
        while repository.gatedCount < 1 { await Task.yield() }
        // The optimistic add already flipped state to favorited...
        #expect(sut.isFavorite(id: 7))

        // Second tap sees the favorited state → remove, also gated.
        let second = Task { await sut.toggle(character) }
        while repository.gatedCount < 2 { await Task.yield() }

        repository.release()
        await first.value
        await second.value

        // Net effect: add then remove → not favorited, and both views agree.
        #expect(sut.isFavorite(id: 7) == false)
        #expect(sut.favorites.isEmpty)
        #expect(sut.favoriteIDs.isEmpty)
        #expect(repository.addCallCount == 1)
        #expect(repository.removeCallCount == 1)
    }
}

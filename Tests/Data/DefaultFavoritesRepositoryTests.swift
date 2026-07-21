//
//  DefaultFavoritesRepositoryTests.swift
//  Tests
//

import Foundation
import SwiftData
import Testing
@testable import rick_verse

/// Tests for `DefaultFavoritesRepository` — driven against a real, in-memory
/// `ModelContainer` (the SwiftData analogue of the network repositories' stubbed
/// `APIClient`). Covers add/upsert, remove and its no-op case, newest-first
/// ordering, and the model ↔ snapshot mapping round-trip.
///
/// `@MainActor` to match the repository, whose `ModelContext` is main-actor-bound.
@MainActor
struct DefaultFavoritesRepositoryTests {

    /// Builds a repository over a fresh in-memory container, so each test starts
    /// from an empty store and never touches disk. The repository owns the
    /// container, so its lifetime is safe.
    private func makeSUT() -> DefaultFavoritesRepository {
        DefaultFavoritesRepository(container: PersistenceController.makeInMemoryContainer())
    }

    private func snapshot(
        id: Int,
        name: String = "Rick",
        imageURL: URL? = URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"),
        status: RMCharacter.Status = .alive,
        dateAdded: Date = .now
    ) -> FavoriteCharacterSnapshot {
        FavoriteCharacterSnapshot(id: id, name: name, imageURL: imageURL, status: status, dateAdded: dateAdded)
    }

    // MARK: - Add & fetch

    @Test("Adding a favorite then fetching returns it")
    func addThenFetch() async throws {
        let sut = makeSUT()

        try await sut.add(snapshot(id: 1, name: "Rick Sanchez"))
        let favorites = try await sut.favorites()

        #expect(favorites.map(\.id) == [1])
        #expect(favorites.first?.name == "Rick Sanchez")
    }

    @Test("favoriteIDs returns the stored ids")
    func favoriteIDsReturnsStoredIDs() async throws {
        let sut = makeSUT()

        try await sut.add(snapshot(id: 1))
        try await sut.add(snapshot(id: 2))

        #expect(try await sut.favoriteIDs() == [1, 2])
    }

    // MARK: - Upsert

    @Test("Adding the same id twice upserts — no duplicate, latest snapshot wins")
    func addSameIDUpserts() async throws {
        let sut = makeSUT()

        try await sut.add(snapshot(id: 1, name: "Rick"))
        try await sut.add(snapshot(id: 1, name: "Pickle Rick", status: .unknown))

        let favorites = try await sut.favorites()
        #expect(favorites.count == 1, "unique id means the second add replaces the first")
        #expect(favorites.first?.name == "Pickle Rick")
        #expect(favorites.first?.status == .unknown)
    }

    // MARK: - Remove

    @Test("Removing deletes the favorite")
    func removeDeletes() async throws {
        let sut = makeSUT()
        try await sut.add(snapshot(id: 1))
        try await sut.add(snapshot(id: 2))

        try await sut.remove(id: 1)

        #expect(try await sut.favoriteIDs() == [2])
    }

    @Test("Removing an id that isn't stored is a no-op")
    func removeAbsentIsNoOp() async throws {
        let sut = makeSUT()
        try await sut.add(snapshot(id: 1))

        try await sut.remove(id: 99)

        #expect(try await sut.favoriteIDs() == [1])
    }

    // MARK: - Ordering

    @Test("Favorites come back newest-first by dateAdded")
    func favoritesAreNewestFirst() async throws {
        let sut = makeSUT()
        try await sut.add(snapshot(id: 1, dateAdded: Date(timeIntervalSince1970: 1)))
        try await sut.add(snapshot(id: 2, dateAdded: Date(timeIntervalSince1970: 3)))
        try await sut.add(snapshot(id: 3, dateAdded: Date(timeIntervalSince1970: 2)))

        let favorites = try await sut.favorites()

        #expect(favorites.map(\.id) == [2, 3, 1])
    }

    // MARK: - Mapping round-trip

    @Test("Status round-trips through storage", arguments: [
        RMCharacter.Status.alive,
        .dead,
        .unknown,
    ])
    func statusRoundTrips(status: RMCharacter.Status) async throws {
        let sut = makeSUT()

        try await sut.add(snapshot(id: 1, status: status))
        let favorites = try await sut.favorites()

        #expect(favorites.first?.status == status)
    }

    @Test("A nil image round-trips as nil")
    func nilImageRoundTrips() async throws {
        let sut = makeSUT()

        try await sut.add(snapshot(id: 1, imageURL: nil))
        let favorites = try await sut.favorites()

        #expect(favorites.first?.imageURL == nil)
    }

    @Test("A non-nil image round-trips intact")
    func imageURLRoundTrips() async throws {
        let sut = makeSUT()
        let url = URL(string: "https://rickandmortyapi.com/api/character/avatar/42.jpeg")

        try await sut.add(snapshot(id: 42, imageURL: url))
        let favorites = try await sut.favorites()

        #expect(favorites.first?.imageURL == url)
    }
}

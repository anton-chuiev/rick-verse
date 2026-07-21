//
//  MockFavoritesRepository.swift
//  Tests
//

import Foundation
@testable import rick_verse

/// `FavoritesRepository` test double. Backed by an in-memory dictionary so it
/// behaves like the real store (add upserts, remove is a no-op when absent),
/// records calls, and can be made to fail or to *gate* a call open so two
/// operations overlap for reentrancy/race tests.
///
/// `@MainActor` because the `FavoritesStore` under test is — a test can inspect
/// recorded calls right after awaiting the store.
@MainActor
final class MockFavoritesRepository: FavoritesRepository {
    private var stored: [Int: FavoriteCharacterSnapshot] = [:]

    /// If set, the next matching operation throws this instead of mutating.
    var addError: Error?
    var removeError: Error?

    private(set) var addCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var favoritesCallCount = 0

    /// When true, `add`/`remove` suspend until `release()` is called, so a test
    /// can start a second operation while the first is in flight.
    var gateCalls = false
    private var gate: [CheckedContinuation<Void, Never>] = []

    init(seed: [FavoriteCharacterSnapshot] = []) {
        for snapshot in seed { stored[snapshot.id] = snapshot }
    }

    /// Number of operations currently suspended on the gate.
    var gatedCount: Int { gate.count }

    /// Releases all gated operations, letting them complete.
    func release() {
        let continuations = gate
        gate.removeAll()
        for continuation in continuations { continuation.resume() }
    }

    func favorites() async throws -> [FavoriteCharacterSnapshot] {
        favoritesCallCount += 1
        return stored.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    func favoriteIDs() async throws -> Set<Int> {
        Set(stored.keys)
    }

    func add(_ character: FavoriteCharacterSnapshot) async throws {
        addCallCount += 1
        await gateIfNeeded()
        if let addError { throw addError }
        stored[character.id] = character
    }

    func remove(id: Int) async throws {
        removeCallCount += 1
        await gateIfNeeded()
        if let removeError { throw removeError }
        stored[id] = nil
    }

    private func gateIfNeeded() async {
        guard gateCalls else { return }
        await withCheckedContinuation { continuation in
            gate.append(continuation)
        }
    }
}

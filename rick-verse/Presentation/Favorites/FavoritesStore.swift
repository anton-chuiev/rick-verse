//
//  FavoritesStore.swift
//  rick-verse
//

import Foundation
import Observation

/// Shared, app-wide source of truth for favorites. A single instance lives in
/// the SwiftUI environment, so the Characters list, Character detail, and
/// Favorites screens all observe the *same* state — a toggle on one screen
/// updates the others live, with no manual refresh.
///
/// Holds two views of the same data that must always agree:
/// - `favoriteIDs` — read synchronously by the hearts (`isFavorite(id:)`).
/// - `favorites` — the newest-first snapshot list the Favorites screen renders.
///
/// Depends only on the `FavoritesRepository` protocol (the mockable test seam).
@Observable
@MainActor
final class FavoritesStore {
    private(set) var favoriteIDs: Set<Int> = []
    private(set) var favorites: [FavoriteCharacterSnapshot] = []

    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    /// True if the character is currently favorited. Synchronous so hearts render
    /// instantly without awaiting.
    func isFavorite(id: Int) -> Bool {
        favoriteIDs.contains(id)
    }

    /// Loads both views from the store. Called when the Favorites screen appears
    /// and once at app start to warm the id set for the hearts. Best-effort: a
    /// read failure leaves the current state in place.
    func load() async {
        guard let snapshots = try? await repository.favorites() else { return }
        favorites = snapshots
        favoriteIDs = Set(snapshots.map(\.id))
    }

    /// Adds or removes the character depending on its current state. Updates
    /// `favoriteIDs` and `favorites` together and *optimistically* — the heart
    /// flips before the persistence call resolves — then reverts both if the
    /// repository throws. Moving both properties in lockstep is what keeps the
    /// three screens consistent.
    ///
    /// Reentrancy: on `@MainActor` the optimistic mutation happens synchronously
    /// before the `await`, so a rapid double-tap sees the already-flipped state
    /// and toggles back — the happy path stays consistent. The error-revert path
    /// makes the (safe for a local store) assumption that a failed write should
    /// undo its own optimistic change; any rare desync is reconciled by the next
    /// `load()`. In-flight-task dedup would be overkill for a favorites toggle.
    func toggle(_ character: RMCharacter) async {
        if isFavorite(id: character.id) {
            await remove(id: character.id)
        } else {
            await add(character)
        }
    }

    /// Removes a favorite (used by the Favorites screen's remove affordance and
    /// by `toggle`). Optimistic with revert on failure.
    func remove(id: Int) async {
        let removed = favorites.first { $0.id == id }
        let wasFavorite = favoriteIDs.contains(id)

        favoriteIDs.remove(id)
        favorites.removeAll { $0.id == id }

        do {
            try await repository.remove(id: id)
        } catch {
            // Revert to the pre-toggle state.
            if wasFavorite { favoriteIDs.insert(id) }
            if let removed { reinsert(removed) }
        }
    }

    private func add(_ character: RMCharacter) async {
        let snapshot = FavoriteCharacterSnapshot(character: character)

        favoriteIDs.insert(snapshot.id)
        // Newest-first: the just-added snapshot goes to the front.
        favorites.insert(snapshot, at: 0)

        do {
            try await repository.add(snapshot)
        } catch {
            favoriteIDs.remove(snapshot.id)
            favorites.removeAll { $0.id == snapshot.id }
        }
    }

    /// Re-inserts a reverted snapshot in newest-first position.
    private func reinsert(_ snapshot: FavoriteCharacterSnapshot) {
        favorites.removeAll { $0.id == snapshot.id }
        let index = favorites.firstIndex { $0.dateAdded < snapshot.dateAdded } ?? favorites.endIndex
        favorites.insert(snapshot, at: index)
    }
}

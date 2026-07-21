//
//  DefaultFavoritesRepository.swift
//  rick-verse
//

import Foundation
import SwiftData

/// `FavoritesRepository` backed by SwiftData. `@MainActor` so its non-`Sendable`
/// `ModelContext` never crosses an actor boundary while the type still satisfies
/// the `Sendable` protocol. Uses the container's shared main context — the
/// favorites store is small, so no background context is needed.
///
/// Holds the `ModelContainer`, not a bare `ModelContext`: a `ModelContext` does
/// not keep its container alive, so taking only the context risks the container
/// deallocating out from under it (a dangling context that crashes on the next
/// `save()`). Owning the container makes the lifetime correct by construction.
///
/// Saves are explicit after every mutation (SwiftData's autosave timing is
/// unpredictable, and correctness matters here).
@MainActor
struct DefaultFavoritesRepository: FavoritesRepository {
    let container: ModelContainer

    /// The container's main context — shared with the SwiftUI environment's
    /// `.modelContainer`, so both see the same favorites.
    private var context: ModelContext { container.mainContext }

    func favorites() async throws -> [FavoriteCharacterSnapshot] {
        let descriptor = FetchDescriptor<FavoriteCharacter>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func favoriteIDs() async throws -> Set<Int> {
        // The favorites store is small, so a plain fetch is fine — no partial
        // `propertiesToFetch` projection (which is fragile) needed.
        Set(try context.fetch(FetchDescriptor<FavoriteCharacter>()).map(\.id))
    }

    func add(_ character: FavoriteCharacterSnapshot) async throws {
        // Upsert: the model's `.unique` id means inserting an existing id
        // replaces the stored row (refreshing name/image/status) rather than
        // duplicating it. No manual pre-delete needed.
        context.insert(
            FavoriteCharacter(
                id: character.id,
                name: character.name,
                imageURLString: character.imageURL?.absoluteString ?? "",
                status: character.status.storedValue,
                dateAdded: character.dateAdded
            )
        )
        try context.save()
    }

    func remove(id: Int) async throws {
        // Batch delete by predicate. The predicate captures the id via a local
        // `let` so it isn't confused with the model's own `id` key path.
        let targetID = id
        try context.delete(
            model: FavoriteCharacter.self,
            where: #Predicate { $0.id == targetID }
        )
        try context.save()
    }
}

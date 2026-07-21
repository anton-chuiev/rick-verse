//
//  FavoritesRepository.swift
//  rick-verse
//

/// Local persistence of favorited characters. Backed by SwiftData in the Data
/// layer; consumed by `FavoritesStore` (each operation is a single call to a
/// single store with no orchestration, so no use case sits in between — the
/// store depends on this protocol directly, which is the mockable test seam).
///
/// `Sendable` so the `@MainActor` store can hold it under Swift 6 strict
/// concurrency. Methods take/return plain domain values — the SwiftData `@Model`
/// stays inside the implementation.
protocol FavoritesRepository: Sendable {
    /// All favorites, newest-first (by `dateAdded` descending).
    func favorites() async throws -> [FavoriteCharacterSnapshot]

    /// Just the favorited ids, for the store's synchronous `isFavorite` lookups
    /// without materializing full snapshots.
    func favoriteIDs() async throws -> Set<Int>

    /// Adds a favorite, upserting by `id` (a repeat replaces rather than
    /// duplicates, via the model's unique `id`).
    func add(_ character: FavoriteCharacterSnapshot) async throws

    /// Removes the favorite with this `id`. A no-op if it isn't stored.
    func remove(id: Int) async throws
}

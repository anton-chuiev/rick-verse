//
//  PersistenceController.swift
//  rick-verse
//

import Foundation
import SwiftData

/// Builds the app's SwiftData `ModelContainer` for the favorites schema. The
/// container is created once at the app root and shared: it backs both the
/// SwiftUI environment (`.modelContainer`) and `DefaultFavoritesRepository`.
enum PersistenceController {
    /// The schema — just `FavoriteCharacter` for now.
    static let schema = Schema([FavoriteCharacter.self])

    /// On-disk container for the running app: favorites survive relaunch.
    static func makeContainer() -> ModelContainer {
        make(inMemory: false)
    }

    /// In-memory container for previews and tests: isolated, never touches disk.
    static func makeInMemoryContainer() -> ModelContainer {
        make(inMemory: true)
    }

    private static func make(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A container that can't be created is an unrecoverable setup error
            // (bad schema / disk), not a runtime condition to handle — fail loudly.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

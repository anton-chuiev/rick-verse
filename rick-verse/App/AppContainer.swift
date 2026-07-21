//
//  AppContainer.swift
//  rick-verse
//

import Foundation
import SwiftData

/// Composition root. Holds the app's repositories (the domain data boundary)
/// and builds view models from them, so views and coordinators don't wire
/// concrete types themselves. Value type: cheap to pass down the view tree.
///
/// `@MainActor` because it constructs and holds the `@MainActor` favorites
/// store / repository (their SwiftData `ModelContext` is main-actor-bound).
@MainActor
struct AppContainer {
    let charactersRepository: CharactersRepository
    let characterDetailRepository: CharacterDetailRepository
    let episodeBatchRepository: EpisodeBatchRepository
    let episodesRepository: EpisodesRepository
    let locationsRepository: LocationsRepository
    /// The SwiftData container backing favorites. Exposed so `AppShellView` can
    /// install it into the environment (`.modelContainer`) — the *same* container
    /// the favorites repository reads through.
    let modelContainer: ModelContainer
    /// Shared favorites state, a single instance for the whole app so all screens
    /// observe the same favorites (see `FavoritesStore`).
    let favoritesStore: FavoritesStore

    /// The live container: real repositories backed by the Rick and Morty API
    /// over a shared `URLSession` client, plus on-disk favorites persistence.
    static let live: AppContainer = {
        let apiClient = URLSessionAPIClient()
        let modelContainer = PersistenceController.makeContainer()
        let favoritesRepository = DefaultFavoritesRepository(container: modelContainer)
        return AppContainer(
            charactersRepository: DefaultCharactersRepository(apiClient: apiClient),
            characterDetailRepository: DefaultCharacterDetailRepository(apiClient: apiClient),
            episodeBatchRepository: DefaultEpisodeBatchRepository(apiClient: apiClient),
            episodesRepository: DefaultEpisodesRepository(apiClient: apiClient),
            locationsRepository: DefaultLocationsRepository(apiClient: apiClient),
            modelContainer: modelContainer,
            favoritesStore: FavoritesStore(repository: favoritesRepository)
        )
    }()

    #if DEBUG
    /// Container for SwiftUI previews: real view models over networkless stub
    /// repositories and an in-memory favorites store. Never used in a release build.
    static let preview: AppContainer = {
        let modelContainer = PersistenceController.makeInMemoryContainer()
        return AppContainer(
            charactersRepository: PreviewCharactersRepository(),
            characterDetailRepository: PreviewCharacterDetailRepository(),
            episodeBatchRepository: PreviewEpisodeBatchRepository(),
            episodesRepository: PreviewEpisodesRepository(),
            locationsRepository: PreviewLocationsRepository(),
            modelContainer: modelContainer,
            favoritesStore: FavoritesStore(repository: PreviewFavoritesRepository())
        )
    }()
    #endif

    @MainActor
    func makeCharactersListViewModel() -> CharactersListViewModel {
        CharactersListViewModel(repository: charactersRepository)
    }

    @MainActor
    func makeCharacterDetailViewModel(id: Int) -> CharacterDetailViewModel {
        CharacterDetailViewModel(
            characterID: id,
            repository: characterDetailRepository,
            fetchEpisodes: DefaultFetchEpisodeBatchUseCase(repository: episodeBatchRepository)
        )
    }

    @MainActor
    func makeEpisodesListViewModel() -> EpisodesListViewModel {
        EpisodesListViewModel(
            fetchAllEpisodes: DefaultFetchAllEpisodesUseCase(repository: episodesRepository)
        )
    }

    @MainActor
    func makeLocationsListViewModel() -> LocationsListViewModel {
        LocationsListViewModel(repository: locationsRepository)
    }
}

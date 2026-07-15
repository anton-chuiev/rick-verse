//
//  AppContainer.swift
//  rick-verse
//

import Foundation

/// Composition root. Holds the app's repositories (the domain data boundary)
/// and builds view models from them, so views and coordinators don't wire
/// concrete types themselves. Value type: cheap to pass down the view tree.
struct AppContainer {
    let charactersRepository: CharactersRepository
    let characterDetailRepository: CharacterDetailRepository
    let episodeRepository: EpisodeRepository

    /// The live container: real repositories backed by the Rick and Morty API
    /// over a shared `URLSession` client.
    static let live: AppContainer = {
        let apiClient = URLSessionAPIClient()
        return AppContainer(
            charactersRepository: DefaultCharactersRepository(apiClient: apiClient),
            characterDetailRepository: DefaultCharacterDetailRepository(apiClient: apiClient),
            episodeRepository: DefaultEpisodeRepository(apiClient: apiClient)
        )
    }()

    #if DEBUG
    /// Container for SwiftUI previews: real view models over networkless stub
    /// repositories. Never used in a release build.
    static let preview = AppContainer(
        charactersRepository: PreviewCharactersRepository(),
        characterDetailRepository: PreviewCharacterDetailRepository(),
        episodeRepository: PreviewEpisodeRepository()
    )
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
            fetchEpisodes: DefaultFetchEpisodesUseCase(repository: episodeRepository)
        )
    }
}

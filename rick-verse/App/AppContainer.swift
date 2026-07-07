//
//  AppContainer.swift
//  rick-verse
//

import Foundation

/// Composition root. Holds the app's repositories (the domain data boundary)
/// and builds view models from them, so views and coordinators don't wire
/// concrete types themselves. Value type: cheap to pass down the view tree.
struct AppContainer {
    let characterRepository: CharacterRepository

    /// The live container: real repositories backed by the Rick and Morty API
    /// over a shared `URLSession` client.
    static let live: AppContainer = {
        let apiClient = URLSessionAPIClient()
        return AppContainer(
            characterRepository: DefaultCharacterRepository(apiClient: apiClient)
        )
    }()

    #if DEBUG
    /// Container for SwiftUI previews: real use cases / view models over
    /// networkless stub repositories. Never used in a release build.
    static let preview = AppContainer(
        characterRepository: PreviewCharacterRepository()
    )
    #endif

    @MainActor
    func makeCharactersListViewModel() -> CharactersListViewModel {
        CharactersListViewModel(
            fetchCharacters: DefaultFetchCharactersUseCase(repository: characterRepository)
        )
    }
}

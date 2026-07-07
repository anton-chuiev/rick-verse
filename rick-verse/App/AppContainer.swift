//
//  AppContainer.swift
//  rick-verse
//

import Foundation

/// Composition root. Builds the dependency graph (API client → repository →
/// use case → view model) so views and coordinators don't wire concrete types
/// themselves. Value type: cheap to pass down through the view tree.
struct AppContainer {
    let apiClient: APIClient

    /// The live container backed by the real Rick and Morty API.
    static let live = AppContainer(apiClient: URLSessionAPIClient())

    private var characterRepository: CharacterRepository {
        DefaultCharacterRepository(apiClient: apiClient)
    }

    @MainActor
    func makeCharactersListViewModel() -> CharactersListViewModel {
        CharactersListViewModel(
            fetchCharacters: DefaultFetchCharactersUseCase(repository: characterRepository)
        )
    }
}

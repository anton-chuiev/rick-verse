//
//  FetchCharactersUseCase.swift
//  rick-verse
//

/// Fetches a page of characters for the given search/filter parameters. The
/// view model depends on this protocol, never on the implementation.
protocol FetchCharactersUseCase: Sendable {
    func execute(_ request: CharactersRequest) async throws -> CharactersResponse
}

/// Default implementation. A thin orchestration point over the repository —
/// it exists so the view model has a narrow, mockable seam and so page/search/
/// filter composition has a home as the feature grows.
struct DefaultFetchCharactersUseCase: FetchCharactersUseCase {
    let repository: CharacterRepository

    func execute(_ request: CharactersRequest) async throws -> CharactersResponse {
        try await repository.characters(matching: request)
    }
}

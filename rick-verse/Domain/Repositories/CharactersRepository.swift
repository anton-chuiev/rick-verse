//
//  CharactersRepository.swift
//  rick-verse
//

/// Parameters for a paged characters query. `page` is 1-based; `name` and
/// `status` are optional filters combined by the API.
struct CharactersRequest: Equatable {
    var page: Int = 1
    var name: String?
    var status: RMCharacter.Status?
}

/// One page of characters plus the paging metadata the UI needs to drive
/// infinite scroll and the total-count badge.
struct CharactersResponse: Equatable {
    let characters: [RMCharacter]
    let totalCount: Int
    let hasNextPage: Bool
}

/// Read access to characters. Implemented in the Data layer; consumed by use
/// cases in the Domain layer.
protocol CharactersRepository: Sendable {
    /// Fetches one page of characters matching `request`. A no-results response
    /// (API 404) maps to an empty page, not an error.
    func characters(matching request: CharactersRequest) async throws -> CharactersResponse
}

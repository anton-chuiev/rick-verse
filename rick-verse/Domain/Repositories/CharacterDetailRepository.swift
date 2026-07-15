//
//  CharacterDetailRepository.swift
//  rick-verse
//

/// Identifies the character to fetch for the detail screen. A struct (rather
/// than a bare `Int`) so extra parameters can be added later without breaking
/// the protocol signature.
struct CharacterDetailRequest: Equatable {
    let id: Int
}

/// The character fetched for the detail screen.
struct CharacterDetailResponse: Equatable {
    let character: RMCharacter
}

/// Read access to a single character by ID. Implemented in the Data layer;
/// consumed directly by the detail view model (the fetch is a trivial
/// pass-through, so no use case sits in between — see the Use Case Convention).
///
/// Named `CharacterDetailRepository`, not `CharacterRepository`, to avoid a
/// one-letter difference from the list's `CharactersRepository`.
protocol CharacterDetailRepository: Sendable {
    /// Fetches the character matching `request`. Unlike the list, the API's 404
    /// here means "no such character" and surfaces as a real error.
    func character(matching request: CharacterDetailRequest) async throws -> CharacterDetailResponse
}

//
//  DefaultCharacterRepository.swift
//  rick-verse
//

/// `CharacterRepository` backed by the Rick and Morty API via ``APIClient``.
/// Builds the `/character` endpoint from a `CharactersRequest`, maps DTOs to
/// domain, and turns the API's 404 "no results" into an empty page.
struct DefaultCharacterRepository: CharacterRepository {
    let apiClient: APIClient

    func characters(matching request: CharactersRequest) async throws -> CharactersResponse {
        do {
            let dto: CharactersResponseDTO = try await apiClient.send(CharacterEndpoint.list(request))
            return CharactersResponse(
                characters: dto.results.map { $0.toDomain() },
                totalCount: dto.info.count,
                hasNextPage: dto.info.next != nil
            )
        } catch APIError.notFound {
            // The API returns 404 when no characters match the filters.
            return CharactersResponse(characters: [], totalCount: 0, hasNextPage: false)
        }
    }
}

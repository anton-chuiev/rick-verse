//
//  DefaultCharacterRepository.swift
//  rick-verse
//

/// `CharacterRepository` backed by the Rick and Morty API via ``APIClient``.
/// Builds the `/character` endpoint from a `CharacterQuery`, maps DTOs to
/// domain, and turns the API's 404 "no results" into an empty page.
struct DefaultCharacterRepository: CharacterRepository {
    let apiClient: APIClient

    func characters(matching query: CharacterQuery) async throws -> CharacterPage {
        do {
            let dto: CharacterPageDTO = try await apiClient.send(CharacterEndpoint.list(query))
            return CharacterPage(
                characters: dto.results.map { $0.toDomain() },
                totalCount: dto.info.count,
                hasNextPage: dto.info.next != nil
            )
        } catch APIError.notFound {
            // The API returns 404 when no characters match the filters.
            return CharacterPage(characters: [], totalCount: 0, hasNextPage: false)
        }
    }
}

//
//  DefaultCharacterDetailRepository.swift
//  rick-verse
//

/// `CharacterDetailRepository` backed by the Rick and Morty API via
/// ``APIClient``. Fetches one character by ID and maps the DTO to domain. Unlike
/// the list repository, it does not swallow 404 — an unknown ID is a real error
/// the detail screen surfaces.
struct DefaultCharacterDetailRepository: CharacterDetailRepository {
    let apiClient: APIClient

    func character(matching request: CharacterDetailRequest) async throws -> CharacterDetailResponse {
        let dto: CharacterDTO = try await apiClient.send(CharacterEndpoint.detail(id: request.id))
        return CharacterDetailResponse(character: dto.toDomain())
    }
}

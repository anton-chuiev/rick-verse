//
//  DefaultEpisodesRepository.swift
//  rick-verse
//

/// `EpisodesRepository` backed by the Rick and Morty API via ``APIClient``.
/// Builds the `/episode` list endpoint from an `EpisodesListRequest` and maps
/// DTOs to domain. No 404→empty handling: this feature applies no filters, so
/// the list endpoint always returns results.
struct DefaultEpisodesRepository: EpisodesRepository {
    let apiClient: APIClient

    func episodes(matching request: EpisodesListRequest) async throws -> EpisodesListResponse {
        let dto: EpisodesResponseDTO = try await apiClient.send(EpisodeEndpoint.list(request))
        return EpisodesListResponse(
            episodes: dto.results.map { $0.toDomain() },
            totalCount: dto.info.count,
            hasNextPage: dto.info.next != nil
        )
    }
}

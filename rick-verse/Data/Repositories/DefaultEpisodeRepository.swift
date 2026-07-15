//
//  DefaultEpisodeRepository.swift
//  rick-verse
//

/// `EpisodeRepository` backed by the Rick and Morty API via ``APIClient``.
/// Fetches episodes in one batch and maps DTOs to domain, hiding two API
/// quirks from callers:
///  - an empty `ids` array returns immediately with no network call;
///  - `GET /episode/{id}` returns a single object for one ID but an array for
///    several — `BatchEpisodesDTO` decodes both shapes.
struct DefaultEpisodeRepository: EpisodeRepository {
    let apiClient: APIClient

    func episodes(matching request: EpisodesRequest) async throws -> EpisodesResponse {
        guard !request.ids.isEmpty else {
            return EpisodesResponse(episodes: [])
        }

        let batch: BatchEpisodesDTO = try await apiClient.send(EpisodeEndpoint.batch(ids: request.ids))
        return EpisodesResponse(episodes: batch.episodes.map { $0.toDomain() })
    }
}

/// Decodes the batch episode response, absorbing the API's single-vs-array
/// quirk: with one requested ID the endpoint returns a lone episode object, and
/// with several it returns an array. Tries the array first, then falls back to a
/// single object wrapped into a one-element array.
private struct BatchEpisodesDTO: Decodable {
    let episodes: [EpisodeDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let many = try? container.decode([EpisodeDTO].self) {
            episodes = many
        } else {
            episodes = [try container.decode(EpisodeDTO.self)]
        }
    }
}

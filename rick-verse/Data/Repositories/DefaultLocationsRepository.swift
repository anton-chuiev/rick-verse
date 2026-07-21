//
//  DefaultLocationsRepository.swift
//  rick-verse
//

/// `LocationsRepository` backed by the Rick and Morty API via ``APIClient``.
/// Builds the `/location` endpoint from a `LocationsRequest`, maps DTOs to
/// domain, and turns the API's 404 "no results" into an empty page. This feature
/// applies no filters, so the 404 path won't trigger yet — it's mirrored from
/// `DefaultCharactersRepository` so the future Search & Filter feature inherits
/// the behavior.
struct DefaultLocationsRepository: LocationsRepository {
    let apiClient: APIClient

    func locations(matching request: LocationsRequest) async throws -> LocationsResponse {
        do {
            let dto: LocationsResponseDTO = try await apiClient.send(LocationEndpoint.list(request))
            return LocationsResponse(
                locations: dto.results.map { $0.toDomain() },
                totalCount: dto.info.count,
                hasNextPage: dto.info.next != nil
            )
        } catch APIError.notFound {
            // The API returns 404 when no locations match the filters.
            return LocationsResponse(locations: [], totalCount: 0, hasNextPage: false)
        }
    }
}

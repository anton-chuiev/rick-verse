//
//  LocationDTO.swift
//  rick-verse
//

/// Wire model for a single location, mirroring the Rick and Morty API JSON.
/// `url` and `created` aren't carried into the domain, but are still decoded so
/// decoding stays strict.
struct LocationDTO: Decodable {
    let id: Int
    let name: String
    let type: String
    let dimension: String
    let residents: [String]
    let url: String
    let created: String
}

/// Wire model for a paginated `GET /location` response: `info` + `results`.
/// Reuses `PageInfoDTO` (declared with the character DTOs) — the `info` block is
/// identical across the API's list endpoints.
struct LocationsResponseDTO: Decodable {
    let info: PageInfoDTO
    let results: [LocationDTO]
}

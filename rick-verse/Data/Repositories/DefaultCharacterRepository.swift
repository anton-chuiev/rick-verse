//
//  DefaultCharacterRepository.swift
//  rick-verse
//

import Foundation

/// `CharacterRepository` backed by the Rick and Morty API via ``APIClient``.
/// Builds the `GET /character` request from a `CharacterQuery`, maps DTOs to
/// domain, and turns the API's 404 "no results" into an empty page.
struct DefaultCharacterRepository: CharacterRepository {
    let apiClient: APIClient

    func characters(matching query: CharacterQuery) async throws -> CharacterPage {
        let request = APIRequest(path: "character", queryItems: Self.queryItems(for: query))

        do {
            let dto: CharacterPageDTO = try await apiClient.send(request)
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

    private static func queryItems(for query: CharacterQuery) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "page", value: String(query.page))]

        if let name = query.name, !name.isEmpty {
            items.append(URLQueryItem(name: "name", value: name))
        }
        if let status = query.status {
            items.append(URLQueryItem(name: "status", value: status.apiValue))
        }
        return items
    }
}

private extension RMCharacter.Status {
    /// Lowercase value expected by the API's `status` query param. `.unknown`
    /// maps to `"unknown"`, which the API accepts.
    var apiValue: String {
        switch self {
        case .alive: "alive"
        case .dead: "dead"
        case .unknown: "unknown"
        }
    }
}

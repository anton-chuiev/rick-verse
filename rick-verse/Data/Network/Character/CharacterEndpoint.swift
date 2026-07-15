//
//  CharacterEndpoint.swift
//  rick-verse
//

/// Endpoints under `/character`. Self-describing: each case knows its path and
/// query parameters, so the repository just builds the endpoint and hands it to
/// the `APIClient`.
enum CharacterEndpoint: Endpoint {
    /// `GET /character` — a paged, filtered list.
    case list(CharactersRequest)
    /// `GET /character/{id}` — a single character, no query parameters.
    case detail(id: Int)

    var path: String {
        switch self {
        case .list: "character"
        case let .detail(id): "character/\(id)"
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case let .list(request): CharactersRequestDTO(request)
        case .detail: nil
        }
    }
}

/// Query parameters for `GET /character`, encoded to the API's `page` / `name`
/// / `status` params. `nil` fields drop out during encoding, so absent filters
/// aren't sent. Lives in the Data layer so the domain `CharactersRequest` stays
/// free of networking concerns.
private struct CharactersRequestDTO: Encodable {
    let page: Int
    let name: String?
    let status: String?

    init(_ request: CharactersRequest) {
        self.page = request.page
        self.name = request.name.flatMap { $0.isEmpty ? nil : $0 }
        self.status = request.status?.apiValue
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

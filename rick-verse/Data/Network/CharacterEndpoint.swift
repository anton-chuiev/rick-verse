//
//  CharacterEndpoint.swift
//  rick-verse
//

/// Endpoints under `/character`. Self-describing: each case knows its path and
/// query parameters, so the repository just builds the endpoint and hands it to
/// the `APIClient`.
enum CharacterEndpoint: Endpoint {
    /// `GET /character` — a paged, filtered list.
    case list(CharacterQuery)

    var path: String {
        switch self {
        case .list: "character"
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case let .list(query): CharacterListParameters(query)
        }
    }
}

/// Query parameters for `GET /character`, encoded to the API's `page` / `name`
/// / `status` params. `nil` fields drop out during encoding, so absent filters
/// aren't sent. Lives in the Data layer so the domain `CharacterQuery` stays
/// free of networking concerns.
private struct CharacterListParameters: Encodable {
    let page: Int
    let name: String?
    let status: String?

    init(_ query: CharacterQuery) {
        self.page = query.page
        self.name = query.name.flatMap { $0.isEmpty ? nil : $0 }
        self.status = query.status?.apiValue
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

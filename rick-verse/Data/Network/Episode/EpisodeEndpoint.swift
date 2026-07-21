//
//  EpisodeEndpoint.swift
//  rick-verse
//

/// Endpoints under `/episode`. Self-describing: each case knows its path and
/// query parameters, so the repository just builds the endpoint and hands it to
/// the `APIClient`.
enum EpisodeEndpoint: Endpoint {
    /// `GET /episode` — a paged list of all episodes.
    case list(EpisodesListRequest)
    /// `GET /episode/1,2,3` — several episodes by ID in one request, avoiding an
    /// N+1 fan-out. A character has at most ~51 episodes, which comfortably fits
    /// in a single request, so no chunking is needed.
    ///
    /// Quirk: with two or more IDs the API returns a JSON array, but with exactly
    /// one ID it returns a single object. The repository decodes both shapes.
    case batch(ids: [Int])

    var path: String {
        switch self {
        case .list:
            "episode"
        case let .batch(ids):
            "episode/\(ids.map(String.init).joined(separator: ","))"
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case let .list(request): EpisodesListRequestDTO(request)
        case .batch: nil
        }
    }
}

/// Query parameters for `GET /episode`, encoded to the API's `page` param. Lives
/// in the Data layer so the domain `EpisodesListRequest` stays free of
/// networking concerns.
private struct EpisodesListRequestDTO: Encodable {
    let page: Int

    init(_ request: EpisodesListRequest) {
        self.page = request.page
    }
}

//
//  LocationEndpoint.swift
//  rick-verse
//

/// Endpoints under `/location`. Self-describing: each case knows its path and
/// query parameters, so the repository just builds the endpoint and hands it to
/// the `APIClient`.
enum LocationEndpoint: Endpoint {
    /// `GET /location` — a paged list of all locations.
    case list(LocationsRequest)

    var path: String {
        switch self {
        case .list: "location"
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case let .list(request): LocationsRequestDTO(request)
        }
    }
}

/// Query parameters for `GET /location`, encoded to the API's `page` param.
/// Name / type / dimension filters are added later by Search & Filter. Lives in
/// the Data layer so the domain `LocationsRequest` stays free of networking
/// concerns.
private struct LocationsRequestDTO: Encodable {
    let page: Int

    init(_ request: LocationsRequest) {
        self.page = request.page
    }
}

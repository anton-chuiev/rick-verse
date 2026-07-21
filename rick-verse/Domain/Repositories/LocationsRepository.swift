//
//  LocationsRepository.swift
//  rick-verse
//

/// Parameters for a paged locations query. `page` is 1-based. Name / type /
/// dimension filters are added later by the Search & Filter feature; a struct
/// keeps the protocol signature stable when they arrive.
struct LocationsRequest: Equatable {
    var page: Int = 1
}

/// One page of locations plus the paging metadata the UI needs to drive infinite
/// scroll and the total-count badge.
struct LocationsResponse: Equatable {
    let locations: [Location]
    let totalCount: Int
    let hasNextPage: Bool
}

/// Read access to the paginated `/location` list. Implemented in the Data layer;
/// consumed directly by `LocationsListViewModel` (a page fetch is a single
/// repository call with no orchestration, so no use case sits in between).
protocol LocationsRepository: Sendable {
    /// Fetches one page of locations matching `request`. A no-results response
    /// (API 404) maps to an empty page, not an error.
    func locations(matching request: LocationsRequest) async throws -> LocationsResponse
}

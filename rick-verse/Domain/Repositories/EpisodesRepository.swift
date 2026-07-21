//
//  EpisodesRepository.swift
//  rick-verse
//

/// Parameters for a paged episodes query. `page` is 1-based. Name / episode-code
/// filters are added later by the Search & Filter feature; a struct keeps the
/// protocol signature stable when they arrive.
struct EpisodesListRequest: Equatable {
    var page: Int = 1
}

/// One page of episodes plus the paging metadata the UI needs for the
/// total-count badge and to know whether more pages remain.
struct EpisodesListResponse: Equatable {
    let episodes: [Episode]
    let totalCount: Int
    let hasNextPage: Bool
}

/// Read access to the paginated `/episode` list. Implemented in the Data layer;
/// consumed by `FetchAllEpisodesUseCase`. Distinct from `EpisodeBatchRepository`,
/// which fetches specific episodes by ID.
protocol EpisodesRepository: Sendable {
    /// Fetches one page of episodes matching `request`.
    func episodes(matching request: EpisodesListRequest) async throws -> EpisodesListResponse
}

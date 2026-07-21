//
//  EpisodeBatchRepository.swift
//  rick-verse
//

/// Identifies the episodes to fetch in one batch. A struct (rather than a bare
/// `[Int]`) so extra parameters can be added later without breaking the protocol
/// signature.
struct EpisodeBatchRequest: Equatable {
    let ids: [Int]
}

/// The episodes fetched for a batch request, in the order the API returned them.
struct EpisodeBatchResponse: Equatable {
    let episodes: [Episode]
}

/// Read access to episodes by ID. Implemented in the Data layer; consumed by
/// `FetchEpisodeBatchUseCase`. Distinct from `EpisodesRepository`, which serves
/// the paginated `/episode` list.
protocol EpisodeBatchRepository: Sendable {
    /// Fetches all episodes matching `request` in a single batch call. An empty
    /// `ids` array returns an empty response without hitting the network. The
    /// implementation hides the API's single-vs-array response quirk.
    func episodes(matching request: EpisodeBatchRequest) async throws -> EpisodeBatchResponse
}

//
//  EpisodeRepository.swift
//  rick-verse
//

/// Identifies the episodes to fetch in one batch. A struct (rather than a bare
/// `[Int]`) so extra parameters can be added later without breaking the protocol
/// signature.
struct EpisodesRequest: Equatable {
    let ids: [Int]
}

/// The episodes fetched for a batch request, in the order the API returned them.
struct EpisodesResponse: Equatable {
    let episodes: [Episode]
}

/// Read access to episodes by ID. Implemented in the Data layer; consumed by
/// `FetchEpisodesUseCase`.
protocol EpisodeRepository: Sendable {
    /// Fetches all episodes matching `request` in a single batch call. An empty
    /// `ids` array returns an empty response without hitting the network. The
    /// implementation hides the API's single-vs-array response quirk.
    func episodes(matching request: EpisodesRequest) async throws -> EpisodesResponse
}

//
//  FetchEpisodesUseCase.swift
//  rick-verse
//

/// Fetches the episodes for a set of IDs in one batch. The detail view model
/// depends on this protocol, never on the implementation.
protocol FetchEpisodesUseCase: Sendable {
    func execute(_ request: EpisodesRequest) async throws -> EpisodesResponse
}

/// Default implementation over the `EpisodeRepository`. This is the batch-fetch
/// orchestration the project overview cites as the canonical use-case example:
/// it turns a character's list of episode IDs into a single `/episode/1,2,3`
/// request rather than an N+1 fan-out.
struct DefaultFetchEpisodesUseCase: FetchEpisodesUseCase {
    let repository: EpisodeRepository

    func execute(_ request: EpisodesRequest) async throws -> EpisodesResponse {
        try await repository.episodes(matching: request)
    }
}

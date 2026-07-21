//
//  FetchAllEpisodesUseCase.swift
//  rick-verse
//

/// Fetches every episode across all pages and returns them as one flat list.
/// The Episodes List view model depends on this protocol, never on the
/// implementation.
protocol FetchAllEpisodesUseCase: Sendable {
    func execute() async throws -> [Episode]
}

/// Default implementation over `EpisodesRepository`. Real orchestration (not a
/// pass-through): it walks the API's pages sequentially, accumulating results
/// until no page remains. Sequential rather than parallel — the dataset is tiny
/// (~3 pages) and serial requests sidestep the API's HTTP 429 rate limit.
/// Grouping into seasons is a Presentation concern, so this returns a flat list.
struct DefaultFetchAllEpisodesUseCase: FetchAllEpisodesUseCase {
    let repository: EpisodesRepository

    func execute() async throws -> [Episode] {
        var episodes: [Episode] = []
        var page = 1

        while true {
            let response = try await repository.episodes(matching: EpisodesListRequest(page: page))
            episodes.append(contentsOf: response.episodes)
            guard response.hasNextPage else { break }
            page += 1
        }

        return episodes
    }
}

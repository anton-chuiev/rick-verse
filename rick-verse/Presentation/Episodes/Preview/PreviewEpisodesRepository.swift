//
//  PreviewEpisodesRepository.swift
//  rick-verse
//

#if DEBUG
/// `EpisodesRepository` for SwiftUI previews: serves a fixed set of episodes
/// across two seasons with no network access, paged to exercise the view model's
/// multi-page accumulation. Set `error` to preview the failure state.
struct PreviewEpisodesRepository: EpisodesRepository {
    var episodes: [Episode] = PreviewEpisodesRepository.sample
    var pageSize = 2
    var error: Error?

    func episodes(matching request: EpisodesListRequest) async throws -> EpisodesListResponse {
        if let error { throw error }

        let start = (request.page - 1) * pageSize
        guard start < episodes.count else {
            return EpisodesListResponse(episodes: [], totalCount: episodes.count, hasNextPage: false)
        }
        let end = min(start + pageSize, episodes.count)
        return EpisodesListResponse(
            episodes: Array(episodes[start..<end]),
            totalCount: episodes.count,
            hasNextPage: end < episodes.count
        )
    }
}

extension PreviewEpisodesRepository {
    /// A handful of episodes spanning two seasons, so previews render multiple
    /// season sections.
    static let sample: [Episode] = [
        Episode(id: 1, name: "Pilot", airDate: "December 2, 2013", episodeCode: "S01E01", characterIDs: [1, 2]),
        Episode(id: 2, name: "Lawnmower Dog", airDate: "December 9, 2013", episodeCode: "S01E02", characterIDs: [1, 2]),
        Episode(id: 3, name: "Anatomy Park", airDate: "December 16, 2013", episodeCode: "S01E03", characterIDs: [1]),
        Episode(id: 12, name: "A Rickle in Time", airDate: "July 26, 2015", episodeCode: "S02E01", characterIDs: [1, 2]),
        Episode(id: 13, name: "Mortynight Run", airDate: "August 2, 2015", episodeCode: "S02E02", characterIDs: [1]),
    ]
}
#endif

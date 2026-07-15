//
//  PreviewEpisodeRepository.swift
//  rick-verse
//

#if DEBUG
/// `EpisodeRepository` for SwiftUI previews: serves a fixed set of episodes with
/// no network access, returning those whose IDs the request asks for so the
/// "First seen in" row and episode count stay live. Set `error` to preview the
/// section's failure state.
struct PreviewEpisodeRepository: EpisodeRepository {
    var episodes: [Episode] = PreviewEpisodeRepository.sample
    var error: Error?

    func episodes(matching request: EpisodesRequest) async throws -> EpisodesResponse {
        if let error { throw error }
        guard !request.ids.isEmpty else { return EpisodesResponse(episodes: []) }
        let ids = Set(request.ids)
        return EpisodesResponse(episodes: episodes.filter { ids.contains($0.id) })
    }
}

extension PreviewEpisodeRepository {
    static let sample: [Episode] = [
        Episode(
            id: 1,
            name: "Pilot",
            airDate: "December 2, 2013",
            episodeCode: "S01E01",
            characterIDs: [1, 2]
        ),
        Episode(
            id: 2,
            name: "Lawnmower Dog",
            airDate: "December 9, 2013",
            episodeCode: "S01E02",
            characterIDs: [1, 2]
        ),
        Episode(
            id: 3,
            name: "Anatomy Park",
            airDate: "December 16, 2013",
            episodeCode: "S01E03",
            characterIDs: [1]
        ),
    ]
}
#endif

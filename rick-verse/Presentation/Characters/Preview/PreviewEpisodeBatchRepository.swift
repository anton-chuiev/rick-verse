//
//  PreviewEpisodeBatchRepository.swift
//  rick-verse
//

#if DEBUG
/// `EpisodeBatchRepository` for SwiftUI previews: serves a fixed set of episodes
/// with no network access, returning those whose IDs the request asks for so the
/// "First seen in" row and episode count stay live. Set `error` to preview the
/// section's failure state.
struct PreviewEpisodeBatchRepository: EpisodeBatchRepository {
    var episodes: [Episode] = PreviewEpisodeBatchRepository.sample
    var error: Error?

    func episodes(matching request: EpisodeBatchRequest) async throws -> EpisodeBatchResponse {
        if let error { throw error }
        guard !request.ids.isEmpty else { return EpisodeBatchResponse(episodes: []) }
        let ids = Set(request.ids)
        return EpisodeBatchResponse(episodes: episodes.filter { ids.contains($0.id) })
    }
}

extension PreviewEpisodeBatchRepository {
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

//
//  EpisodeDTO+Mapping.swift
//  rick-verse
//

extension EpisodeDTO {
    /// Maps this wire model to the domain `Episode`. Each `characters` URL's
    /// trailing ID is parsed into `characterIDs`; `airDate` and `episodeCode`
    /// carry over as-is (display strings). `url` and `created` are dropped.
    func toDomain() -> Episode {
        Episode(
            id: id,
            name: name,
            airDate: airDate,
            episodeCode: episodeCode,
            characterIDs: characters.compactMap(Self.trailingID(from:))
        )
    }

    /// Extracts the trailing integer ID from a resource URL such as
    /// `https://rickandmortyapi.com/api/character/42` → `42`.
    private static nonisolated func trailingID(from urlString: String) -> Int? {
        Int(urlString.split(separator: "/").last ?? "")
    }
}

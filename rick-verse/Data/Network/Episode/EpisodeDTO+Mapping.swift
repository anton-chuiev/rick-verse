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
            characterIDs: characters.compactMap(ResourceURL.trailingID(from:))
        )
    }
}

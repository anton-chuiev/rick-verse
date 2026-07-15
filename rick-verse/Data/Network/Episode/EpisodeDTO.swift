//
//  EpisodeDTO.swift
//  rick-verse
//

import Foundation

/// Wire model for a single episode, mirroring the Rick and Morty API JSON.
/// `url` and `created` aren't carried into the domain, but are still decoded so
/// decoding stays strict.
struct EpisodeDTO: Decodable {
    let id: Int
    let name: String
    let airDate: String
    let episodeCode: String
    let characters: [String]
    let url: String
    let created: String

    private enum CodingKeys: String, CodingKey {
        case id, name, characters, url, created
        // The API uses snake_case for these two; map them explicitly rather than
        // switching the whole decoder to a key strategy (the character DTO's
        // keys are already camelCase-clean).
        case airDate = "air_date"
        case episodeCode = "episode"
    }
}

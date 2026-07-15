//
//  CharacterDTO.swift
//  rick-verse
//

import Foundation

/// Wire model for a single character, mirroring the Rick and Morty API JSON.
/// `url` and `created` aren't carried into the domain, but are still decoded so
/// decoding stays strict.
struct CharacterDTO: Decodable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let type: String
    let gender: String
    let origin: LocationRefDTO
    let location: LocationRefDTO
    let image: String
    let episode: [String]
    let url: String
    let created: String
}

/// Wire model for the `origin` / `location` references on a character.
struct LocationRefDTO: Decodable {
    let name: String
    let url: String
}

/// Wire model for the `info` block of a paginated list response.
struct PageInfoDTO: Decodable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

/// Wire model for a paginated `GET /character` response: `info` + `results`.
struct CharactersResponseDTO: Decodable {
    let info: PageInfoDTO
    let results: [CharacterDTO]
}

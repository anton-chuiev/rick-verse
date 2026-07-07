//
//  CharacterDTO+Mapping.swift
//  rick-verse
//

import Foundation

extension CharacterDTO {
    /// Maps this wire model to the domain `RMCharacter`. `status` becomes a
    /// case-insensitive `Status`, `location.name` becomes `locationName`,
    /// `image` becomes `imageURL`, and each `episode` URL's trailing ID is
    /// parsed into `episodeIDs`.
    func toDomain() -> RMCharacter {
        RMCharacter(
            id: id,
            name: name,
            status: RMCharacter.Status(apiValue: status),
            species: species,
            imageURL: URL(string: image),
            episodeIDs: episode.compactMap(Self.trailingID(from:)),
            locationName: location.name
        )
    }

    /// Extracts the trailing integer ID from a resource URL such as
    /// `https://rickandmortyapi.com/api/episode/42` → `42`.
    private static func trailingID(from urlString: String) -> Int? {
        Int(urlString.split(separator: "/").last ?? "")
    }
}

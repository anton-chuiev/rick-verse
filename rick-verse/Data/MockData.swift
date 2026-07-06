import Foundation

struct MockCharacter {
    let id: Int
    let name: String
    let status: String
    let species: String
    let locationName: String
    let imageURL: URL?
}

let mockCharacters: [MockCharacter] = [
    MockCharacter(
        id: 1,
        name: "Rick Sanchez",
        status: "Alive",
        species: "Human",
        locationName: "Citadel of Ricks",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")
    ),
    MockCharacter(
        id: 2,
        name: "Morty Smith",
        status: "Alive",
        species: "Human",
        locationName: "Earth (Replacement Dimension)",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/2.jpeg")
    ),
    MockCharacter(
        id: 3,
        name: "Summer Smith",
        status: "Alive",
        species: "Human",
        locationName: "Earth (Replacement Dimension)",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/3.jpeg")
    ),
    MockCharacter(
        id: 4,
        name: "Beth Smith",
        status: "Alive",
        species: "Human",
        locationName: "Earth (Replacement Dimension)",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/4.jpeg")
    ),
    MockCharacter(
        id: 5,
        name: "Jerry Smith",
        status: "Alive",
        species: "Human",
        locationName: "Earth (Replacement Dimension)",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/5.jpeg")
    ),
    MockCharacter(
        id: 6,
        name: "Abadango Cluster Princess",
        status: "Alive",
        species: "Alien",
        locationName: "Abadango",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/6.jpeg")
    ),
    MockCharacter(
        id: 8,
        name: "Adjudicator Rick",
        status: "Dead",
        species: "Human",
        locationName: "Citadel of Ricks",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/8.jpeg")
    ),
    MockCharacter(
        id: 21,
        name: "Birdperson",
        status: "Dead",
        species: "Alien",
        locationName: "Bird World",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/21.jpeg")
    ),
    MockCharacter(
        id: 45,
        name: "Diphtheria Girl",
        status: "Dead",
        species: "Human",
        locationName: "Earth (C-137)",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/45.jpeg")
    ),
    MockCharacter(
        id: 183,
        name: "Mr. Meeseeks",
        status: "Unknown",
        species: "Human",
        locationName: "unknown",
        imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/183.jpeg")
    ),
]

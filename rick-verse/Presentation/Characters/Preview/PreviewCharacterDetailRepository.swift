//
//  PreviewCharacterDetailRepository.swift
//  rick-verse
//

#if DEBUG
/// `CharacterDetailRepository` for SwiftUI previews: returns a fixed character
/// with no network access. Reuses the list preview's sample data so the same
/// characters appear across screens. Set `error` to preview the failure state.
struct PreviewCharacterDetailRepository: CharacterDetailRepository {
    var character: RMCharacter = PreviewCharactersRepository.sample[0]
    var error: Error?

    func character(matching request: CharacterDetailRequest) async throws -> CharacterDetailResponse {
        if let error { throw error }
        return CharacterDetailResponse(character: character)
    }
}
#endif

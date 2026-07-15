//
//  CharacterDetailViewModel.swift
//  rick-verse
//

import Foundation
import Observation

/// Drives the Character Detail screen. Fetches the character by ID, then loads
/// its episodes independently (progressive loading), so the hero and About card
/// render while the Episodes section is still filling in.
///
/// The character fetch is a direct `CharacterDetailRepository` call — a single
/// call with no orchestration, so per the Use Case Convention no use case sits
/// in between. Episodes go through `FetchEpisodesUseCase` because turning a list
/// of IDs into one batch request is real orchestration.
@Observable
@MainActor
final class CharacterDetailViewModel {
    /// State of the character load, which drives the whole screen (skeleton /
    /// content / error). A 404 here is a real error, unlike the list.
    enum CharacterState: Equatable {
        case loading
        case loaded(RMCharacter)
        case failed
    }

    /// State of the episodes section, loaded independently of the character.
    enum EpisodesState: Equatable {
        case loading
        case loaded([Episode])
        case empty
        case failed
    }

    let characterID: Int
    private(set) var characterState: CharacterState = .loading
    private(set) var episodesState: EpisodesState = .loading

    private let repository: CharacterDetailRepository
    private let fetchEpisodes: FetchEpisodesUseCase

    init(
        characterID: Int,
        repository: CharacterDetailRepository,
        fetchEpisodes: FetchEpisodesUseCase
    ) {
        self.characterID = characterID
        self.repository = repository
        self.fetchEpisodes = fetchEpisodes
    }

    /// The character once loaded, else `nil`. Used by the view for the hero and
    /// About card.
    var character: RMCharacter? {
        if case let .loaded(character) = characterState { return character }
        return nil
    }

    /// Name of the character's first episode, for the About card's "First seen
    /// in" row. `nil` while episodes are still loading or on failure — the row
    /// shows a placeholder until this resolves.
    var firstSeenIn: String? {
        if case let .loaded(episodes) = episodesState { return episodes.first?.name }
        return nil
    }

    /// Loads the character on first appearance. Safe to call on every appear —
    /// it no-ops once a load has started.
    func onAppear() async {
        guard case .loading = characterState else { return }
        await loadCharacter()
    }

    /// Retries the whole screen after a character load failure.
    func retryCharacter() async {
        characterState = .loading
        episodesState = .loading
        await loadCharacter()
    }

    /// Retries just the Episodes section, leaving the hero and About on screen.
    func retryEpisodes() async {
        guard let character else { return }
        episodesState = .loading
        await loadEpisodes(for: character)
    }

    private func loadCharacter() async {
        do {
            let response = try await repository.character(matching: CharacterDetailRequest(id: characterID))
            characterState = .loaded(response.character)
            await loadEpisodes(for: response.character)
        } catch is CancellationError {
            // View went away mid-load; leave state as `.loading` so re-appearing
            // re-triggers the fetch.
        } catch {
            characterState = .failed
        }
    }

    private func loadEpisodes(for character: RMCharacter) async {
        // Defensive: a character with no episodes never hits the network — show
        // the empty section instead of firing an empty batch request.
        guard !character.episodeIDs.isEmpty else {
            episodesState = .empty
            return
        }

        do {
            let response = try await fetchEpisodes.execute(EpisodesRequest(ids: character.episodeIDs))
            episodesState = response.episodes.isEmpty ? .empty : .loaded(response.episodes)
        } catch is CancellationError {
            // View went away mid-load; leave as `.loading`.
        } catch {
            episodesState = .failed
        }
    }
}

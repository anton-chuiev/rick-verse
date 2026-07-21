//
//  CharacterDetailView.swift
//  rick-verse
//

import SwiftUI

/// Character Detail screen: an edge-to-edge hero image with the name and status
/// overlaid, an About card, and an Episodes section. Loads progressively — the
/// hero and About appear as soon as the character arrives, while episodes fill
/// in independently.
struct CharacterDetailView: View {
    @State private var viewModel: CharacterDetailViewModel
    @Environment(FavoritesStore.self) private var favorites

    /// Builds the view once, constructing its view model from the factory. The
    /// `@autoclosure` runs a single time (via `State(wrappedValue:)`) so parent
    /// re-renders don't discard and rebuild the view model mid-load.
    init(viewModel: @autoclosure () -> CharacterDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Interactive only once the character is loaded — there's
                    // nothing to favorite while loading or on failure.
                    if let character = viewModel.character {
                        favoriteButton(character)
                    }
                }
            }
            // The hero image runs under the status bar; a dark scrim sits behind
            // the back button and heart, so prefer light bar content.
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await viewModel.onAppear() }
    }

    /// Toolbar favorite toggle over the hero image. Filled + red when favorited.
    private func favoriteButton(_ character: RMCharacter) -> some View {
        let isFavorite = favorites.isFavorite(id: character.id)
        return Button {
            Task { await favorites.toggle(character) }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? AppColor.statusDead : .white)
                .shadow(radius: 4)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isFavorite ? "Unfavorite \(character.name)" : "Favorite \(character.name)")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.characterState {
        case .loading:
            CharacterDetailSkeleton()
        case let .loaded(character):
            loadedContent(character)
        case .failed:
            CharactersStateView(
                systemImage: "person.fill.questionmark",
                title: "Character not found",
                message: "We couldn't load this character. Please try again.",
                retry: { await viewModel.retryCharacter() }
            )
        }
    }

    private func loadedContent(_ character: RMCharacter) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                CharacterHeroView(character: character)

                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    AboutCard(character: character, firstSeenIn: viewModel.firstSeenIn)
                    episodesSection
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    @ViewBuilder
    private var episodesSection: some View {
        switch viewModel.episodesState {
        case .loading:
            EpisodesSection(title: sectionTitle(count: viewModel.character?.episodeIDs.count)) {
                ForEach(0..<3, id: \.self) { _ in EpisodeRowSkeleton() }
            }
        case let .loaded(episodes):
            EpisodesSection(title: sectionTitle(count: episodes.count)) {
                ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
                    if index > 0 { Divider() }
                    EpisodeRow(episode: episode)
                }
            }
        case .empty:
            EpisodesSection(title: sectionTitle(count: 0)) {
                Text("No episodes for this character.")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppSpacing.s)
            }
        case .failed:
            EpisodesSection(title: sectionTitle(count: viewModel.character?.episodeIDs.count)) {
                VStack(spacing: AppSpacing.s) {
                    Text("Couldn't load episodes.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    Button("Retry") {
                        Task { await viewModel.retryEpisodes() }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColor.statusAlive)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.s)
            }
        }
    }

    private func sectionTitle(count: Int?) -> String {
        if let count { "EPISODES · \(count)" } else { "EPISODES" }
    }
}

#Preview("Loaded") {
    NavigationStack {
        CharacterDetailView(
            viewModel: AppContainer.preview.makeCharacterDetailViewModel(id: 1)
        )
    }
    .environment(AppContainer.preview.favoritesStore)
}

#Preview("Character error") {
    NavigationStack {
        CharacterDetailView(
            viewModel: CharacterDetailViewModel(
                characterID: 1,
                repository: PreviewCharacterDetailRepository(error: APIError.notFound),
                fetchEpisodes: DefaultFetchEpisodeBatchUseCase(repository: PreviewEpisodeBatchRepository())
            )
        )
    }
    .environment(AppContainer.preview.favoritesStore)
}

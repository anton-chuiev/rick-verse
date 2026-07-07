//
//  CharactersListView.swift
//  rick-verse
//

import SwiftUI

/// The Characters list screen: header, search field, status chips, and a
/// scrollable list of character cards with infinite scroll, pull-to-refresh,
/// and skeleton / empty / error states.
struct CharactersListView: View {
    @State private var viewModel: CharactersListViewModel
    /// Called when a card is tapped, with the character's id. The parent
    /// (coordinator-owned) view decides navigation.
    let onSelect: (Int) -> Void

    /// Builds the view once, constructing its view model from the factory. The
    /// `@autoclosure` runs a single time (via `State(wrappedValue:)`) so parent
    /// re-renders don't discard and rebuild the view model.
    init(
        viewModel: @autoclosure () -> CharactersListViewModel,
        onSelect: @escaping (Int) -> Void
    ) {
        _viewModel = State(wrappedValue: viewModel())
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            content
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.onAppear() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RICKVERSE")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(AppColor.statusAlive)
                    Text("Characters")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppColor.textPrimary)
                }
                Spacer()
                totalBadge
            }

            searchField

            StatusFilterChips(selection: $viewModel.statusFilter)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.top, AppSpacing.s)
        .padding(.bottom, AppSpacing.m)
    }

    @ViewBuilder
    private var totalBadge: some View {
        if viewModel.totalCount > 0 {
            Text("\(viewModel.totalCount) total")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.m)
                .padding(.vertical, AppSpacing.s)
                .background(AppColor.cardBackground)
                .clipShape(Capsule())
        }
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.textSecondary)
            TextField("Search characters", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            skeletonList
        case .empty:
            CharactersStateView(
                systemImage: "person.slash",
                title: "No characters found",
                message: "Try a different name or filter.",
                retry: nil
            )
        case .failed:
            CharactersStateView(
                systemImage: "wifi.slash",
                title: "Something went wrong",
                message: "We couldn't load characters.",
                retry: { await viewModel.retry() }
            )
        case .loaded:
            characterList
        }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                ForEach(0..<8, id: \.self) { _ in
                    CharacterCardSkeleton()
                }
            }
            .padding(AppSpacing.m)
        }
        .scrollDisabled(true)
    }

    private var characterList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                ForEach(viewModel.characters) { character in
                    Button {
                        onSelect(character.id)
                    } label: {
                        CharacterCardView(character: character)
                    }
                    .buttonStyle(.plain)
                    .task { await viewModel.onRowAppear(character) }
                }

                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .padding(.vertical, AppSpacing.m)
                }
            }
            .padding(AppSpacing.m)
        }
        .refreshable { await viewModel.reload() }
    }
}

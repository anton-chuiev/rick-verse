//
//  EpisodesListView.swift
//  rick-verse
//

import SwiftUI

/// The Episodes list screen: header with a total-count badge, then all episodes
/// grouped into season sections. Loads everything up front (no infinite scroll),
/// with skeleton / empty / error states and pull-to-refresh.
struct EpisodesListView: View {
    @State private var viewModel: EpisodesListViewModel

    /// Builds the view once, constructing its view model from the factory. The
    /// `@autoclosure` runs a single time (via `State(wrappedValue:)`) so parent
    /// re-renders don't discard and rebuild the view model.
    init(viewModel: @autoclosure () -> EpisodesListViewModel) {
        _viewModel = State(wrappedValue: viewModel())
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RICKVERSE")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(AppColor.statusAlive)
                Text("Episodes")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            totalBadge
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

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            skeletonList
        case .empty:
            CharactersStateView(
                systemImage: "film.stack",
                title: "No episodes found",
                message: "There's nothing to show right now.",
                retry: nil
            )
        case .failed:
            CharactersStateView(
                systemImage: "wifi.slash",
                title: "Something went wrong",
                message: "We couldn't load episodes.",
                retry: { await viewModel.retry() }
            )
        case .loaded:
            episodeList
        }
    }

    private var episodeList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.l, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.sections) { section in
                    Section {
                        VStack(spacing: AppSpacing.s) {
                            ForEach(section.episodes) { episode in
                                EpisodeRowView(episode: episode)
                            }
                        }
                    } header: {
                        sectionHeader(section.title)
                    }
                }
            }
            .padding(AppSpacing.m)
        }
        .refreshable { await viewModel.reload() }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.s)
            .background(AppColor.background)
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.s) {
                ForEach(0..<8, id: \.self) { _ in
                    EpisodeListRowSkeleton()
                }
            }
            .padding(AppSpacing.m)
        }
        .scrollDisabled(true)
    }
}

#if DEBUG
#Preview {
    EpisodesListView(viewModel: AppContainer.preview.makeEpisodesListViewModel())
}
#endif

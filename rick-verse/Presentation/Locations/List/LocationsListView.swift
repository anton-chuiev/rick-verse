//
//  LocationsListView.swift
//  rick-verse
//

import SwiftUI

/// The Locations list screen: header with a total-count badge, then a scrollable
/// list of location cards with infinite scroll, pull-to-refresh, and skeleton /
/// empty / error states.
struct LocationsListView: View {
    @State private var viewModel: LocationsListViewModel

    /// Builds the view once, constructing its view model from the factory. The
    /// `@autoclosure` runs a single time (via `State(wrappedValue:)`) so parent
    /// re-renders don't discard and rebuild the view model.
    init(viewModel: @autoclosure () -> LocationsListViewModel) {
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
                Text("Locations")
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
                systemImage: "mappin.slash",
                title: "No locations found",
                message: "There's nothing to show right now.",
                retry: nil
            )
        case .failed:
            CharactersStateView(
                systemImage: "wifi.slash",
                title: "Something went wrong",
                message: "We couldn't load locations.",
                retry: { await viewModel.retry() }
            )
        case .loaded:
            locationList
        }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                ForEach(0..<8, id: \.self) { _ in
                    LocationRowSkeleton()
                }
            }
            .padding(AppSpacing.m)
        }
        .scrollDisabled(true)
    }

    private var locationList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                ForEach(viewModel.locations) { location in
                    LocationRowView(location: location)
                }

                if viewModel.hasNextPage {
                    // End-of-list sentinel. It sits below the last row, so it
                    // only becomes visible when the user reaches the bottom, and
                    // its `.task` re-runs whenever `paginationToken` changes —
                    // which happens after every load attempt, success or fail.
                    // That makes it self-healing: a failed page (API rate limit)
                    // re-arms the trigger and this still-visible sentinel retries,
                    // instead of stalling until the user scrolls to recreate it.
                    ProgressView()
                        .padding(.vertical, AppSpacing.m)
                        .frame(maxWidth: .infinity)
                        .task(id: viewModel.paginationToken) {
                            await viewModel.loadNextPageIfNeeded()
                        }
                }
            }
            .padding(AppSpacing.m)
        }
        .refreshable { await viewModel.reload() }
    }
}

#if DEBUG
#Preview {
    LocationsListView(viewModel: AppContainer.preview.makeLocationsListViewModel())
}
#endif

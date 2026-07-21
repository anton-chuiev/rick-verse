//
//  FavoritesListView.swift
//  rick-verse
//

import SwiftUI

/// The Favorites screen: header + count badge, and a newest-first list of
/// favorited characters rendered offline from the shared `FavoritesStore`. Rows
/// swipe to remove and tap through to Character Detail.
///
/// No view model: the shared store already owns the list, load, and remove, so
/// the screen is a thin view over it (per the spec).
struct FavoritesListView: View {
    @Environment(FavoritesStore.self) private var favorites
    /// Called when a row is tapped, with the character's id. The tab's
    /// coordinator decides navigation.
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .task { await favorites.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RICKVERSE")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(AppColor.statusAlive)
                Text("Favorites")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            countBadge
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.top, AppSpacing.s)
        .padding(.bottom, AppSpacing.m)
    }

    @ViewBuilder
    private var countBadge: some View {
        if !favorites.favorites.isEmpty {
            Text("\(favorites.favorites.count) saved")
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
        if favorites.favorites.isEmpty {
            CharactersStateView(
                systemImage: "heart.slash",
                title: "No favorites yet",
                message: "Tap the heart on a character to save it here.",
                retry: nil
            )
        } else {
            favoriteList
        }
    }

    /// A `List` (not a `ScrollView`) so rows get native swipe-to-delete via
    /// `.swipeActions`. The default list chrome — separators, row insets, and
    /// backgrounds — is stripped so the cards look the same as on the other
    /// screens; row spacing is recreated with `.listRowInsets`.
    private var favoriteList: some View {
        List {
            ForEach(favorites.favorites) { favorite in
                Button {
                    onSelect(favorite.id)
                } label: {
                    FavoriteRowView(favorite: favorite)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(
                    top: AppSpacing.s, leading: AppSpacing.m,
                    bottom: AppSpacing.s, trailing: AppSpacing.m
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await favorites.remove(id: favorite.id) }
                    } label: {
                        Label("Remove", systemImage: "heart.slash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#if DEBUG
#Preview {
    FavoritesListView(onSelect: { _ in })
        .environment(AppContainer.preview.favoritesStore)
}
#endif

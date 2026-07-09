//
//  StatusFilterChips.swift
//  rick-verse
//

import SwiftUI

/// Horizontal, single-select row of status filter chips (All / Alive / Dead /
/// Unknown). The selected chip fills with the accent color.
struct StatusFilterChips: View {
    @Binding var selection: CharactersListViewModel.StatusFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                ForEach(CharactersListViewModel.StatusFilter.allCases) { filter in
                    chip(for: filter)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(for filter: CharactersListViewModel.StatusFilter) -> some View {
        let isSelected = filter == selection
        return Button {
            selection = filter
        } label: {
            Text(filter.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.m)
                .padding(.vertical, AppSpacing.s)
                .background(isSelected ? AppColor.statusAlive : AppColor.cardBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StatePreview()
}

private struct StatePreview: View {
    @State private var selection: CharactersListViewModel.StatusFilter = .all
    var body: some View {
        StatusFilterChips(selection: $selection)
            .padding()
    }
}

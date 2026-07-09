//
//  CharacterDetailPlaceholderView.swift
//  rick-verse
//

import SwiftUI

/// Temporary Character Detail destination. The real screen (info + episodes)
/// is a separate follow-up feature; for now this confirms the navigation wiring
/// from the list.
struct CharacterDetailPlaceholderView: View {
    let characterID: Int

    var body: some View {
        VStack(spacing: AppSpacing.s) {
            Image(systemName: "person.crop.circle")
                .font(.largeTitle)
                .foregroundStyle(AppColor.textSecondary)
            Text("Character #\(characterID)")
                .font(.title2)
                .foregroundStyle(AppColor.textPrimary)
            Text("Detail screen coming soon")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .navigationTitle("Character")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CharacterDetailPlaceholderView(characterID: 1)
    }
}

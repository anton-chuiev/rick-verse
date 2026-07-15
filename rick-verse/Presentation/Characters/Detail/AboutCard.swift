//
//  AboutCard.swift
//  rick-verse
//

import SwiftUI

/// "About" card: labeled metadata rows for the character. "First seen in" fills
/// in once episodes load — until then (`firstSeenIn == nil`) its value shows a
/// shimmer placeholder.
struct AboutCard: View {
    let character: RMCharacter
    let firstSeenIn: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("ABOUT")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            VStack(spacing: 0) {
                row("Gender", value: character.gender)
                Divider()
                // The API often returns an empty `type`; show a dash instead.
                row("Type", value: character.type.isEmpty ? "—" : character.type)
                Divider()
                row("Origin", value: character.originName)
                Divider()
                row("Last known location", value: character.locationName)
                Divider()
                firstSeenRow
            }
            .padding(AppSpacing.m)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: AppSpacing.m)
            Text(value)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, AppSpacing.s)
    }

    @ViewBuilder
    private var firstSeenRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("First seen in")
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: AppSpacing.m)
            if let firstSeenIn {
                Text(firstSeenIn)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.trailing)
            } else {
                // Episodes still loading — hold the row with a shimmer.
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColor.textSecondary.opacity(0.25))
                    .frame(width: 90, height: 12)
                    .redacted(reason: .placeholder)
                    .shimmer()
            }
        }
        .font(.subheadline)
        .padding(.vertical, AppSpacing.s)
    }
}

#Preview {
    AboutCard(character: PreviewCharactersRepository.sample[0], firstSeenIn: "Pilot")
        .padding()
        .background(AppColor.background)
}

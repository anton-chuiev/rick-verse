//
//  LocationRowView.swift
//  rick-verse
//

import SwiftUI

/// One location row in the Locations list: the location name, a type · dimension
/// subtitle, and a residents count. Text-only — locations have no image.
/// Non-interactive in this phase — Location Detail is a later feature.
struct LocationRowView: View {
    let location: Location

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            residentsBadge
        }
        .padding(AppSpacing.m)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// "Planet · Dimension C-137", with "—" standing in for either field when the
    /// API returns an empty string.
    private var subtitle: String {
        "\(display(location.type)) · \(display(location.dimension))"
    }

    private func display(_ value: String) -> String {
        value.isEmpty ? "—" : value
    }

    @ViewBuilder
    private var residentsBadge: some View {
        if !location.residentIDs.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                Text("\(location.residentIDs.count)")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(AppColor.textSecondary)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: AppSpacing.m) {
        LocationRowView(location: PreviewLocationsRepository.sample[0])
        LocationRowView(location: PreviewLocationsRepository.sample[2])
    }
    .padding()
    .background(AppColor.background)
}
#endif

//
//  CharacterHeroView.swift
//  rick-verse
//

import Kingfisher
import SwiftUI

/// Edge-to-edge square hero image with a bottom gradient scrim and the
/// character's name + status overlaid, readable over any artwork in light or
/// dark mode.
///
/// Behaves as a stretchy header: its resting height is the screen width (a
/// square), but when the surrounding `ScrollView` is pulled down past the top,
/// the image grows to fill the overscroll and stays pinned to the top edge — so
/// no background shows through above it.
struct CharacterHeroView: View {
    let character: RMCharacter

    var body: some View {
        GeometryReader { proxy in
            // `minY` is how far the image's top sits below the scroll edge —
            // positive only while the user overscrolls down. The reader's own
            // width is the resting (square) height.
            let stretch = max(proxy.frame(in: .scrollView).minY, 0)
            let width = proxy.size.width

            image
                .frame(width: width, height: width + stretch)
                // Pin the top: grow downward, then shift up by the same amount.
                .offset(y: -stretch)
        }
        // Reserve the resting square in layout; the reader draws into it and
        // only grows upward-pinned, never pushing the content below down.
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(character.name), \(character.status.title), \(character.species)")
    }

    private var image: some View {
        KFImage(character.imageURL)
            .placeholder {
                Rectangle().fill(AppColor.textSecondary.opacity(0.15))
            }
            .fade(duration: 0.2)
            .resizable()
            .scaledToFill()
            .clipped()
            .overlay(alignment: .bottomLeading) {
                overlay
                    .padding(AppSpacing.m)
            }
            .overlay {
                // Bottom-anchored dark scrim so the overlaid text stays legible.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
    }

    private var overlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(character.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                Circle()
                    .fill(character.status.tint)
                    .frame(width: 9, height: 9)
                Text(character.status.title)
                Text("·")
                Text(character.species)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    ScrollView {
        CharacterHeroView(character: PreviewCharactersRepository.sample[0])
        Color.clear.frame(height: 600)
    }
    .ignoresSafeArea(edges: .top)
}

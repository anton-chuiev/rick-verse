//
//  PlaceholderView.swift
//  rick-verse
//

import SwiftUI

/// Temporary tab content used by the app shell. Shows the tab name as a
/// navigation title until each feature's real screens are built.
struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        PlaceholderView(title: "Characters")
    }
}

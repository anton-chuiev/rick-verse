//
//  Color+Dynamic.swift
//  rick-verse
//

import SwiftUI
import UIKit

extension Color {
    /// Resolves to `light` in light mode and `dark` in dark mode.
    ///
    /// SwiftUI has no built-in light/dark `Color` initializer, so this wraps a
    /// dynamic `UIColor` that reacts to the trait environment.
    init(light: Color, dark: Color) {
        self = Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

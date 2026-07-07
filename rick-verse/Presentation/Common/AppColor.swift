//
//  AppColor.swift
//  rick-verse
//

import SwiftUI

/// Central color palette. Change a color here to change it everywhere.
enum AppColor {
    /// Screen background. Defaults to the system light/dark backgrounds; set a
    /// custom `dark:` value here to override the dark-mode background app-wide.
    static let background = Color(light: .white, dark: .black)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accent = Color.accentColor
}

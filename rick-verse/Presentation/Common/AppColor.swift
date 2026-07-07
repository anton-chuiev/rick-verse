//
//  AppColor.swift
//  rick-verse
//

import SwiftUI

/// Central color palette. Change a color here to change it everywhere.
enum AppColor {
    /// Screen background. Defaults to the system light/dark backgrounds; set a
    /// custom `dark:` value here to override the dark-mode background app-wide.
    static let background = Color(
        light: Color(red: 0.95, green: 0.96, blue: 0.97),
        dark: .black
    )
    /// Background of an elevated card sitting on top of `background`.
    static let cardBackground = Color(
        light: .white,
        dark: Color(red: 0.11, green: 0.12, blue: 0.14)
    )
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accent = Color.accentColor

    // Status colors — mirror the alive/dead/unknown dots in the screenshots.
    static let statusAlive = Color(red: 0.20, green: 0.72, blue: 0.40)
    static let statusDead = Color(red: 0.90, green: 0.25, blue: 0.22)
    static let statusUnknown = Color.gray
}

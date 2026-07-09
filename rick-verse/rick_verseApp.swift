//
//  rick_verseApp.swift
//  rick-verse
//
//  Created by Anton Chuev on 03.07.2026.
//

import SwiftUI

@main
struct rick_verseApp: App {
    init() {
        KingfisherConfig.apply()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
        }
    }
}

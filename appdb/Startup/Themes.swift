//
//  Themes.swift
//  appdb
//
//  Created by ned on 27/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

enum Themes: Int, CaseIterable {

    case light = 0
    case dark = 1
    case darker = 2

    var toString: String {
        switch self {
        case .light: return "Light".localized()
        case .dark: return "Dark".localized()
        case .darker: return "Darker".localized()
        }
    }

    static var current: Themes { Themes(rawValue: ThemeManager.currentThemeIndex)! }

    // MARK: - Switch Theme

    static func switchTo(theme: Themes) {
        if theme != current {
            ThemeManager.setTheme(index: theme.rawValue)
            saveCurrentTheme()
        }
    }

    static var isNight: Bool { current != .light }

    // MARK: - Save & Restore

    static func saveCurrentTheme() {
        Preferences.set(.theme, to: ThemeManager.currentThemeIndex)
    }

    static func restoreLastTheme() {
        if #available(iOS 13.0, *), Preferences.followSystemAppearance {
            if Global.isDarkSystemAppearance {
                switchTo(theme: Preferences.shouldSwitchToDarkerTheme ? .darker : .dark)
            } else {
                switchTo(theme: .light)
            }
        } else {
            guard let theme = Themes(rawValue: Preferences.theme) else { return }
            switchTo(theme: theme)
        }
    }
}

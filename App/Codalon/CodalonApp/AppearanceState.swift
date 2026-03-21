// Issue #213 — Observable appearance state with UserDefaults persistence

import SwiftUI
import HelaiaDesign
import Observation

@MainActor
@Observable
final class AppearanceState {

    // MARK: - Properties

    var colorScheme: ColorScheme? {
        didSet { persistColorScheme() }
    }

    var accentTheme: HelaiaTheme {
        didSet { UserDefaults.standard.set(accentTheme.rawValue, forKey: Keys.accentTheme) }
    }

    var density: HelalaDensity {
        didSet { persistDensity() }
    }

    var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Keys.reduceMotion) }
    }

    var isHighContrast: Bool {
        didSet { UserDefaults.standard.set(isHighContrast, forKey: Keys.highContrast) }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        // Color scheme
        if let raw = defaults.string(forKey: Keys.colorScheme) {
            switch raw {
            case "light": colorScheme = .light
            case "dark": colorScheme = .dark
            default: colorScheme = nil
            }
        } else {
            colorScheme = nil
        }

        // Accent theme
        if let raw = defaults.string(forKey: Keys.accentTheme),
           let theme = HelaiaTheme(rawValue: raw) {
            accentTheme = theme
        } else {
            accentTheme = .sage
        }

        // Density
        if let raw = defaults.string(forKey: Keys.density) {
            switch raw {
            case "compact": density = .compact
            case "comfortable": density = .comfortable
            default: density = .regular
            }
        } else {
            density = .regular
        }

        reduceMotion = defaults.bool(forKey: Keys.reduceMotion)
        isHighContrast = defaults.bool(forKey: Keys.highContrast)
    }

    // MARK: - Derived

    func themeConfig(for colorScheme: ColorScheme) -> HelaiaThemeConfig {
        HelaiaThemeConfig(
            accentColor: accentTheme.color(for: colorScheme),
            colorScheme: self.colorScheme,
            density: density,
            reduceMotion: reduceMotion,
            isHighContrast: isHighContrast
        )
    }

    var themeMode: ThemeMode {
        switch colorScheme {
        case .light: .light
        case .dark: .dark
        case nil: .system
        @unknown default: .system
        }
    }

    /// User-selectable Helaia themes (excludes Codalon context themes).
    static let selectableThemes: [HelaiaTheme] = [
        .sage, .terracotta, .navy, .stone, .olive, .mint, .cyan, .cream
    ]

    // MARK: - Persistence

    private enum Keys {
        static let colorScheme = "codalon.appearance.colorScheme"
        static let accentTheme = "codalon.appearance.accentTheme"
        static let density = "codalon.appearance.density"
        static let reduceMotion = "codalon.appearance.reduceMotion"
        static let highContrast = "codalon.appearance.highContrast"
    }

    private func persistColorScheme() {
        switch colorScheme {
        case .light:
            UserDefaults.standard.set("light", forKey: Keys.colorScheme)
        case .dark:
            UserDefaults.standard.set("dark", forKey: Keys.colorScheme)
        case nil:
            UserDefaults.standard.removeObject(forKey: Keys.colorScheme)
        @unknown default:
            UserDefaults.standard.removeObject(forKey: Keys.colorScheme)
        }
    }

    private func persistDensity() {
        switch density {
        case .compact:
            UserDefaults.standard.set("compact", forKey: Keys.density)
        case .regular:
            UserDefaults.standard.set("regular", forKey: Keys.density)
        case .comfortable:
            UserDefaults.standard.set("comfortable", forKey: Keys.density)
        }
    }
}

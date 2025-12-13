import SwiftUI
import UIKit

struct EmberTheme {
    // MARK: - Colors
    static let primary = Color(red: 0.937, green: 0.392, blue: 0.094) // #EF6418
    static let background = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    // MARK: - Internal helper

    // Try a specific AlbertSans font name; if it fails, fall back to system rounded.
    private static func albert(
        _ name: String,
        size: CGFloat,
        fallbackWeight: Font.Weight
    ) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        } else {
            return .system(size: size, weight: fallbackWeight, design: .rounded)
        }
    }

    // MARK: - Public font helpers

    /// Big titles / page headers
    static func titleFont(_ size: CGFloat = 64) -> Font {
        // SemiBold is usually a nicer display weight than full Bold on TV
        albert("AlbertSans-SemiBold", size: size, fallbackWeight: .semibold)
    }

    /// Section headings / card titles
    static func headingFont(_ size: CGFloat = 36) -> Font {
        albert("AlbertSans-SemiBold", size: size, fallbackWeight: .semibold)
    }

    /// Default body text
    static func bodyFont(_ size: CGFloat = 28) -> Font {
        albert("AlbertSans-Regular", size: size, fallbackWeight: .regular)
    }

    /// Slightly stronger body (for buttons, labels, etc.)
    static func bodySemibold(_ size: CGFloat = 24) -> Font {
        albert("AlbertSans-SemiBold", size: size, fallbackWeight: .semibold)
    }

    /// Small caption text
    static func captionFont(_ size: CGFloat = 18) -> Font {
        albert("AlbertSans-Light", size: size, fallbackWeight: .regular)
    }
}


import SwiftUI

/// Warm Embrace Design System tokens for CrossPromoKit.
/// Provides consistent colors, spacing, and animations across all views.
public enum WarmEmbraceTokens {
    // MARK: - Colors

    /// Warm Coral - Primary accent color
    public static let warmCoral = Color(red: 1.0, green: 0.42, blue: 0.36) // #FF6B5B

    /// Soft Teal - Secondary accent color
    public static let softTeal = Color(red: 0.36, green: 0.75, blue: 0.73) // #5BBFBA

    /// Background color for cards and rows
    public static let cardBackground = Color(.systemBackground)

    /// Secondary background color
    public static let secondaryBackground = Color(.secondarySystemBackground)

    /// Primary text color
    public static let primaryText = Color(.label)

    /// Secondary text color
    public static let secondaryText = Color(.secondaryLabel)

    // MARK: - Spacing

    /// Extra small spacing (4pt)
    public static let spacingXS: CGFloat = 4

    /// Small spacing (8pt)
    public static let spacingS: CGFloat = 8

    /// Medium spacing (12pt)
    public static let spacingM: CGFloat = 12

    /// Large spacing (16pt)
    public static let spacingL: CGFloat = 16

    /// Extra large spacing (24pt)
    public static let spacingXL: CGFloat = 24

    // MARK: - Corner Radius

    /// Small corner radius (8pt)
    public static let cornerRadiusS: CGFloat = 8

    /// Medium corner radius (12pt)
    public static let cornerRadiusM: CGFloat = 12

    /// Large corner radius (16pt)
    public static let cornerRadiusL: CGFloat = 16

    // MARK: - Icon Sizes

    /// App icon size in list rows (48pt)
    public static let appIconSize: CGFloat = 48

    /// Placeholder icon size (24pt)
    public static let placeholderIconSize: CGFloat = 24

    // MARK: - Animations

    /// Standard animation duration
    public static let animationDuration: Double = 0.25

    /// Standard spring animation
    public static var springAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }

    /// Subtle fade animation
    public static var fadeAnimation: Animation {
        .easeInOut(duration: animationDuration)
    }
}

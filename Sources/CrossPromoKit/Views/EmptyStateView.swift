import SwiftUI

/// Reusable empty state view with customizable message and retry action.
/// Used when no apps are available or when loading fails.
public struct EmptyStateView: View {
    private let icon: String
    private let title: String
    private let message: String?
    private let retryTitle: String?
    private let onRetry: (() -> Void)?

    /// Creates an empty state view with customizable content.
    /// - Parameters:
    ///   - icon: SF Symbol name for the icon
    ///   - title: Main title text
    ///   - message: Optional descriptive message
    ///   - retryTitle: Optional retry button title
    ///   - onRetry: Optional retry action closure
    public init(
        icon: String = "app.badge.fill",
        title: String,
        message: String? = nil,
        retryTitle: String? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: WarmEmbraceTokens.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(WarmEmbraceTokens.secondaryText)

            Text(title)
                .font(.headline)
                .foregroundStyle(WarmEmbraceTokens.primaryText)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(WarmEmbraceTokens.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retryTitle, let onRetry {
                Button(retryTitle) {
                    onRetry()
                }
                .buttonStyle(.bordered)
                .tint(WarmEmbraceTokens.warmCoral)
            }
        }
        .padding(.vertical, WarmEmbraceTokens.spacingXL)
        .padding(.horizontal, WarmEmbraceTokens.spacingL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Convenience Initializers

public extension EmptyStateView {
    /// Creates a standard "no apps" empty state for the promo list.
    /// - Parameter onRetry: Action to perform when retry is tapped
    static func noApps(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "app.badge.fill",
            title: L10n.noAppsTitle,
            message: L10n.noAppsMessage,
            retryTitle: L10n.retry,
            onRetry: onRetry
        )
    }

    /// Creates a standard "offline" empty state.
    /// - Parameter onRetry: Action to perform when retry is tapped
    static func offline(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: L10n.offlineTitle,
            message: L10n.offlineMessage,
            retryTitle: L10n.retry,
            onRetry: onRetry
        )
    }
}

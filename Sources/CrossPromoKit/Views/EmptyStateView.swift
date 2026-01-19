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
            title: "앱을 불러올 수 없습니다",
            message: "네트워크 연결을 확인하고 다시 시도해 주세요.",
            retryTitle: "다시 시도",
            onRetry: onRetry
        )
    }

    /// Creates a standard "offline" empty state.
    /// - Parameter onRetry: Action to perform when retry is tapped
    static func offline(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "오프라인 상태입니다",
            message: "인터넷에 연결되면 앱 목록을 불러올 수 있습니다.",
            retryTitle: "다시 시도",
            onRetry: onRetry
        )
    }
}

import SwiftUI

/// A row displaying a single promotable app with icon, name, category, and tagline.
public struct PromoAppRow: View {
    private let app: PromoApp
    private let onTap: () -> Void

    public init(app: PromoApp, onTap: @escaping () -> Void = {}) {
        self.app = app
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: WarmEmbraceTokens.spacingM) {
                AsyncAppIcon(url: app.iconURL)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: WarmEmbraceTokens.spacingXS) {
                    HStack(spacing: WarmEmbraceTokens.spacingS) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(WarmEmbraceTokens.primaryText)

                        Text(app.category)
                            .font(.caption)
                            .foregroundStyle(WarmEmbraceTokens.softTeal)
                            .padding(.horizontal, WarmEmbraceTokens.spacingXS)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(WarmEmbraceTokens.softTeal.opacity(0.15))
                            )
                    }

                    Text(app.tagline.localized)
                        .font(.subheadline)
                        .foregroundStyle(WarmEmbraceTokens.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WarmEmbraceTokens.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, WarmEmbraceTokens.spacingS)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(L10n.promoRowHint)
    }

    /// Single VoiceOver sentence for the whole row: app name, category, tagline.
    ///
    /// Composed explicitly rather than relying on `children: .combine` so the
    /// bare category word ("Finance") is spoken with its meaning ("Finance
    /// category") and the reading order stays fixed regardless of layout.
    private var accessibilityLabel: String {
        L10n.promoRowLabel(
            name: app.name,
            category: app.category,
            tagline: app.tagline.localized
        )
    }
}

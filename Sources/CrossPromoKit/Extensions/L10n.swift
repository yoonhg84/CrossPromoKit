import Foundation

/// Localized UI strings bundled with CrossPromoKit.
///
/// Values are resolved from the package's own `Localizable.xcstrings`
/// (`Bundle.module`) so they stay localized regardless of the host app's bundle.
/// Supported languages: en (source), ko, ja.
enum L10n {
    /// "Try Again" — retry button title.
    static var retry: String { string("common.retry") }

    /// "Cancel" — cancel button title.
    static var cancel: String { string("common.cancel") }

    /// Title shown when the app list could not be loaded.
    static var noAppsTitle: String { string("emptyState.noApps.title") }

    /// Message shown when the app list could not be loaded.
    static var noAppsMessage: String { string("emptyState.noApps.message") }

    /// Title shown when the device is offline.
    static var offlineTitle: String { string("emptyState.offline.title") }

    /// Message shown when the device is offline.
    static var offlineMessage: String { string("emptyState.offline.message") }

    /// Title of the alert shown when the in-app App Store overlay fails to present.
    static var overlayErrorTitle: String { string("overlayError.title") }

    /// Message of the alert shown when the in-app App Store overlay fails to present.
    static var overlayErrorMessage: String { string("overlayError.message") }

    /// Button that opens the App Store app directly.
    static var overlayErrorOpenInAppStore: String { string("overlayError.openInAppStore") }

    /// VoiceOver label for a promo app row, combining name, category and tagline
    /// into one sentence.
    static func promoRowLabel(name: String, category: String, tagline: String) -> String {
        String(format: string("promoRow.accessibilityLabel"), locale: .current, name, category, tagline)
    }

    /// VoiceOver hint describing what activating a promo app row does.
    static var promoRowHint: String { string("promoRow.accessibilityHint") }

    private static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }
}

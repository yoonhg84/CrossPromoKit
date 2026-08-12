import StoreKit
import UIKit

/// Presents and dismisses the App Store overlay for a single app.
///
/// Abstracted behind a protocol so ``PromoService`` can be exercised in tests,
/// where no foreground `UIWindowScene` exists and `SKOverlay` cannot be shown.
@MainActor
protocol AppStoreOverlayPresenting: AnyObject {
    /// Presents an overlay for the given App Store ID.
    /// - Parameter appStoreID: The numeric App Store identifier.
    /// - Returns: `true` when an overlay was presented, `false` when there was
    ///   no foreground window scene to present it in.
    @discardableResult
    func present(appStoreID: String) -> Bool

    /// Dismisses the overlay presented by this presenter, if one is tracked.
    func dismiss()
}

/// The `SKOverlay`-backed presenter used in production.
///
/// Keeps the presented overlay together with the window scene it was presented
/// in, because `SKOverlay.dismiss(in:)` must be called with that same scene.
@MainActor
final class SKOverlayPresenter: AppStoreOverlayPresenting {
    // MARK: - Private Properties

    private var presented: (overlay: SKOverlay, scene: UIWindowScene)?

    // MARK: - Internal Methods

    @discardableResult
    func present(appStoreID: String) -> Bool {
        guard let windowScene = Self.foregroundWindowScene() else { return false }

        let configuration = SKOverlay.AppConfiguration(appIdentifier: appStoreID, position: .bottom)
        let overlay = SKOverlay(configuration: configuration)
        presented = (overlay, windowScene)
        overlay.present(in: windowScene)
        return true
    }

    func dismiss() {
        guard let presented else { return }
        self.presented = nil
        SKOverlay.dismiss(in: presented.scene)
    }

    // MARK: - Private Methods

    private static func foregroundWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

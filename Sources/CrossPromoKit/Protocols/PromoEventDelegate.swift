import Foundation

/// Protocol for receiving analytics events from CrossPromoKit.
/// Host apps implement this to handle impression and tap events.
@MainActor
public protocol PromoEventDelegate: AnyObject, Sendable {
    /// Called when a promo event occurs.
    /// - Parameters:
    ///   - service: The PromoService that emitted the event
    ///   - event: The event that occurred
    func promoService(_ service: PromoService, didEmit event: PromoEvent)
}

import Foundation
import CrossPromoKit

/// Demo implementation of PromoEventDelegate that logs events to console.
@MainActor
final class DemoEventHandler: PromoEventDelegate {
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        switch event {
        case .impression(let appID):
            print("📊 [Demo] Impression: \(appID)")
        case .tap(let appID):
            print("👆 [Demo] Tap: \(appID)")
        }
    }
}

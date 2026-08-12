import CrossPromoKit
import Foundation
import SwiftUI

/// Demo implementation of `PromoEventDelegate` that keeps the events on screen.
///
/// `PromoService` holds its delegate weakly, so this is owned by
/// ``DemoViewModel`` — a value that outlives every view — rather than by the
/// view that passes it in. Recording into an observable list rather than only
/// printing means impressions and taps can be checked on the device, without
/// the Xcode console attached.
@MainActor
@Observable
final class DemoEventHandler: PromoEventDelegate {
    /// One received event, newest first in ``entries``.
    struct Entry: Identifiable {
        enum Kind {
            case impression
            case tap

            /// Localized label for the event kind.
            var label: LocalizedStringResource {
                switch self {
                case .impression: return "Impression"
                case .tap: return "Tap"
                }
            }
        }

        let id = UUID()
        let kind: Kind
        let appID: String
        let time: Date
    }

    /// The most recent events, newest first, capped at ``limit``.
    private(set) var entries: [Entry] = []

    /// How many events are kept; older ones are dropped.
    private let limit = 20

    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        let entry: Entry
        switch event {
        case .impression(let appID):
            print("📊 [Demo] Impression: \(appID)")
            entry = Entry(kind: .impression, appID: appID, time: Date())
        case .tap(let appID):
            print("👆 [Demo] Tap: \(appID)")
            entry = Entry(kind: .tap, appID: appID, time: Date())
        }
        entries.insert(entry, at: 0)
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
    }

    /// Empties the log so the next interaction is unambiguous.
    func clear() {
        entries.removeAll()
    }
}

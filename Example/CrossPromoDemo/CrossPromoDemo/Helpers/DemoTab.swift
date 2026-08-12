import Foundation

/// A tab of the demo.
///
/// Two, since the verification cases moved onto the list screen itself: the
/// screen a check is made on, and the parts drawer those checks are assembled
/// from.
///
/// `-demoTab` takes these raw values. The removed third value, `cases`, no
/// longer parses, which lands a `-demoCase` launch on ``settings`` — the screen
/// that now carries both the list and the case panel, and the only place a case
/// was ever checked.
enum DemoTab: String, Hashable, CaseIterable {
    /// The host app's settings screen: the promo list, and the case panel under it.
    case settings
    /// The individual controls a case composes.
    case debug
}

import Foundation

/// Enumeration for controlling UI state during testing and screenshot capture.
enum DemoState: String, CaseIterable, Identifiable {
    case normal
    case loading
    case empty
    case error

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .loading: return "Loading"
        case .empty: return "Empty"
        case .error: return "Error"
        }
    }

    var description: String {
        switch self {
        case .normal: return "Shows loaded app list"
        case .loading: return "Shows loading indicator"
        case .empty: return "Shows empty state"
        case .error: return "Shows error message"
        }
    }
}

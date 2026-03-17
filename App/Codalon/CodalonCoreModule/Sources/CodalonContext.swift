// Issue #8 — Root shell context definition

import Foundation

public enum CodalonContext: String, Hashable, Sendable, CaseIterable {

    case development
    case release
    case launch

    public var displayName: String {
        switch self {
        case .development: return "Development"
        case .release: return "Release"
        case .launch: return "Launch"
        }
    }

    public var iconName: String {
        switch self {
        case .development: return "hammer.fill"
        case .release: return "shippingbox.fill"
        case .launch: return "antenna.radiowaves.left.and.right"
        }
    }

    public var tintColor: String {
        switch self {
        case .development: return "#4A90D9"
        case .release: return "#E8A020"
        case .launch: return "#2EB87A"
        }
    }
}

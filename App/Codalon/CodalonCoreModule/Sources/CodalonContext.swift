// Issue #8 — Root shell context definition

import Foundation
import HelaiaDesign

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

    public var theme: HelaiaTheme {
        switch self {
        case .development: return .codalonDevelopment
        case .release: return .codalonRelease
        case .launch: return .codalonLaunch
        }
    }
}

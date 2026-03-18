// Issues #8, #184 — Root shell context definition

import Foundation
import HelaiaDesign

public enum CodalonContext: String, Hashable, Sendable, CaseIterable {

    case development
    case release
    case launch
    case maintenance

    public var displayName: String {
        switch self {
        case .development: return "Development"
        case .release: return "Release"
        case .launch: return "Launch"
        case .maintenance: return "Maintenance"
        }
    }

    public var iconName: String {
        switch self {
        case .development: return "hammer.fill"
        case .release: return "shippingbox.fill"
        case .launch: return "antenna.radiowaves.left.and.right"
        case .maintenance: return "wrench.and.screwdriver.fill"
        }
    }

    public var theme: HelaiaTheme {
        switch self {
        case .development: return .codalonDevelopment
        case .release: return .codalonRelease
        case .launch: return .codalonLaunch
        case .maintenance: return .stone
        }
    }
}

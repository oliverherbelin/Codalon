// Issue #39 — Codalon motion rules

import SwiftUI

// MARK: - CodalonAnimation

public enum CodalonAnimation: Sendable {
    public static let contextTransition: Animation = .spring(
        response: 0.45, dampingFraction: 0.82
    )
    public static let cardInteraction: Animation = .spring(
        response: 0.3, dampingFraction: 0.82
    )
    public static let inspectorSlide: Animation = .spring(
        response: 0.32, dampingFraction: 0.82
    )
    public static let proposalPill: Animation = .spring(
        response: 0.35, dampingFraction: 0.78
    )
    public static let sheetPresent: Animation = .spring(
        response: 0.35, dampingFraction: 0.82
    )
    public static let rowCompletion: Animation = .easeIn(
        duration: 0.2
    )
    public static let rowAppearance: Animation = .easeOut(
        duration: 0.18
    )
    public static let ambientCrossFade: Animation = .easeInOut(
        duration: 0.38
    )
    public static let hudShow: Animation = .spring(
        response: 0.22, dampingFraction: 0.9
    )

    public static func animation(
        _ animation: Animation,
        reduceMotion: Bool
    ) -> Animation {
        reduceMotion ? .default : animation
    }
}

// MARK: - CodalonDuration

public enum CodalonDuration: Sendable {
    public static let fast: Double = 0.18
    public static let standard: Double = 0.28
    public static let contextSwitch: Double = 0.38
    public static let proposalAutoDismiss: Double = 8.0
    public static let hudAutoHide: Double = 2.0
}

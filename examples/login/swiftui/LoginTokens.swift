//  LoginTokens.swift
//  Semantic design-token layer for the login example.
//
//  This is the ONLY file permitted to hold raw values. Every line that carries a
//  raw number (or hex) ends with `// ux:ignore` so the token linter treats this
//  file as the single source of truth and flags any literal that leaks into
//  product code. Colors map to Apple's *semantic* system colors, so light /
//  dark / Increase-Contrast resolve automatically (in a shipping app these would
//  be asset-catalog Color sets generated from DTCG tokens).
//
//  Spacing lives on a strict 4 / 8 grid.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum LoginTokens {

    // MARK: Color — semantic roles (auto light / dark / high-contrast)
    // Sourced from platform system colors so light/dark/Increase-Contrast resolve
    // automatically. Cross-platform shim lives in the `Color` extension below.

    static let surface          = Color.uxSurface
    static let surfaceContainer = Color.uxSurfaceContainer
    static let onSurface        = Color.uxOnSurface
    static let onSurfaceMuted   = Color.uxOnSurfaceMuted
    static let outline          = Color.uxOutline
    static let focusRing        = Color.accentColor
    static let actionPrimary    = Color.accentColor
    static let onActionPrimary  = Color.white
    static let statusError      = Color.uxStatusError
    static let statusSuccess    = Color.uxStatusSuccess

    // MARK: Spacing — 4 / 8 grid

    static let s1: CGFloat = 4    // ux:ignore
    static let s2: CGFloat = 8    // ux:ignore
    static let s3: CGFloat = 12   // ux:ignore
    static let s4: CGFloat = 16   // ux:ignore
    static let s6: CGFloat = 24   // ux:ignore
    static let s8: CGFloat = 32   // ux:ignore

    // MARK: Radius

    static let fieldRadius: CGFloat  = 12   // ux:ignore
    static let bannerRadius: CGFloat = 16   // ux:ignore

    // MARK: Size / target — ≥ 48pt hit areas (Apple 44 / Material 48)

    static let buttonMinHeight: CGFloat = 48    // ux:ignore
    static let toggleHitArea: CGFloat   = 48    // ux:ignore
    static let hairline: CGFloat        = 1     // ux:ignore
    static let borderWidth: CGFloat     = 1     // ux:ignore
    static let focusBorderWidth: CGFloat = 2    // ux:ignore
    static let contentMaxWidth: CGFloat = 420   // ux:ignore

    // MARK: Typography — text-style roles that scale with Dynamic Type

    static let titleFont       = Font.largeTitle
    static let subtitleFont    = Font.body
    static let labelFont       = Font.subheadline
    static let fieldFont       = Font.body
    static let buttonLabelFont = Font.headline
    static let calloutFont     = Font.callout
    static let footnoteFont    = Font.footnote

    // MARK: Motion — Reduce-Motion decision lives with the token

    private static let instantDuration: Double = 0.001   // ux:ignore
    private static let effectDuration: Double  = 0.2      // ux:ignore

    /// Opacity / offset reveal. Collapses to ~instant under Reduce Motion.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: effectDuration)
    }

    // MARK: Demo timing (stand-in for a real auth round-trip)

    static let simulatedNetworkDelay: Duration = .seconds(1)   // ux:ignore
}

// MARK: - Cross-platform system colors
// Resolves Apple semantic colors on iOS (UIKit) and macOS (AppKit) so the token
// layer compiles on both SDKs. In a shipping iOS app these map to asset-catalog
// Color sets generated from DTCG tokens.
private extension Color {
    static var uxSurface: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.white
        #endif
    }
    static var uxSurfaceContainer: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color.gray.opacity(0.12)   // ux:ignore
        #endif
    }
    static var uxOnSurface: Color {
        #if canImport(UIKit)
        Color(uiColor: .label)
        #elseif canImport(AppKit)
        Color(nsColor: .labelColor)
        #else
        Color.primary
        #endif
    }
    static var uxOnSurfaceMuted: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondaryLabel)
        #elseif canImport(AppKit)
        Color(nsColor: .secondaryLabelColor)
        #else
        Color.secondary
        #endif
    }
    static var uxOutline: Color {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        Color.gray
        #endif
    }
    static var uxStatusError: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemRed)
        #elseif canImport(AppKit)
        Color(nsColor: .systemRed)
        #else
        Color.red
        #endif
    }
    static var uxStatusSuccess: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGreen)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGreen)
        #else
        Color.green
        #endif
    }
}

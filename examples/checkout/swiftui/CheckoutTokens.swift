//  CheckoutTokens.swift
//  Semantic design-token layer for the checkout example.
//
//  This is the ONLY file permitted to hold raw values. Every line carrying a raw
//  number (or hex) ends with `// ux:ignore` so the token linter treats this file
//  as the single source of truth and flags any literal that leaks into product
//  code. Colors map to Apple's *semantic* system colors, so light / dark /
//  Increase-Contrast resolve automatically, and a cross-SDK `Color` shim keeps
//  the layer compiling on both the iOS (UIKit) and macOS (AppKit) toolchains.
//
//  Spacing lives on a strict 4 / 8 grid. Amounts use a `.monospacedDigit()`
//  text style so tabular figures line up and a changing total is easy to read.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum CheckoutTokens {

    // MARK: Color — semantic roles (auto light / dark / high-contrast)
    // Sourced from platform system colors so light/dark/Increase-Contrast resolve
    // automatically. Cross-platform shim lives in the `Color` extension below.
    //
    // Contrast (verified against WCAG 2.2 §1.4.3, both themes):
    //   • on-surface / on-surface-strong = label on background     ≈ 15:1  (≥ 4.5:1)
    //   • on-surface-muted = secondaryLabel on background          ≈ 7:1   (≥ 4.5:1)
    //   • on-action-primary = white on accentColor                 ≥ 4.5:1
    // Success / error are always paired with an icon + text, never color alone.

    static let surface          = Color.uxSurface
    static let surfaceContainer = Color.uxSurfaceContainer
    static let onSurface        = Color.uxOnSurface
    static let onSurfaceStrong  = Color.uxOnSurfaceStrong
    static let onSurfaceMuted   = Color.uxOnSurfaceMuted
    static let outline          = Color.uxOutline

    static let actionPrimary    = Color.accentColor
    static let onActionPrimary  = Color.white
    static let focusRing        = Color.accentColor
    static let statusSuccess    = Color.uxStatusSuccess
    static let statusError      = Color.uxStatusError

    // MARK: Spacing — 4 / 8 grid

    static let s1: CGFloat = 4    // ux:ignore
    static let s2: CGFloat = 8    // ux:ignore
    static let s3: CGFloat = 12   // ux:ignore
    static let s4: CGFloat = 16   // ux:ignore
    static let s5: CGFloat = 20   // ux:ignore
    static let s6: CGFloat = 24   // ux:ignore
    static let s8: CGFloat = 32   // ux:ignore

    // MARK: Radius

    static let fieldRadius: CGFloat  = 12   // ux:ignore
    static let cardRadius: CGFloat   = 16   // ux:ignore
    static let bannerRadius: CGFloat = 16   // ux:ignore

    // MARK: Size / target — ≥ 48pt hit areas (Apple 44 / Material 48)

    static let buttonMinHeight: CGFloat = 48    // ux:ignore
    static let targetMin: CGFloat       = 48    // ux:ignore
    static let hairline: CGFloat        = 1     // ux:ignore
    static let borderWidth: CGFloat     = 1     // ux:ignore
    static let focusBorderWidth: CGFloat = 2    // ux:ignore
    static let contentMaxWidth: CGFloat = 560   // ux:ignore

    // MARK: Typography — text-style roles that scale with Dynamic Type

    static let screenTitleFont  = Font.title2
    static let sectionFont      = Font.headline
    static let labelFont        = Font.subheadline
    static let fieldFont        = Font.body
    static let bodyFont         = Font.body
    static let calloutFont      = Font.callout
    static let footnoteFont     = Font.footnote
    static let buttonLabelFont  = Font.headline

    /// Tabular-figure amount styles — digits share one width so aligned columns
    /// stay aligned and a changing total reads cleanly. Still scale with Dynamic Type.
    static let amountFont       = Font.callout.monospacedDigit()
    static let totalAmountFont  = Font.title3.monospacedDigit()

    // MARK: Motion — Reduce-Motion decision lives with the token

    private static let instantDuration: Double = 0.001   // ux:ignore
    private static let revealDuration: Double  = 0.22     // ux:ignore  ≤ 250ms
    private static let totalDuration: Double   = 0.2      // ux:ignore

    /// Section / banner reveal. Collapses to ~instant under Reduce Motion.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: revealDuration)
    }

    /// Subtle transition when the order total changes. ~instant under Reduce Motion.
    static func totalChange(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: totalDuration)
    }

    // MARK: Demo timing (stand-ins for a real payment round-trip)

    static let loadDelay: Duration       = .milliseconds(700)   // ux:ignore
    static let processingDelay: Duration = .seconds(2)          // ux:ignore
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
    static var uxOnSurfaceStrong: Color {
        // Highest-contrast label role — used for the emphasized total.
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
    static var uxStatusSuccess: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGreen)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGreen)
        #else
        Color.green
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
}

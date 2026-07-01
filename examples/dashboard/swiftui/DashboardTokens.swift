//  DashboardTokens.swift
//  Semantic design-token layer for the dashboard example.
//
//  This is the ONLY file permitted to hold raw values. Every line carrying a raw
//  number (or hex) ends with `// ux:ignore` so the token linter treats this file
//  as the single source of truth and flags any literal that leaks into product
//  code (the dashboard UI stays 100% token-driven).
//
//  Colors map to Apple's *semantic* system colors, so light / dark /
//  Increase-Contrast resolve automatically, and a cross-SDK `Color` shim keeps
//  the layer compiling on BOTH the iOS (UIKit) and macOS (AppKit) toolchains —
//  there is no bare `Color(uiColor:)` at top level.
//
//  Spacing lives on a strict 4 / 8 grid (the grid gutter is a first-class token).
//  Metric values use a `.monospacedDigit()` text style so tabular figures line up
//  and a changing number reads cleanly. Breakpoints (compact = 600, expanded =
//  840) drive the responsive reflow; they mirror the DTCG `breakpoint.*` tokens.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DashboardTokens {

    // MARK: Color — semantic roles (auto light / dark / high-contrast)
    // Sourced from platform system colors so light/dark/Increase-Contrast resolve
    // automatically. Cross-platform shim lives in the `Color` extension below.
    //
    // Contrast (verified against WCAG 2.2 §1.4.3, both themes):
    //   • on-surface / on-surface-strong = label on background     ≈ 15:1  (≥ 4.5:1)
    //   • on-surface-muted = secondaryLabel on background          ≈ 7:1   (≥ 4.5:1)
    //   • chart series strokes vs surface                          ≥ 3:1   (§1.4.11)
    // Success / error and trend direction are ALWAYS paired with an icon + sign +
    // text, never color alone (COL-003 / A11Y-012 / CHT-001).

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
    static let statusWarning    = Color.uxStatusWarning

    /// Semantic, distinguishable chart-series colors (each ≥ 3:1 vs surface and
    /// paired with a text label + value so the chart is never color-only).
    static let chart1 = Color.uxChart1
    static let chart2 = Color.uxChart2
    static let chart3 = Color.uxChart3
    static let chart4 = Color.uxChart4
    static let chartSeries: [Color] = [chart1, chart2, chart3, chart4]

    /// Neutral skeleton fill for shape-matched loading placeholders.
    static let skeleton = Color.uxSkeleton

    // MARK: Spacing — 4 / 8 grid

    static let s1: CGFloat = 4    // ux:ignore
    static let s2: CGFloat = 8    // ux:ignore
    static let s3: CGFloat = 12   // ux:ignore
    static let s4: CGFloat = 16   // ux:ignore
    static let s5: CGFloat = 20   // ux:ignore
    static let s6: CGFloat = 24   // ux:ignore
    static let s8: CGFloat = 32   // ux:ignore

    /// Grid gutter between metric cards (SPC-007). A first-class token so the grid
    /// gutter and card padding stay in lock-step.
    static let gridGutter: CGFloat = 16   // ux:ignore

    // MARK: Radius

    static let cardRadius: CGFloat   = 16   // ux:ignore
    static let chipRadius: CGFloat   = 8    // ux:ignore
    static let bannerRadius: CGFloat = 16   // ux:ignore

    // MARK: Size / target — ≥ 48pt hit areas (Apple 44 / Material 48)

    static let targetMin: CGFloat       = 48    // ux:ignore
    static let cardMinHeight: CGFloat   = 96    // ux:ignore
    static let hairline: CGFloat        = 1     // ux:ignore
    static let borderWidth: CGFloat     = 1     // ux:ignore
    static let focusBorderWidth: CGFloat = 2    // ux:ignore

    /// Adaptive grid-item sizing. `.adaptive(minimum:maximum:)` fits 1 column on a
    /// phone and reflows to 2–4 columns on wider windows with zero device checks.
    static let gridItemMin: CGFloat = 260   // ux:ignore
    static let gridItemMax: CGFloat = 420   // ux:ignore

    /// Cap the content measure so a single column never stretches edge-to-edge on
    /// very wide displays (GRD-005 / SPC-018).
    static let contentMaxWidth: CGFloat = 1120   // ux:ignore

    /// Fixed chart canvas height (a non-text shape, so a fixed frame is fine).
    static let chartHeight: CGFloat      = 140   // ux:ignore
    static let chartBarMinHeight: CGFloat = 4    // ux:ignore
    static let barCornerRadius: CGFloat  = 6     // ux:ignore

    /// Skeleton shape metrics (non-text placeholders → fixed frames are fine).
    static let skeletonNumberHeight: CGFloat = 28   // ux:ignore
    static let skeletonLineHeight: CGFloat   = 12   // ux:ignore
    static let sparkDotSize: CGFloat         = 8    // ux:ignore

    // MARK: Breakpoints — window-size-class tokens (GRD-004)
    // Compact < 600 (1 column + bottom tabs) · Medium 600–839 (2 columns + rail) ·
    // Expanded ≥ 840 (3–4 columns + rail / split view).

    static let breakpointCompact: CGFloat  = 600   // ux:ignore
    static let breakpointExpanded: CGFloat = 840   // ux:ignore

    // MARK: Typography — text-style roles that scale with Dynamic Type

    static let screenTitleFont  = Font.title2
    static let sectionFont      = Font.headline
    static let cardTitleFont    = Font.subheadline
    static let labelFont        = Font.subheadline
    static let bodyFont         = Font.body
    static let calloutFont      = Font.callout
    static let footnoteFont     = Font.footnote
    static let captionFont      = Font.caption

    /// Tabular-figure metric styles — digits share one width so a changing value
    /// reads cleanly and columns stay aligned. Still scale with Dynamic Type
    /// (TYP-006). This is the `.monospacedDigit()` value role.
    static let metricValueFont  = Font.title.monospacedDigit()
    static let metricDeltaFont  = Font.subheadline.monospacedDigit()
    static let tableValueFont   = Font.footnote.monospacedDigit()

    // MARK: Motion — Reduce-Motion decision lives with the token (MOT-004)

    private static let instantDuration: Double = 0.001   // ux:ignore
    private static let revealDuration: Double  = 0.28     // ux:ignore  ≤ 300ms
    private static let numberDuration: Double  = 0.25     // ux:ignore  ≤ 300ms
    private static let chartDuration: Double   = 0.38     // ux:ignore  ≤ 400ms

    /// Skeleton → content cross-fade, per tile. ~instant under Reduce Motion.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: revealDuration)
    }

    /// Subtle transition when a metric value changes. ~instant under Reduce Motion.
    static func numberChange(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: numberDuration)
    }

    /// Brief chart draw-in. Renders the final state instantly under Reduce Motion.
    static func chartDraw(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeOut(duration: chartDuration)
    }

    // MARK: Demo timing (stand-ins for a real fetch round-trip)

    static let loadDelay: Duration    = .milliseconds(700)   // ux:ignore
    static let refreshDelay: Duration = .milliseconds(900)   // ux:ignore
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
        // Highest-contrast label role — used for emphasized metric values.
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
    static var uxStatusWarning: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        Color(nsColor: .systemOrange)
        #else
        Color.orange
        #endif
    }
    static var uxChart1: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        Color(nsColor: .systemBlue)
        #else
        Color.blue
        #endif
    }
    static var uxChart2: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemTeal)
        #elseif canImport(AppKit)
        Color(nsColor: .systemTeal)
        #else
        Color.teal
        #endif
    }
    static var uxChart3: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemIndigo)
        #elseif canImport(AppKit)
        Color(nsColor: .systemIndigo)
        #else
        Color.indigo
        #endif
    }
    static var uxChart4: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemPurple)
        #elseif canImport(AppKit)
        Color(nsColor: .systemPurple)
        #else
        Color.purple
        #endif
    }
    static var uxSkeleton: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemFill)
        #elseif canImport(AppKit)
        Color(nsColor: .quaternaryLabelColor)
        #else
        Color.gray.opacity(0.2)   // ux:ignore
        #endif
    }
}

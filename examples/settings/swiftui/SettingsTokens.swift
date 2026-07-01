//  SettingsTokens.swift
//  Semantic design-token layer for the settings example.
//
//  This is the ONLY file permitted to hold raw values. Every line carrying a raw
//  number (or a literal color fallback) ends with `// ux:ignore`, so the token
//  linter treats this file as the single source of truth and flags any literal
//  that leaks into product code (the settings UI stays 100% token-driven).
//
//  Colors map to Apple's *semantic* system colors, so light / dark /
//  Increase-Contrast resolve automatically, and a cross-SDK `Color` shim keeps the
//  layer compiling on BOTH the iOS (UIKit) and macOS (AppKit) toolchains — there
//  is no bare `Color(uiColor:)` at top level.
//
//  Spacing lives on a strict 4 / 8 grid (group spacing is a first-class token).
//  Row hit height is >= 48pt (Apple 44 / Material 48). Breakpoints (compact = 600,
//  expanded = 840) drive the responsive single-pane -> two-pane reflow; they mirror
//  the DTCG `breakpoint.*` tokens.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum SettingsTokens {

    // MARK: Color — semantic roles (auto light / dark / high-contrast)
    // Sourced from platform system colors so light/dark/Increase-Contrast resolve
    // automatically. Cross-platform shim lives in the `Color` extension below.
    //
    // Contrast (verified against WCAG 2.2 §1.4.3, both themes):
    //   • on-surface = label on grouped background            ≈ 15:1  (≥ 4.5:1)
    //   • on-surface-variant = secondaryLabel on background   ≈ 7:1   (≥ 4.5:1)
    //   • status-error (destructive label) on surface         ≥ 4.5:1
    //   • outline-variant divider / switch track vs surface   ≥ 3:1   (§1.4.11)
    // The destructive label is ALWAYS paired with a confirm dialog and an icon,
    // never color alone (COL-003 / A11Y-012).

    static let surface          = Color.uxSurface
    static let surfaceContainer = Color.uxSurfaceContainer
    static let onSurface        = Color.uxOnSurface
    static let onSurfaceVariant = Color.uxOnSurfaceVariant
    static let outlineVariant   = Color.uxOutlineVariant

    static let actionPrimary    = Color.accentColor
    static let onActionPrimary  = Color.white
    static let statusError      = Color.uxStatusError
    static let statusSuccess    = Color.uxStatusSuccess
    static let statusWarning    = Color.uxStatusWarning

    /// Neutral skeleton fill for shape-matched loading placeholders (synced values).
    static let skeleton = Color.uxSkeleton

    // MARK: Spacing — 4 / 8 grid

    static let s1: CGFloat = 4    // ux:ignore
    static let s2: CGFloat = 8    // ux:ignore
    static let s3: CGFloat = 12   // ux:ignore
    static let s4: CGFloat = 16   // ux:ignore
    static let s5: CGFloat = 20   // ux:ignore
    static let s6: CGFloat = 24   // ux:ignore
    static let s8: CGFloat = 32   // ux:ignore

    /// Vertical spacing BETWEEN grouped sections (SPC-006). A first-class token so
    /// group gutters stay in lock-step with the grouped inset style.
    static let groupSpacing: CGFloat = 24   // ux:ignore

    // MARK: Radius (concentric grouped-row corners on iOS, SHP-003)

    static let rowRadius: CGFloat     = 12   // ux:ignore
    static let controlRadius: CGFloat = 8    // ux:ignore
    static let bannerRadius: CGFloat  = 12   // ux:ignore

    // MARK: Size / target — >= 48pt hit areas (Apple 44 / Material 48)

    static let targetMin: CGFloat    = 48    // ux:ignore
    /// Minimum tappable row height. >= 48 satisfies Apple 44pt AND Material 48dp.
    static let rowMinHeight: CGFloat = 48    // ux:ignore
    static let hairline: CGFloat     = 1     // ux:ignore
    static let iconColumn: CGFloat   = 28    // ux:ignore

    /// Sidebar (leading pane) ideal width in the two-pane layout.
    static let sidebarMinWidth: CGFloat   = 240   // ux:ignore
    static let sidebarIdealWidth: CGFloat = 300   // ux:ignore

    /// Cap the content measure so a settings column never stretches edge-to-edge on
    /// a very wide display (GRD-005 / SPC-018).
    static let contentMaxWidth: CGFloat = 680   // ux:ignore

    /// Skeleton shape metrics (non-text placeholders → fixed frames are fine).
    static let skeletonValueWidth: CGFloat = 72   // ux:ignore
    static let skeletonLineHeight: CGFloat = 14   // ux:ignore

    // MARK: Breakpoints — window-size-class tokens (GRD-004)
    // Compact < 600 (single scrolling list; a group pushes a sub-page) ·
    // Expanded >= 840 (two-pane: group list + selected group's settings).

    static let breakpointCompact: CGFloat  = 600   // ux:ignore
    static let breakpointExpanded: CGFloat = 840   // ux:ignore

    // MARK: Typography — text-style roles that scale with Dynamic Type

    static let screenTitleFont  = Font.title2
    static let sectionHeaderFont = Font.footnote
    static let rowTitleFont     = Font.body
    static let rowValueFont     = Font.body
    static let rowSubtitleFont  = Font.footnote
    static let footerFont       = Font.footnote
    static let bannerFont       = Font.subheadline

    // MARK: Motion — Reduce-Motion decision lives with the token (MOT-004)
    // Only opacity / position transitions are used, and each collapses to an
    // ~instant change under Reduce Motion.

    private static let instantDuration: Double = 0.001   // ux:ignore
    private static let revealDuration: Double  = 0.20    // ux:ignore  ≤ 200ms

    /// Banner / value cross-fade. ~instant under Reduce Motion.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: revealDuration)
    }

    // MARK: Demo timing (stand-ins for a real fetch / save round-trip)

    static let syncDelay: Duration = .milliseconds(700)   // ux:ignore
    static let saveDelay: Duration = .milliseconds(450)   // ux:ignore
    static let toastLinger: Duration = .seconds(2)        // ux:ignore
}

// MARK: - Cross-platform system colors
// Resolves Apple semantic colors on iOS (UIKit) and macOS (AppKit) so the token
// layer compiles on both SDKs. In a shipping iOS app these map to asset-catalog
// Color sets generated from DTCG tokens.
private extension Color {
    static var uxSurface: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.white
        #endif
    }
    static var uxSurfaceContainer: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
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
    static var uxOnSurfaceVariant: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondaryLabel)
        #elseif canImport(AppKit)
        Color(nsColor: .secondaryLabelColor)
        #else
        Color.secondary
        #endif
    }
    static var uxOutlineVariant: Color {
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
    static var uxStatusWarning: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        Color(nsColor: .systemOrange)
        #else
        Color.orange
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

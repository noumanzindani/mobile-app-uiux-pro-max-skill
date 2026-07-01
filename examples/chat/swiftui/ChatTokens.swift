//  ChatTokens.swift
//  Semantic design-token layer for the chat example.
//
//  This is the ONLY file permitted to hold raw values. Every line carrying a raw
//  number (or hex) ends with `// ux:ignore` so the token linter treats this file
//  as the single source of truth and flags any literal that leaks into product
//  code. Colors map to Apple's *semantic* system colors, so light / dark /
//  Increase-Contrast resolve automatically, and a cross-SDK `Color` shim keeps
//  the layer compiling on both the iOS (UIKit) and macOS (AppKit) toolchains.
//
//  Spacing lives on a strict 4 / 8 grid.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ChatTokens {

    // MARK: Color — semantic roles (auto light / dark / high-contrast)
    // Sourced from platform system colors so light/dark/Increase-Contrast resolve
    // automatically. Cross-platform shim lives in the `Color` extension below.
    //
    // Bubble contrast (verified against WCAG 2.2 §1.4.3, both themes):
    //   • own bubble  = white on systemIndigo  ≈ 5.1:1  (≥ 4.5:1)
    //   • other bubble= label on secondary bg   ≈ 15:1  (≥ 4.5:1)
    // Status text always uses the muted label role (≥ 4.5:1); the semantic
    // info/error tint is applied only to the *icon* (a graphical object, ≥ 3:1),
    // so delivery status is never conveyed by color alone.

    static let surface          = Color.uxSurface
    static let surfaceContainer = Color.uxSurfaceContainer
    static let onSurface        = Color.uxOnSurface
    static let onSurfaceMuted   = Color.uxOnSurfaceMuted
    static let outline          = Color.uxOutline

    static let chatSelfBg    = Color.uxChatSelfBg
    static let onChatSelf    = Color.white
    static let chatOtherBg   = Color.uxSurfaceContainer
    static let onChatOther   = Color.uxOnSurface

    static let actionPrimary   = Color.accentColor
    static let onActionPrimary = Color.white
    static let statusInfo      = Color.uxStatusInfo
    static let statusError     = Color.uxStatusError
    static let statusSuccess   = Color.uxStatusSuccess

    // MARK: Spacing — 4 / 8 grid

    static let s1: CGFloat = 4    // ux:ignore
    static let s2: CGFloat = 8    // ux:ignore
    static let s3: CGFloat = 12   // ux:ignore
    static let s4: CGFloat = 16   // ux:ignore
    static let s5: CGFloat = 20   // ux:ignore
    static let s6: CGFloat = 24   // ux:ignore
    static let s8: CGFloat = 32   // ux:ignore

    // MARK: Radius

    static let bubbleRadius: CGFloat = 18   // ux:ignore
    static let bannerRadius: CGFloat = 12   // ux:ignore

    // MARK: Size / target — ≥ 48pt hit areas (Apple 44 / Material 48)

    static let targetMin: CGFloat        = 48    // ux:ignore
    static let avatarSize: CGFloat       = 36    // ux:ignore
    static let typingDotSize: CGFloat    = 8     // ux:ignore
    static let bubbleGutter: CGFloat     = 48    // ux:ignore  min gap on the opposite edge
    static let bubbleMaxWidth: CGFloat   = 300   // ux:ignore
    static let skeletonWidth: CGFloat    = 220   // ux:ignore
    static let skeletonHeight: CGFloat   = 44    // ux:ignore
    static let hairline: CGFloat         = 1     // ux:ignore

    // MARK: Composer growth bounds (lines, not points)

    static let composerMinLines: Int = 1   // ux:ignore
    static let composerMaxLines: Int = 6   // ux:ignore

    // MARK: Opacity

    static let dotDimOpacity: Double = 0.3   // ux:ignore

    // MARK: Typography — text-style roles that scale with Dynamic Type

    static let navTitleFont      = Font.headline
    static let navSubtitleFont   = Font.caption
    static let bubbleFont        = Font.body
    static let timestampFont     = Font.caption2
    static let statusFont        = Font.caption2
    static let sectionDateFont   = Font.caption
    static let bannerFont        = Font.subheadline
    static let pillFont          = Font.subheadline
    static let composerIconFont  = Font.title2
    static let emptyIconFont     = Font.largeTitle
    static let emptyTitleFont    = Font.title2
    static let emptyBodyFont     = Font.body

    // MARK: Motion — Reduce-Motion decision lives with the token

    private static let instantDuration: Double = 0.001   // ux:ignore
    private static let insertDuration: Double  = 0.22     // ux:ignore  ≤ 250ms
    private static let statusDuration: Double  = 0.14     // ux:ignore  ≤ 150ms
    private static let typingLoopSeconds: Double = 0.6    // ux:ignore
    static let typingStagger: Double            = 0.15    // ux:ignore

    /// Bubble insert / scroll-to-latest reveal. Collapses to ~instant under Reduce Motion.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: insertDuration)
    }

    /// Delivery-status icon cross-fade. Collapses to ~instant under Reduce Motion.
    static func statusChange(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .linear(duration: instantDuration)
            : .easeInOut(duration: statusDuration)
    }

    /// Looping typing dots. `nil` under Reduce Motion so the dots hold still and
    /// the state is exposed as status text instead.
    static func typingLoop(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .easeInOut(duration: typingLoopSeconds).repeatForever(autoreverses: true)
    }

    // MARK: Demo timing (stand-ins for a real transport round-trip)

    static let loadDelay: Duration     = .milliseconds(900)   // ux:ignore
    static let sendStep: Duration      = .milliseconds(700)   // ux:ignore
    static let typingDuration: Duration = .seconds(2)         // ux:ignore
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
    static var uxChatSelfBg: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemIndigo)
        #elseif canImport(AppKit)
        Color(nsColor: .systemIndigo)
        #else
        Color.indigo
        #endif
    }
    static var uxStatusInfo: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        Color(nsColor: .systemBlue)
        #else
        Color.blue
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

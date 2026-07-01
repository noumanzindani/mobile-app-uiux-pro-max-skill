# Platform Conventions (PLAT)

> Pick one paradigm per platform — Apple HIG (iOS 26 Liquid Glass) vs Material 3 Expressive vs deliberate adaptive — and apply the correct navigation, sheets, typography, back behavior, safe areas, and system controls. Never ship a "neither-native" hybrid.

## Table of contents
- Paradigm & navigation — PLAT-001, PLAT-002, PLAT-003, PLAT-004, PLAT-012, PLAT-017
- Visual system — PLAT-005, PLAT-006, PLAT-007, PLAT-008, PLAT-015, PLAT-019
- Controls & interaction — PLAT-009, PLAT-010, PLAT-013, PLAT-016, PLAT-018
- Ergonomics & platform features — PLAT-011, PLAT-014, PLAT-020

---

### PLAT-001 — Choose one paradigm per platform; never mix
- **Rule:** Decide per platform: Apple HIG (iOS 26 Liquid Glass) on iOS, Material 3 Expressive on Android, or a deliberate adaptive strategy — and apply it consistently. Do NOT mix Material components into an iOS build or Cupertino into an Android build within one screen.
- **Why:** "Hybrid-native-to-neither" UI is the #1 tell of AI-generated apps and feels foreign on both platforms.
- **Platforms:** all
- **Severity:** error
- **Check:** `platform_audit` flags cross-paradigm widget usage; manual per-platform review.
- **Exceptions:** A single, intentional cross-platform design system applied uniformly and coherently.
- **See also:** [[PLAT-007]], [[PLAT-009]]

### PLAT-002 — Use the platform navigation model
- **Rule:** Apply the correct navigation pattern: iOS tab bar + navigation stack with large titles; Android bottom navigation / navigation rail (≥ 600dp) with Material top app bar. Respect the ≤ 5 primary destinations guidance.
- **Why:** Users navigate on muscle memory; the wrong nav chrome makes the app feel non-native and harder to use.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual per-platform nav review; `platform_audit` for mismatched nav components.
- **Exceptions:** Adaptive layouts that switch to rail/drawer at larger widths.
- **See also:** [[PLAT-017]], [[NAV-001]]

### PLAT-003 — Respect the system back gesture/button
- **Rule:** Honor platform back: iOS interactive edge-swipe-back on nav stacks; Android system Back gesture/button + predictive back. Never disable or hijack system back; back must go to the previous logical screen.
- **Why:** Breaking back is deeply disorienting and, on Android, violates a core platform contract users rely on constantly.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual back-gesture/button test on every screen; verify predictive back on Android.
- **Exceptions:** Guarded exits (unsaved changes) that confirm rather than silently blocking.
- **See also:** [[PLAT-002]], [[NOTIF-004]]

### PLAT-004 — Use platform sheets and detents correctly
- **Rule:** Use native sheet patterns: iOS sheets with detents + grabber and respect the 34pt home-indicator inset; Material bottom sheets (modal/standard) with correct scrim and drag behavior. Match the platform's sheet dismissal and corner treatment.
- **Why:** Sheets are heavily used; non-native sheet behavior (wrong dismissal, ignored insets) reads as broken.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual sheet review per platform; verify insets and detents.
- **Exceptions:** Custom full-screen covers where a sheet is inappropriate.
- **See also:** [[PLAT-011]], [[BSH-001]]

### PLAT-005 — Apply iOS 26 Liquid Glass materials correctly (with fallback)
- **Rule:** On iOS 26, use Liquid Glass materials only where the system does (navigation/tab bars, controls layer), maintain legibility with vibrancy, and provide an opaque fallback under Reduce Transparency. Do not slather glass over content or reduce text contrast below AA.
- **Why:** Misused translucency harms contrast and battery and misreads Apple's material system.
- **Platforms:** ios
- **Severity:** warning
- **Check:** Manual review of material usage; `contrast_check.py` over glass; Reduce Transparency test.
- **Exceptions:** Pre-iOS 26 targets use the prior material system.
- **See also:** [[A11Y-029]], [[PLAT-019]]

### PLAT-006 — Apply Material 3 Expressive on Android
- **Rule:** On Android use Material 3 Expressive components, shapes, and motion; adopt dynamic color / Material You from the wallpaper where appropriate while keeping brand and contrast intact.
- **Why:** M3 Expressive is the current Android design language; older Material or iOS-styled UI feels dated/foreign on Android.
- **Platforms:** android
- **Severity:** warning
- **Check:** Manual review against M3 Expressive; verify dynamic color handling.
- **Exceptions:** Strong brand systems that intentionally opt out of dynamic color.
- **See also:** [[PLAT-001]], [[COL-004]]

### PLAT-007 — Use platform typography
- **Rule:** Use each platform's system type: San Francisco (SF Pro) + iOS text styles on iOS; Roboto / Material type scale on Android. Match native text hierarchy (e.g., iOS large titles, Material headline/title/body). Don't force one platform's type onto the other.
- **Why:** System fonts and scales are what users expect; foreign typography is an immediate non-native signal.
- **Platforms:** all
- **Severity:** warning
- **Check:** `platform_audit` for font family/scale; manual typography review.
- **Exceptions:** A deliberate brand typeface applied consistently and accessibly.
- **See also:** [[PLAT-001]], [[TYP-001]], [[A11Y-025]]

### PLAT-008 — Use platform iconography
- **Rule:** Use SF Symbols on iOS and Material Symbols on Android (matching weight/optical size to text), rather than mixing icon sets or shipping one platform's icons on the other.
- **Why:** Native icon sets carry platform-consistent metaphors, weights, and accessibility behavior users recognize.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual icon-set review per platform.
- **Exceptions:** Custom brand icons used consistently across the app.
- **See also:** [[ICN-001]], [[L10N-003]]

### PLAT-009 — Platform-correct dialog/alert style and button order
- **Rule:** Alerts/dialogs MUST follow platform conventions: iOS alert with cancel/confirm order and styling per HIG; Material dialog with text buttons bottom-right. Place and label destructive vs default actions per platform.
- **Why:** Swapped button order/style causes users to tap the wrong action, sometimes destructively.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual per-platform dialog review; verify button order/roles.
- **Exceptions:** None.
- **See also:** [[PLAT-001]], [[DLG-001]], [[SET-003]]

### PLAT-010 — Use native pickers and date/time controls
- **Rule:** Use native date/time/selection pickers (iOS wheel/inline/`UIDatePicker`, Android Material date/time pickers) rather than custom-built ones, unless a custom picker is clearly superior and fully accessible.
- **Why:** Native pickers are familiar, accessible, and handle locale/format automatically.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of date/time/selection inputs.
- **Exceptions:** Specialized selection UX that native pickers can't express, built accessibly.
- **See also:** [[L10N-008]], [[FRM-003]]

### PLAT-011 — Respect safe areas and system insets
- **Rule:** All content MUST respect safe areas/insets — notch/Dynamic Island, status bar, 34pt home indicator, Android gesture-nav insets, and the IME/keyboard — using safe-area primitives (`SafeArea`, `safeAreaInsets`, `WindowInsets`), never hardcoded padding.
- **Why:** Content under the notch, behind the home indicator, or hidden by the keyboard is unusable and looks broken.
- **Platforms:** all
- **Severity:** error
- **Check:** `platform_audit` for hardcoded status-bar/home-indicator padding; manual notch + keyboard test.
- **Exceptions:** Intentional full-bleed media that still keeps controls within safe areas.
- **See also:** [[PLAT-017]], [[A11Y-032]], [[FRM-008]]

### PLAT-012 — Use the native share/action mechanism
- **Rule:** Sharing MUST use the native share sheet (iOS `UIActivityViewController` / Android `ACTION_SEND` / share intent), not a custom in-app list of hardcoded targets.
- **Why:** The native sheet respects user-installed apps, ordering, and privacy, and is what users expect.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of share entry points for native sheet usage.
- **Exceptions:** In-app-only sharing (e.g., to a contact within the app).
- **See also:** [[PLAT-001]]

### PLAT-013 — Use platform haptic APIs and semantics
- **Rule:** Haptics MUST use platform APIs with correct semantics — iOS feedback generators (impact/notification/selection); Android `HapticFeedbackConstants`/`VibrationEffect` with meaningful patterns — matched to the event type, and never the sole feedback.
- **Why:** Semantically-correct, platform-native haptics feel right; arbitrary vibration feels cheap and drains battery.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review haptic calls for platform API + semantic mapping.
- **Exceptions:** None where haptics are used.
- **See also:** [[HAP-001]], [[A11Y-031]]

### PLAT-014 — Place primary actions in the thumb zone
- **Rule:** Primary and frequent actions MUST sit within the bottom reachable thumb zone (bottom bar, bottom-anchored CTA/FAB); avoid placing critical or frequent actions only in hard-to-reach top corners on tall phones.
- **Why:** One-handed use dominates mobile; top-corner-only primary actions are physically awkward and slow.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual reachability review on a large device; `platform_audit` flags primary CTAs only in top corners.
- **Exceptions:** Rare/destructive actions intentionally placed out of the easy-tap zone.
- **See also:** [[A11Y-010]], [[BTN-001]]

### PLAT-015 — Use platform-native control styles
- **Rule:** Toggles, switches, checkboxes, radios, sliders, and steppers MUST use the platform's native style/behavior (iOS switch vs Material switch/checkbox) rather than one platform's controls on the other.
- **Why:** Control appearance signals platform and affordance; mismatched controls confuse and look non-native.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual per-platform control review.
- **Exceptions:** A unified brand control system applied consistently and accessibly.
- **See also:** [[PLAT-001]], [[A11Y-013]]

### PLAT-016 — Match platform scroll physics and pull-to-refresh
- **Rule:** Use platform scroll physics and refresh affordances — iOS rubber-band bounce + iOS refresh control; Android overscroll stretch + Material `SwipeRefresh`. Don't force iOS bounce on Android or vice versa.
- **Why:** Scroll feel is a subconscious platform cue; wrong physics immediately feels off.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Manual scroll/refresh feel test per platform.
- **Exceptions:** Cross-platform frameworks that adapt physics automatically per OS.
- **See also:** [[PLAT-002]], [[LST-004]]

### PLAT-017 — Support edge-to-edge, window size classes & foldables
- **Rule:** Layouts MUST go edge-to-edge with inset handling and adapt across window size classes (compact/medium/expanded, Android 16), including tablets and foldables — single-column compact, two-pane/list-detail at ≥ 600–840dp — not just a stretched phone layout.
- **Why:** Large screens and foldables are common; non-adaptive layouts waste space and look unpolished.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual test across phone/tablet/foldable and both orientations; `platform_audit` for adaptive breakpoints.
- **Exceptions:** Phone-only apps (declared), still handling rotation.
- **See also:** [[PLAT-011]], [[GRD-002]], [[A11Y-040]]

### PLAT-018 — Use native text editing, selection & keyboard toolbar
- **Rule:** Text inputs MUST use native text editing — selection handles, context menu (copy/paste/lookup), autofill, spellcheck, and the correct keyboard type/return key per field — rather than reimplementing these.
- **Why:** Reinvented text editing loses autofill, accessibility, and platform muscle memory, and usually breaks paste ([[A11Y-036]]).
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: selection, paste, autofill, and keyboard type on each field.
- **Exceptions:** Specialized editors (code/rich text) that still preserve core selection/paste/a11y.
- **See also:** [[A11Y-036]], [[FRM-002]]

### PLAT-019 — Match system bar styling to content
- **Rule:** Status bar and navigation-bar icon/color styling MUST match the underlying content and theme (light icons on dark content, dark on light), edge-to-edge, with no clashing opaque bars.
- **Why:** Mismatched or invisible system-bar icons look unfinished and can hide important indicators.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of system bars across screens and themes.
- **Exceptions:** Immersive modes that hide system bars.
- **See also:** [[DRK-010]], [[PLAT-011]]

### PLAT-020 — Don't reimplement OS-provided capabilities
- **Rule:** Do not rebuild features the OS already provides — autofill, password/passkey managers, spellcheck, text magnifier, Dynamic Type/font scaling, share sheet, system pickers; integrate with them instead.
- **Why:** Reinventing OS features almost always regresses accessibility, security, and familiarity, and adds maintenance cost.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review for custom reimplementations of OS capabilities.
- **Exceptions:** Cases where the OS feature genuinely cannot meet a documented need, implemented accessibly.
- **See also:** [[A11Y-036]], [[PLAT-018]], [[PLAT-012]]

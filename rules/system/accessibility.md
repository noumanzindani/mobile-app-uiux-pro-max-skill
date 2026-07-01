# Accessibility (A11Y)

> Enforce WCAG 2.2 AA + platform accessibility APIs (VoiceOver / TalkBack / Dynamic Type) on every screen. **Audit against WCAG 2.2 now**; APCA / WCAG 3.0 remain informational only (WCAG 3.0 is not expected as a Recommendation before ~2030) — do not gate on them.

This is the flagship rule pack. Accessibility is a **default, not an afterthought** (Blueprint goal G1: 100% of generated screens pass the bundled WCAG 2.2 AA validator suite). Every interactive element carries a name, role/trait, and value/state; contrast and target sizes meet floors; text reflows under Dynamic Type; and system accessibility preferences are honored.

## Table of contents
- [Contrast & color](#contrast--color) — A11Y-001…006
- [Touch targets & spacing](#touch-targets--spacing) — A11Y-007…010
- [Screen-reader semantics](#screen-reader-semantics) — A11Y-011…023
- [Dynamic Type & reflow](#dynamic-type--reflow) — A11Y-024…027
- [System accessibility settings](#system-accessibility-settings) — A11Y-028…031
- [WCAG 2.2 new criteria & input methods](#wcag-22-new-criteria--input-methods) — A11Y-032…040

---

## Contrast & color

### A11Y-001 — Body text contrast ≥ 4.5:1
- **Rule:** All text below the large-text threshold MUST have a contrast ratio ≥ 4.5:1 against its background (WCAG 2.2 SC 1.4.3, AA). Verify per theme (light AND dark) and over the actual rendered background (gradients/images use the least-contrasting pixel or add a scrim).
- **Why:** Sub-4.5:1 text is unreadable for low-vision users and in bright sunlight — the single most common mobile a11y failure.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` computes WCAG ratios from resolved token pairs per theme; manual spot-check text over imagery.
- **Exceptions:** Disabled controls, pure decoration, and incidental/logotype text are exempt (1.4.3).
- **See also:** [[A11Y-002]], [[A11Y-003]], [[DRK-004]], [[COL-006]]

### A11Y-002 — Large-text contrast ≥ 3:1
- **Rule:** Large text MAY use ≥ 3:1 contrast (1.4.3). "Large" = ≥ 18pt/24px regular OR ≥ 14pt/18.66px bold. Do not apply the 3:1 allowance to any smaller size.
- **Why:** Larger glyphs remain legible at lower contrast; this is the only relaxation WCAG grants for text.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` classifies each text token by size/weight, then applies the correct threshold.
- **Exceptions:** Same as [[A11Y-001]].
- **See also:** [[A11Y-001]], [[TYP-002]]

### A11Y-003 — Non-text & UI-component contrast ≥ 3:1
- **Rule:** Meaningful icons, input borders, control boundaries, toggle states, focus indicators, chart strokes, and graphical objects needed to understand content MUST have ≥ 3:1 contrast against adjacent colors (SC 1.4.11, AA).
- **Why:** Users must be able to perceive that a control exists and its state (checked, selected, focused) without relying on subtle color.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` on component/state tokens (border, icon, indicator); manual for custom-drawn graphics.
- **Exceptions:** Inactive/disabled components, and elements whose appearance is defined purely by the OS.
- **See also:** [[A11Y-004]], [[A11Y-006]], [[CHT-002]], [[FRM-004]]

### A11Y-004 — Visible focus indicator (contrast + area)
- **Rule:** Every focusable control MUST show a visible focus indicator with ≥ 3:1 contrast against both the component and the background, a minimum thickness of 2px (target the SC 2.4.13 AAA area: ≥ 2px perimeter or an equivalent enclosed area). Never remove the platform default without a compliant replacement.
- **Why:** Keyboard, switch-control, and external-keyboard users navigate entirely by the focus ring; an invisible ring makes the app unusable for them.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual keyboard/switch sweep; `contrast_check.py` on the focus-ring token.
- **Exceptions:** None for interactive controls.
- **See also:** [[A11Y-032]], [[A11Y-003]], [[MOT-010]]

### A11Y-005 — Prefer AAA 7:1 for critical & long-form text
- **Rule:** For primary body copy, financial figures, medical dosages, and error text, aim for ≥ 7:1 (large text ≥ 4.5:1) — the WCAG 1.4.6 AAA target.
- **Why:** AAA contrast markedly improves comfort for low-vision users and readability in glare; cheap insurance on high-stakes content.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `contrast_check.py --aaa` reports which text tokens clear 7:1.
- **Exceptions:** Secondary/tertiary text where AA is met and hierarchy requires lower emphasis.
- **See also:** [[A11Y-001]]

### A11Y-006 — Color is never the only signal (1.4.1)
- **Rule:** Never encode meaning with color alone. Errors, required fields, selected/active states, chart series, and status MUST also carry a non-color cue: icon, text label, shape, pattern, underline, or weight.
- **Why:** ~1 in 12 men has color-vision deficiency; color-only cues vanish for them and under grayscale/high-contrast modes.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual grayscale render; `semantics_lint.py` flags status set only via a color token.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[CHP-002]], [[CHT-001]], [[FRM-004]]

---

## Touch targets & spacing

### A11Y-007 — Minimum target size 24×24 CSS px (2.5.8 AA)
- **Rule:** Every pointer target MUST be ≥ 24×24 CSS px (SC 2.5.8, new in WCAG 2.2, AA), OR meet the spacing exception in [[A11Y-009]]. This is the absolute floor before platform floors apply.
- **Why:** Targets under 24px produce mis-taps and frustration, especially for users with motor or dexterity impairments.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size.py` measures rendered hit rects.
- **Exceptions:** Inline text links; targets constrained by the sentence flow; OS-provided controls; equivalent target available elsewhere.
- **See also:** [[A11Y-008]], [[A11Y-009]], [[ICN-004]]

### A11Y-008 — Platform target floors: 44pt (iOS) / 48dp (Android)
- **Rule:** Interactive controls MUST meet the stricter platform floor: ≥ 44×44pt on iOS (Apple HIG) and ≥ 48×48dp on Android (Material). Expand the hit area (padding / larger hitSlop / `minimumInteractiveComponentSize`) when the visual glyph is smaller.
- **Why:** Apple and Google set these floors from ergonomic research; they exceed the WCAG minimum and are what reviewers expect.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size.py --platform`; manual review of icon buttons.
- **Exceptions:** Purely decorative or non-interactive elements.
- **See also:** [[A11Y-007]], [[A11Y-010]], [[ICN-004]], [[BTN-003]]

### A11Y-009 — ≥ 8dp spacing (or 24px offset) between adjacent targets
- **Rule:** Adjacent touch targets MUST be separated by ≥ 8dp; where a target is smaller than 24×24, a 24px-diameter circle centered on it MUST NOT overlap another target's circle (the SC 2.5.8 spacing exception).
- **Why:** Crowded targets cause accidental activation; spacing satisfies the spec even when a glyph is small.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size.py` computes inter-target gaps and 24px-circle overlap.
- **Exceptions:** None where both are activatable.
- **See also:** [[A11Y-007]], [[A11Y-008]], [[SPC-001]]

### A11Y-010 — Prefer AAA target size 44×44 for primary actions
- **Rule:** For primary CTAs, destructive actions, and one-handed-reach controls, target ≥ 44×44 CSS px (SC 2.5.5 AAA) with ≥ 8dp spacing.
- **Why:** Larger targets cut error rates on the highest-consequence actions and improve thumb-zone reach.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `target_size.py --aaa`.
- **Exceptions:** Dense data tables/toolbars where AA + spacing is met.
- **See also:** [[A11Y-008]], [[PLAT-014]]

---

## Screen-reader semantics

### A11Y-011 — Every interactive element has an accessible name
- **Rule:** Buttons, links, inputs, toggles, tabs, and custom controls MUST expose a concise, meaningful accessible name (iOS `accessibilityLabel` / SwiftUI `.accessibilityLabel`; Android `contentDescription` / Compose `contentDescription`; Flutter `Semantics(label:)`; RN `accessibilityLabel`). Form fields also expose their visible label programmatically (SC 3.3.2, 4.1.2). Names describe purpose, not appearance ("Add to cart", not "green button").
- **Why:** Screen-reader users hear only the accessible name; unlabeled controls are announced as "button" or skipped entirely.
- **Platforms:** all
- **Severity:** error
- **Check:** `semantics_lint.py` flags interactive nodes without a name; manual VoiceOver/TalkBack sweep.
- **Exceptions:** None for interactive elements. Purely decorative elements MUST instead be hidden ([[A11Y-022]]).
- **See also:** [[A11Y-012]], [[A11Y-013]], [[A11Y-023]]

### A11Y-012 — Expose the correct role / trait
- **Rule:** Each control MUST expose its role/trait so assistive tech announces what it is and how to operate it (iOS traits `.button`/`.link`/`.header`/`.adjustable`/`.selected`; Android/Compose `Role`; Flutter semantic flags; RN `accessibilityRole`). Never fake a button with a plain tappable `Text`/`View` lacking a button role.
- **Why:** Role drives the interaction model ("double-tap to activate", "swipe up/down to adjust") and how the element is found in the rotor/menu.
- **Platforms:** all
- **Severity:** error
- **Check:** `semantics_lint.py` verifies role presence on custom controls; manual rotor test.
- **Exceptions:** Native controls that carry roles automatically.
- **See also:** [[A11Y-011]], [[A11Y-018]], [[PRG-004]]

### A11Y-013 — Expose value & state (selected, checked, expanded, disabled)
- **Rule:** Stateful controls MUST expose current value and state programmatically and update it on change: selected/checked (toggles, tabs, chips), expanded/collapsed (accordions, disclosure), disabled, busy, and slider/stepper values. Do not rely on visual styling alone.
- **Why:** Without exposed state a screen-reader user cannot tell whether a toggle is on, a tab is selected, or a section is expanded.
- **Platforms:** all
- **Severity:** error
- **Check:** `semantics_lint.py`; manual TalkBack/VoiceOver toggle sweep.
- **Exceptions:** None for stateful controls.
- **See also:** [[A11Y-006]], [[A11Y-019]], [[CHP-002]], [[PRG-004]]

### A11Y-014 — Hints only when behavior is non-obvious
- **Rule:** Provide an accessibility hint only to clarify a non-obvious outcome (e.g., "Double-tap and hold, then drag to reorder"). Do NOT restate the label, and never place essential information in a hint (hints can be disabled by the user and are read last).
- **Why:** Redundant or verbose hints slow every interaction and bury the actual label.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review; `semantics_lint.py` flags hints that duplicate the label.
- **Exceptions:** Complex gestures/custom actions where discovery is otherwise impossible.
- **See also:** [[A11Y-011]], [[A11Y-015]]

### A11Y-015 — Announcement order: label → value → trait → hint
- **Rule:** Compose semantics so VoiceOver reads in the order label → value → trait/role → hint. Keep labels free of role words ("Submit", not "Submit button" — the trait already says "button").
- **Why:** A consistent, non-redundant reading order makes controls fast to parse and prevents doubled words like "button button".
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual VoiceOver listen-through of key screens.
- **Exceptions:** None.
- **See also:** [[A11Y-011]], [[A11Y-014]]

### A11Y-016 — Group related text into a single accessible element
- **Rule:** Group logically related text (a list-row title + subtitle + metadata, a card's heading + body) into one accessible element so it is announced as one coherent phrase, with child controls still individually reachable (iOS `accessibilityElement(children:.combine)` / `shouldGroupAccessibilityChildren`; Android focusable group / `mergeDescendants`; Flutter `MergeSemantics`).
- **Why:** Ungrouped fragments force users to swipe through each snippet separately, losing the relationship between them.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual swipe-navigation review of lists/cards.
- **Exceptions:** When each fragment is independently actionable and must be separately focusable.
- **See also:** [[A11Y-017]], [[LST-002]], [[CRD-001]]

### A11Y-017 — Reading & focus order matches visual order (mirrored in RTL)
- **Rule:** The accessibility focus/reading order MUST follow the visual reading order (top→bottom, leading→trailing) and MUST mirror for RTL locales. Fix any DOM/layer order that diverges from the visual layout.
- **Why:** A jumbled focus order disorients screen-reader users and breaks comprehension, especially after custom layouts or overlays.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual swipe-through in an LTR and an RTL locale.
- **Exceptions:** Deliberate reordering that also matches the intended reading order.
- **See also:** [[A11Y-020]], [[L10N-002]], [[L10N-003]]

### A11Y-018 — Expose heading semantics & structure
- **Rule:** Section titles and screen headings MUST carry the heading trait (iOS `.header` / `accessibilityAddTraits(.isHeader)`; Android `heading = true`; Flutter `Semantics(header: true)`; RN `accessibilityRole="header"`) so users can navigate by heading via the rotor/menu.
- **Why:** Headings are the primary way screen-reader users skim and jump within a screen; without them the whole screen is one flat list.
- **Platforms:** all
- **Severity:** warning
- **Check:** `semantics_lint.py`; manual rotor "Headings" navigation.
- **Exceptions:** Screens with no sectioning.
- **See also:** [[A11Y-012]], [[TYP-005]]

### A11Y-019 — Announce dynamic changes via live regions (4.1.3)
- **Rule:** Content that changes without moving focus — toast/snackbar, inline validation, cart badge count, loading→loaded, search-result count — MUST be announced (iOS `UIAccessibility.post(notification:.announcement/.layoutChanged)`; Android `announceForAccessibility` / `accessibilityLiveRegion`; Flutter `SemanticsService.announce`; RN `AccessibilityInfo.announceForAccessibility`). Status messages (SC 4.1.3) MUST announce without stealing focus.
- **Why:** Screen-reader users get no signal about silent updates; important status must be spoken.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual VoiceOver/TalkBack test of async updates; `semantics_lint.py` flags snackbars/toasts lacking live-region config.
- **Exceptions:** Purely cosmetic changes.
- **See also:** [[A11Y-013]], [[A11Y-021]], [[BDG-003]], [[STATE-004]]

### A11Y-020 — Move focus into modals; trap it; restore on dismiss
- **Rule:** When a dialog, bottom sheet, or full-screen cover opens, move accessibility focus to it (title or first control), trap focus within it, mark content behind as inaccessible (iOS `accessibilityViewIsModal`; Android sibling `importantForAccessibility="no-hide-descendants"`), and return focus to the triggering control on dismiss.
- **Why:** Otherwise focus stays on the now-hidden screen behind the modal, and users interact with obscured content.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual screen-reader open/close of every modal & sheet.
- **Exceptions:** Non-modal transient popovers that do not obscure interaction.
- **See also:** [[A11Y-017]], [[A11Y-032]], [[DLG-002]], [[BSH-004]]

### A11Y-021 — Identify errors in text and move focus to them (3.3.1)
- **Rule:** Form and submission errors MUST be described in text (not color/icon alone), programmatically associated with the offending field, and on submit failure move focus to the first error (or announce a summary via live region). Error text meets [[A11Y-001]] contrast.
- **Why:** Users must know an error occurred, which field, and how to fix it — silent red borders fail everyone relying on assistive tech.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual screen-reader submit-with-errors flow; `semantics_lint.py` checks error↔field association.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[A11Y-019]], [[FRM-006]], [[STATE-005]]

### A11Y-022 — Hide decorative & redundant elements from assistive tech
- **Rule:** Purely decorative images, background shapes, spacer views, and duplicate-of-adjacent-text icons MUST be hidden from assistive tech (iOS `isAccessibilityElement = false` / `.accessibilityHidden(true)`; Android `importantForAccessibility="no"`; Flutter `ExcludeSemantics`; RN `accessibilityElementsHidden` / `importantForAccessibility="no"`).
- **Why:** Announcing decoration adds noise and slows navigation; meaningful content should not compete with clutter.
- **Platforms:** all
- **Severity:** warning
- **Check:** `semantics_lint.py` flags images without label and without hidden flag; manual sweep.
- **Exceptions:** Images conveying information MUST instead have a text alternative, not be hidden.
- **See also:** [[A11Y-011]], [[AVT-002]]

### A11Y-023 — Icon-only controls carry a text label
- **Rule:** Every icon-only button (back, close, share, more, filter) MUST have an accessible label describing its action; the label MUST match the visible/tooltip meaning. Never ship a bare glyph with no name.
- **Why:** Icon-only controls are the most frequently unlabeled elements and are opaque to screen-reader users.
- **Platforms:** all
- **Severity:** error
- **Check:** `semantics_lint.py` flags icon buttons lacking a label.
- **Exceptions:** None.
- **See also:** [[A11Y-011]], [[ICN-004]], [[NAV-006]]

---

## Dynamic Type & reflow

### A11Y-024 — Support system font scaling up to the largest sizes (AX5 / 200%+)
- **Rule:** UI MUST support the OS text-scaling range up to iOS Accessibility size AX5 and Android font scale (≈ 200%+), remaining usable with no loss of content or function (SC 1.4.4). Do not cap `textScaler`/`fontScale` or disable Dynamic Type.
- **Why:** Many low-vision users run large text full-time; capping it silently breaks their setting.
- **Platforms:** all
- **Severity:** error
- **Check:** `a11y_audit.py` renders key screens at 200%/AX5 and diffs for clipping; manual largest-size pass.
- **Exceptions:** A hard clamp is acceptable only where uncapped scaling would break a legally-required layout, and then only within a documented range.
- **See also:** [[A11Y-025]], [[A11Y-026]], [[A11Y-027]], [[TYP-006]]

### A11Y-025 — Use scalable text-style APIs, never fixed pixel fonts
- **Rule:** Text MUST use the platform's scalable type APIs — iOS `UIFont.TextStyle`/`.font(.body)` + `dynamicTypeSize`; Android `sp` units + `TextAppearance`; Flutter `MediaQuery.textScaler` (do not hardcode fontSize without scaling); RN `allowFontScaling` left true — so it responds to the user's font-size setting.
- **Why:** Fixed `dp`/`px`/`pt` font sizes ignore the accessibility setting entirely.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags fixed-size font literals that bypass scaling; grep for `allowFontScaling={false}`.
- **Exceptions:** Brand wordmarks/logos rendered as images.
- **See also:** [[A11Y-024]], [[TYP-001]]

### A11Y-026 — No fixed heights on text containers
- **Rule:** Buttons, list rows, chips, cards, and labels MUST size to their content (min-height, not fixed height) so text can grow when scaled. Avoid fixed `height` on any container that holds user-facing text.
- **Why:** Fixed heights clip or truncate scaled text; content must be free to grow vertically.
- **Platforms:** all
- **Severity:** error
- **Check:** `a11y_audit.py` at 200% detects clipped text; manual review.
- **Exceptions:** Single-line fixed-format numerics (e.g., PIN cells) where truncation cannot occur.
- **See also:** [[A11Y-024]], [[A11Y-027]], [[BTN-003]]

### A11Y-027 — Reflow at 200%+ with no truncation, overlap, or lost function
- **Rule:** At 200% text scale (and AX5), content MUST reflow — text wraps, layouts stack, actions stay reachable (scroll if needed) — with no truncation, clipping, overlap, or two-dimensional scrolling of body content (SC 1.4.10). Prefer wrapping/stacking over horizontal scroll or ellipsis.
- **Why:** Truncated labels and overlapping controls at large sizes make the app unusable for the people who most need scaling.
- **Platforms:** all
- **Severity:** error
- **Check:** `a11y_audit.py` screenshot diff at 200%/AX5; manual sweep of dense screens.
- **Exceptions:** Data tables and content that inherently require 2-D scroll.
- **See also:** [[A11Y-024]], [[A11Y-026]], [[GRD-003]]

---

## System accessibility settings

### A11Y-028 — Honor Reduce Motion
- **Rule:** When Reduce Motion is enabled (iOS `UIAccessibility.isReduceMotionEnabled` / SwiftUI `accessibilityReduceMotion`; Android animator/transition scale = 0 or `Settings.Global`; Flutter `MediaQuery.disableAnimations`; RN `AccessibilityInfo.isReduceMotionEnabled`), replace parallax/zoom/spring/slide transitions with a simple cross-fade or no animation, and never auto-play looping motion.
- **Why:** Vestibular-disorder users can be made nauseated or dizzy by large motion; respecting the setting prevents real physical harm.
- **Platforms:** all
- **Severity:** error
- **Check:** `a11y_audit.py` toggles the flag and checks for reduced/removed animation; manual test.
- **Exceptions:** Essential motion conveying required information, which must still be dampened.
- **See also:** [[A11Y-031]], [[MOT-011]], [[PERF-003]]

### A11Y-029 — Honor Reduce Transparency
- **Rule:** When Reduce Transparency is on (iOS `isReduceTransparencyEnabled`), replace blur/translucent/"glass" materials with opaque surfaces that still meet contrast, so text over glass remains ≥ 4.5:1.
- **Why:** Translucent materials (iOS Liquid Glass, frosted bars) can drop text contrast below AA over busy backgrounds; opaque fallbacks restore legibility.
- **Platforms:** ios
- **Severity:** warning
- **Check:** Manual toggle of Reduce Transparency; `contrast_check.py` on the opaque fallback.
- **Exceptions:** None where text sits on the material.
- **See also:** [[A11Y-001]], [[PLAT-005]], [[DRK-003]]

### A11Y-030 — Honor Increase Contrast, Bold Text & Differentiate Without Color
- **Rule:** Respond to Increase Contrast / Bold Text / Differentiate-Without-Color (iOS `accessibilityContrast`, `legibilityWeight`, `shouldDifferentiateWithoutColor`; Android high-contrast text; Flutter `MediaQuery.highContrast`/`boldText`) by switching to a higher-contrast token set, heavier weights, and adding non-color cues.
- **Why:** These are explicit user requests for stronger legibility; ignoring them leaves the app inaccessible for those who opted in.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual toggle of each setting; verify high-contrast theme resolves.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[DRK-006]], [[COL-007]]

### A11Y-031 — Pair haptics & sound with a visible, announced change
- **Rule:** Haptic and audio feedback MUST accompany — never replace — a visible state change that is also exposed to assistive tech. Every haptic maps to an on-screen change and (where it conveys status) a live-region announcement.
- **Why:** Deaf/hard-of-hearing users miss sound and users with reduced tactile sensitivity miss haptics; feedback must be multi-modal.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of feedback events for a paired visual + announced change.
- **Exceptions:** None where the haptic/sound conveys information.
- **See also:** [[A11Y-019]], [[HAP-002]]

---

## WCAG 2.2 new criteria & input methods

### A11Y-032 — Focus not obscured (2.4.11)
- **Rule:** When an element receives focus it MUST NOT be entirely hidden by sticky headers/footers, keyboards, snackbars, FABs, or overlays; scroll it into view with adequate margin. (New in WCAG 2.2, AA.)
- **Why:** A focused control the user cannot see is effectively unreachable for keyboard/switch/screen-magnifier users.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual keyboard/switch navigation behind sticky UI and the on-screen keyboard.
- **Exceptions:** User-dismissible overlays that can be moved out of the way.
- **See also:** [[A11Y-004]], [[A11Y-020]], [[FRM-008]]

### A11Y-033 — Dragging movements have a single-tap alternative (2.5.7)
- **Rule:** Any action performed by dragging (reorder, slider, swipe-to-delete, pull-to-refresh, map pan) MUST also be operable by single taps/clicks — e.g., reorder handles with up/down buttons, a menu action mirroring swipe-to-delete, a refresh button. (New in WCAG 2.2, AA.)
- **Why:** Users with motor impairments or using switch/head-pointer input cannot perform sustained drag gestures.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual review: every drag path has a tap alternative; `semantics_lint.py` checks reorderable/swipe lists for custom actions.
- **Exceptions:** Drags where the path itself is essential (e.g., freehand drawing, signature).
- **See also:** [[A11Y-034]], [[GES-002]], [[LST-006]]

### A11Y-034 — Multipoint / path gestures have a single-pointer alternative (2.5.1)
- **Rule:** Functions triggered by multipoint or path-based gestures (pinch-zoom, two-finger rotate, swipe-path) MUST also be operable with a single-pointer action (buttons: +/−, rotate, next/prev). (SC 2.5.1, AA.)
- **Why:** Not everyone can perform multi-finger or precise-path gestures; single-pointer equivalents keep features reachable.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual audit of gesture-driven features for single-pointer equivalents.
- **Exceptions:** Gestures essential to the function (e.g., a piano/drawing app) or OS-implemented.
- **See also:** [[A11Y-033]], [[GES-001]]

### A11Y-035 — Pointer cancellation: activate on up-event (2.5.2)
- **Rule:** Activation MUST occur on the up-event, and users MUST be able to abort by dragging off the target before release (or provide undo). Do not trigger irreversible actions on touch-down. (SC 2.5.2, AA.)
- **Why:** Down-event activation gives no chance to correct an accidental touch; up-event + abort prevents mis-taps.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual test: press, drag off, release → no activation.
- **Exceptions:** Actions where down-event is essential (e.g., press-and-hold-to-talk) or emulate a physical control.
- **See also:** [[A11Y-033]], [[BTN-004]]

### A11Y-036 — Accessible authentication: allow paste, managers & passkeys (3.3.8)
- **Rule:** Auth MUST NOT require a cognitive-function test (memorizing/transcribing a code, solving a puzzle) as the only method. Allow paste into every credential/OTP field, do not disable password managers/autofill, support passkeys/biometrics, and offer copy on generated codes. (New in WCAG 2.2, AA.)
- **Why:** Blocking paste/managers forces error-prone memorization that excludes users with cognitive disabilities and harms everyone.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: paste works in password/OTP fields; autofill/passkey available; grep for paste-blocking / autofill-disabling code.
- **Exceptions:** A cognitive test is allowed only if an accessible alternative or object-recognition mechanism is also offered.
- **See also:** [[A11Y-038]], [[AUTH-004]], [[PERM-002]]

### A11Y-037 — Consistent help placement (3.2.6)
- **Rule:** If help is offered (contact link, chat, FAQ, support), it MUST appear in the same relative location across screens where it exists. (New in WCAG 2.2, A.)
- **Why:** Predictable help placement reduces cognitive load and lets users in difficulty find assistance quickly.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of help entry-point placement across screens.
- **Exceptions:** None where help exists on multiple screens.
- **See also:** [[SET-004]], [[A11Y-038]]

### A11Y-038 — Redundant entry: don't re-ask for the same info (3.3.7)
- **Rule:** Within a single flow/session, information already entered MUST be auto-populated or selectable rather than re-typed (e.g., "billing same as shipping", remembered email). (New in WCAG 2.2, A.)
- **Why:** Re-entering the same data burdens memory and dexterity and increases abandonment.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual multi-step flow review for repeated inputs.
- **Exceptions:** Re-entry essential for security (e.g., password re-confirm), or where prior data is no longer valid.
- **See also:** [[A11Y-036]], [[FRM-009]], [[PAY-005]]

### A11Y-039 — Captions/transcripts for media; no autoplay audio (1.2.2 / 1.4.2)
- **Rule:** Prerecorded video with audio MUST provide synchronized captions (SC 1.2.2) and audio-only content a transcript (1.2.1). Audio that plays automatically for > 3s MUST offer a pause/stop/volume control independent of system volume (1.4.2).
- **Why:** Captions/transcripts serve deaf and hard-of-hearing users (and sound-off viewing); uncontrolled autoplay audio disrupts screen-reader use.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual media review for captions/transcript and audio controls.
- **Exceptions:** Media alternatives clearly labeled as such; brief non-essential UI sounds.
- **See also:** [[A11Y-031]], [[A11Y-019]]

### A11Y-040 — Do not lock orientation (1.3.4)
- **Rule:** Content MUST work in both portrait and landscape and MUST NOT lock to a single orientation unless essential (SC 1.3.4, AA).
- **Why:** Users with mounted devices or motor impairments may be fixed in one orientation; a hard lock excludes them.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual rotate test; inspect manifest/Info.plist orientation locks.
- **Exceptions:** Orientation essential to the experience (e.g., piano keyboard, AR camera, some games).
- **See also:** [[A11Y-027]], [[GRD-004]]

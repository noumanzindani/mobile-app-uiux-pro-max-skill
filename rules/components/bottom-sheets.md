# Bottom Sheets (BSH)

> Rules for modal and non-modal bottom sheets: detents/breakpoints, drag handle, home-indicator inset, dismissal, and keyboard behavior.

## Contents
- [BSH-001 — Use detents/breakpoints, not a single fixed height](#bsh-001--use-detentsbreakpoints-not-a-single-fixed-height)
- [BSH-002 — Show a drag handle on draggable sheets](#bsh-002--show-a-drag-handle-on-draggable-sheets)
- [BSH-003 — Provide a non-gesture dismiss](#bsh-003--provide-a-non-gesture-dismiss)
- [BSH-004 — Respect the home-indicator inset (34pt)](#bsh-004--respect-the-home-indicator-inset-34pt)
- [BSH-005 — Keep primary actions above the inset and in the thumb zone](#bsh-005--keep-primary-actions-above-the-inset-and-in-the-thumb-zone)
- [BSH-006 — Handle the keyboard without trapping the submit](#bsh-006--handle-the-keyboard-without-trapping-the-submit)
- [BSH-007 — Modal sheets scrim and trap focus](#bsh-007--modal-sheets-scrim-and-trap-focus)
- [BSH-008 — Move focus in and restore it on close](#bsh-008--move-focus-in-and-restore-it-on-close)
- [BSH-009 — Confirm before discarding unsaved input](#bsh-009--confirm-before-discarding-unsaved-input)
- [BSH-010 — Scroll long content within the sheet](#bsh-010--scroll-long-content-within-the-sheet)
- [BSH-011 — Round the top corners from tokens; not full-screen at max](#bsh-011--round-the-top-corners-from-tokens-not-full-screen-at-max)
- [BSH-012 — Use the framework's idiomatic sheet primitive](#bsh-012--use-the-frameworks-idiomatic-sheet-primitive)

---

### BSH-001 — Use detents/breakpoints, not a single fixed height
- **Rule:** Resizable sheets MUST use defined detents/breakpoints (e.g., medium and large, or fractional stops) rather than one hardcoded pixel height, and snap between them.
- **Why:** Detents adapt to content and screen size and match platform expectations (SwiftUI `.presentationDetents`, Compose partial/expanded, gorhom snap points).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — drag the sheet and confirm it snaps to defined stops.
- **Exceptions:** Small fixed-content action sheets that only need one height.
- **See also:** [[BSH-002]], [[BSH-012]]

### BSH-002 — Show a drag handle on draggable sheets
- **Rule:** Sheets the user can drag to resize/dismiss MUST display a visible grabber/drag handle at the top center, with a ≥44pt/48dp interactive region and an accessible label.
- **Why:** The handle signals the sheet is draggable and gives a reliable drag target.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual + a11y audit.
- **Exceptions:** Non-draggable, fixed-height sheets.
- **See also:** [[BSH-003]], [[A11Y-003]]

### BSH-003 — Provide a non-gesture dismiss
- **Rule:** Every sheet MUST be dismissible without a drag gesture — a close (✕) button and/or tapping the scrim — in addition to swipe-down.
- **Why:** WCAG 2.5.7/2.5.1; swipe-only dismissal excludes motor-impaired and screen-reader users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual + a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-012]], [[BSH-007]]

### BSH-004 — Respect the home-indicator inset (34pt)
- **Rule:** Sheet content and controls MUST inset for the bottom safe-area (34pt home indicator on iOS, gesture inset on Android) so nothing sits under or is clipped by it.
- **Why:** Content or buttons under the home indicator are hard to tap and conflict with the system gesture.
- **Platforms:** all
- **Severity:** error
- **Check:** manual on gesture-nav devices.
- **Exceptions:** Full-bleed backgrounds may extend behind the inset if no interactive/text content sits there.
- **See also:** [[GES-002]], [[BSH-005]]

### BSH-005 — Keep primary actions above the inset and in the thumb zone
- **Rule:** A sheet's primary CTA SHOULD be pinned at the bottom of the sheet, above the home-indicator inset, within easy thumb reach, and stay visible as content scrolls.
- **Why:** One-handed reachability; users shouldn't scroll to find the confirm button.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[BTN-012]], [[BSH-004]]

### BSH-006 — Handle the keyboard without trapping the submit
- **Rule:** When a sheet contains inputs, the keyboard MUST NOT cover the focused field or the submit button; the sheet grows/scrolls or shifts so both stay visible above the keyboard.
- **Why:** A submit button trapped under the keyboard blocks the task.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — focus a field near the bottom.
- **Exceptions:** None.
- **See also:** [[FRM-008]], [[SRCH-006]]

### BSH-007 — Modal sheets scrim and trap focus
- **Rule:** Modal bottom sheets MUST dim the background with a scrim, prevent interaction with content behind, and trap keyboard/AT focus inside the sheet until dismissed.
- **Why:** Prevents interacting with obscured background content and keeps screen-reader focus in the active surface.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit — attempt to focus background elements.
- **Exceptions:** Non-modal sheets (e.g., a persistent map detail) intentionally allow background interaction.
- **See also:** [[DLG-009]], [[A11Y-007]]

### BSH-008 — Move focus in and restore it on close
- **Rule:** Opening a sheet MUST move assistive-tech/keyboard focus into it (to the title or first control); closing MUST return focus to the element that opened it.
- **Why:** Prevents lost focus and disorientation for keyboard/screen-reader users (WCAG 2.4.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-007]], [[DLG-010]]

### BSH-009 — Confirm before discarding unsaved input
- **Rule:** If a sheet holds unsaved user input, swipe-down/scrim-tap dismissal MUST prompt to save/discard rather than silently losing the data.
- **Why:** Easy accidental dismissal (swipe) shouldn't destroy work.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enter data, then swipe to dismiss.
- **Exceptions:** Sheets with no editable content.
- **See also:** [[DLG-005]], [[FRM-030]]

### BSH-010 — Scroll long content within the sheet
- **Rule:** Content taller than the sheet's current detent MUST scroll inside the sheet, with drag-to-resize and internal scroll coordinated so neither blocks the other, and a header/CTA that stays reachable.
- **Why:** Non-scrolling overflowing sheets hide content; conflicting gestures frustrate users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual with long content.
- **Exceptions:** None.
- **See also:** [[BSH-001]], [[LST-001]]

### BSH-011 — Round the top corners from tokens; not full-screen at max
- **Rule:** Sheet top corners MUST use a shape token (typically 16–28dp); at the largest detent the sheet SHOULD retain a small top inset/rounding so it reads as a sheet, not an abrupt full-screen swap (or transition to a full-screen presentation deliberately).
- **Why:** Consistent, recognizable sheet affordance; abrupt full-bleed loses the dismiss affordance.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `token_lint.py` on radius + manual.
- **Exceptions:** Intentional full-screen cover presentations.
- **See also:** [[SHP-001]], [[BSH-002]]

### BSH-012 — Use the framework's idiomatic sheet primitive
- **Rule:** Sheets MUST be built with the platform/framework's native sheet primitive — SwiftUI `.sheet`+`.presentationDetents`, Compose `ModalBottomSheet`, Flutter `showModalBottomSheet`/`DraggableScrollableSheet`, RN `@gorhom/bottom-sheet` — not a hand-rolled absolutely-positioned overlay.
- **Why:** Native primitives get detents, insets, accessibility, and gesture handling right for free.
- **Platforms:** all
- **Severity:** warning
- **Check:** code review.
- **Exceptions:** None.
- **See also:** [[BSH-001]], [[PLAT-001]]

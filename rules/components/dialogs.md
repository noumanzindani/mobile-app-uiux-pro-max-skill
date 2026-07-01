# Dialogs & Alerts (DLG)

> Rules for modal dialogs and alerts: explicit destructive confirmation, platform-aware button placement, focus management, scrim, and restraint.

## Contents
- [DLG-001 — Reserve modal dialogs for high-stakes moments](#dlg-001--reserve-modal-dialogs-for-high-stakes-moments)
- [DLG-002 — State the consequence in title and body](#dlg-002--state-the-consequence-in-title-and-body)
- [DLG-003 — Label buttons with the action, not Yes/No](#dlg-003--label-buttons-with-the-action-not-yesno)
- [DLG-004 — Two primary-competing buttons max; clear default](#dlg-004--two-primary-competing-buttons-max-clear-default)
- [DLG-005 — Destructive actions require explicit confirmation](#dlg-005--destructive-actions-require-explicit-confirmation)
- [DLG-006 — Style the destructive action distinctly](#dlg-006--style-the-destructive-action-distinctly)
- [DLG-007 — Place buttons per platform convention](#dlg-007--place-buttons-per-platform-convention)
- [DLG-008 — Buttons meet target and spacing minimums](#dlg-008--buttons-meet-target-and-spacing-minimums)
- [DLG-009 — Scrim and trap focus; block the background](#dlg-009--scrim-and-trap-focus-block-the-background)
- [DLG-010 — Move focus in and restore it on close](#dlg-010--move-focus-in-and-restore-it-on-close)
- [DLG-011 — Provide a non-destructive escape](#dlg-011--provide-a-non-destructive-escape)
- [DLG-012 — Expose dialog semantics and an accessible name](#dlg-012--expose-dialog-semantics-and-an-accessible-name)
- [DLG-013 — Respect safe-area, Dynamic Type, and reduce-motion](#dlg-013--respect-safe-area-dynamic-type-and-reduce-motion)
- [DLG-014 — Use the native alert primitive; style from tokens](#dlg-014--use-the-native-alert-primitive-style-from-tokens)

---

### DLG-001 — Reserve modal dialogs for high-stakes moments
- **Rule:** Blocking modal dialogs MUST be used only for consequential decisions or critical information; routine confirmations SHOULD use inline UI, snackbars with undo, or non-modal surfaces.
- **Why:** Overusing modals interrupts flow and trains users to dismiss without reading.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — audit each modal for necessity.
- **Exceptions:** None.
- **See also:** [[BDG-002]], [[BSH-007]]

### DLG-002 — State the consequence in title and body
- **Rule:** A confirmation dialog's title MUST name the action and its body MUST state the consequence (what happens, whether it's reversible, what's affected) in plain language.
- **Why:** Users must understand what they're agreeing to before acting.
- **Platforms:** all
- **Severity:** error
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[DLG-003]], [[DLG-005]]

### DLG-003 — Label buttons with the action, not Yes/No
- **Rule:** Dialog buttons MUST use specific action verbs matching the title ("Delete", "Discard", "Log out") instead of ambiguous "Yes/No/OK".
- **Why:** Verb labels are unambiguous even when read out of context by a screen reader.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Purely informational single-button dialogs ("OK"/"Got it").
- **See also:** [[BTN-008]], [[DLG-002]]

### DLG-004 — Two primary-competing buttons max; clear default
- **Rule:** A dialog MUST offer at most two action buttons of competing weight (one confirm, one cancel); additional options belong in a menu or a different surface, and the safe/default action MUST be visually clear.
- **Why:** More than two weighted choices in a modal overwhelm and slow decisions.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Platform action sheets that legitimately list several distinct choices.
- **See also:** [[BTN-001]], [[DLG-007]]

### DLG-005 — Destructive actions require explicit confirmation
- **Rule:** Irreversible/destructive actions (delete, wipe, unrecoverable send) MUST require an explicit confirmation step — a dialog, typed confirmation, or an undo window — never a single unconfirmed tap.
- **Why:** Prevents catastrophic, unrecoverable mistakes.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trace every destructive action.
- **Exceptions:** Reversible actions covered by an immediate Undo snackbar ([[BDG-002]]).
- **See also:** [[BTN-009]], [[DLG-006]]

### DLG-006 — Style the destructive action distinctly
- **Rule:** The destructive button in a dialog MUST use the error/destructive color role (and a non-color cue), and MUST NOT be styled identically to a benign confirm.
- **Why:** Visual distinction reduces accidental destructive taps; not-color-only keeps it perceivable.
- **Platforms:** all
- **Severity:** error
- **Check:** manual + desaturate check.
- **Exceptions:** None.
- **See also:** [[COL-002]], [[A11Y-010]]

### DLG-007 — Place buttons per platform convention
- **Rule:** Button placement MUST follow the platform: iOS alerts put the preferred action on the right (bold), destructive typically styled red and placed per HIG; Android/M3 places text buttons at the end (confirming action rightmost in LTR) with cancel to its left.
- **Why:** Matching OS muscle memory prevents wrong-button taps; wrong placement reads as non-native.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual per platform.
- **Exceptions:** Adaptive dialog components that already apply correct per-OS layout.
- **See also:** [[BTN-014]], [[PLAT-002]]

### DLG-008 — Buttons meet target and spacing minimums
- **Rule:** Dialog buttons MUST be ≥44pt/48dp tall with ≥8dp between them; stacked (vertical) layout is required when labels don't fit side-by-side at large Dynamic Type.
- **Why:** Cramped dialog buttons cause mis-taps, worst on the most consequential actions.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` + `dynamic_type_check.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[A11Y-008]]

### DLG-009 — Scrim and trap focus; block the background
- **Rule:** Modal dialogs MUST dim the background with a scrim, disable interaction with content behind, and trap keyboard/AT focus within the dialog until it's resolved.
- **Why:** Prevents interacting with obscured content and keeps focus in the active surface (WCAG 2.4.3).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** Non-modal informational popovers.
- **See also:** [[BSH-007]], [[DLG-010]]

### DLG-010 — Move focus in and restore it on close
- **Rule:** Opening a dialog MUST move focus to it (title or default action); closing MUST return focus to the triggering element.
- **Why:** Keyboard/screen-reader users otherwise lose their place (WCAG 2.4.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-007]], [[BSH-008]]

### DLG-011 — Provide a non-destructive escape
- **Rule:** Every dialog MUST offer a clearly labeled cancel/dismiss that takes no action, reachable via button and (where the platform expects it) scrim tap / system back / Escape — and system back MUST NOT trigger the destructive action.
- **Why:** Users need a safe way out; back/dismiss must default to the non-destructive path.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — press back / tap scrim.
- **Exceptions:** Truly blocking dialogs (e.g., forced update) may omit cancel but must still not perform a destructive action on dismiss.
- **See also:** [[NAV-006]], [[DLG-005]]

### DLG-012 — Expose dialog semantics and an accessible name
- **Rule:** Dialogs MUST be exposed with the dialog/alert role and an accessible name (its title) so assistive tech announces "dialog, <title>" on open.
- **Why:** Screen-reader users must know a modal context opened and what it is (WCAG 4.1.2).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-005]], [[DLG-009]]

### DLG-013 — Respect safe-area, Dynamic Type, and reduce-motion
- **Rule:** Dialogs MUST fit within safe-areas, scroll their body when content + buttons exceed the screen at large Dynamic Type (never clipping the buttons), and honor reduce-motion for present/dismiss transitions.
- **Why:** Dialogs commonly clip actions at large text sizes and use excessive motion.
- **Platforms:** all
- **Severity:** warning
- **Check:** `dynamic_type_check.py` + manual with reduce-motion.
- **Exceptions:** None.
- **See also:** [[A11Y-008]], [[A11Y-009]]

### DLG-014 — Use the native alert primitive; style from tokens
- **Rule:** Standard alerts/confirmations SHOULD use the platform's native alert primitive (iOS `UIAlertController`/SwiftUI `.alert`, Android/M3 `AlertDialog`); custom dialogs MUST take all colors, radii, and spacing from tokens with text ≥4.5:1 contrast.
- **Why:** Native alerts inherit correct placement, a11y, and behavior; custom ones must still theme correctly.
- **Platforms:** all
- **Severity:** warning
- **Check:** code review + `token_lint.py` + `contrast_check.py`.
- **Exceptions:** Branded custom dialogs that replicate native semantics and a11y.
- **See also:** [[PLAT-001]], [[BTN-016]]

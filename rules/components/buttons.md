# Buttons (BTN)

> Rules for button emphasis, touch targets, interactive states, destructive actions, and platform placement. All values are token-driven; no magic numbers.

## Contents
- [BTN-001 — One primary action per view](#btn-001--one-primary-action-per-view)
- [BTN-002 — Minimum touch target 44pt / 48dp](#btn-002--minimum-touch-target-44pt--48dp)
- [BTN-003 — Space adjacent buttons ≥8dp apart](#btn-003--space-adjacent-buttons-8dp-apart)
- [BTN-004 — Ship every interactive state](#btn-004--ship-every-interactive-state)
- [BTN-005 — Pressed feedback: scale 0.96–0.98](#btn-005--pressed-feedback-scale-096098)
- [BTN-006 — Loading state locks the button and its width](#btn-006--loading-state-locks-the-button-and-its-width)
- [BTN-007 — Disabled buttons stay perceivable and explained](#btn-007--disabled-buttons-stay-perceivable-and-explained)
- [BTN-008 — Labels are action verbs that never truncate](#btn-008--labels-are-action-verbs-that-never-truncate)
- [BTN-009 — Destructive buttons are distinct and confirmed](#btn-009--destructive-buttons-are-distinct-and-confirmed)
- [BTN-010 — Icon-only buttons need an accessible name](#btn-010--icon-only-buttons-need-an-accessible-name)
- [BTN-011 — Expose button role and toggle state](#btn-011--expose-button-role-and-toggle-state)
- [BTN-012 — Anchor the primary mobile CTA in the thumb zone](#btn-012--anchor-the-primary-mobile-cta-in-the-thumb-zone)
- [BTN-013 — One FAB per screen (Android/M3 only)](#btn-013--one-fab-per-screen-androidm3-only)
- [BTN-014 — Place confirm buttons per platform convention](#btn-014--place-confirm-buttons-per-platform-convention)
- [BTN-015 — Emphasis is never color-only](#btn-015--emphasis-is-never-color-only)
- [BTN-016 — Style buttons from tokens only](#btn-016--style-buttons-from-tokens-only)
- [BTN-017 — Label contrast ≥4.5:1 (≥3:1 large)](#btn-017--label-contrast-451-31-large)
- [BTN-018 — Debounce to prevent double submit](#btn-018--debounce-to-prevent-double-submit)

---

### BTN-001 — One primary action per view
- **Rule:** Each screen or discrete visual region MUST expose exactly one high-emphasis (filled) primary button; all other actions use lower-emphasis styles (tonal, outlined, text).
- **Why:** Two competing primary buttons split attention and hurt task completion and scanability.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — count filled/high-emphasis buttons per view (should be ≤1 per region).
- **Exceptions:** Mutually exclusive paired actions in an empty state (e.g., "Take photo" / "Upload") may share emphasis if only one is reachable at a time.
- **See also:** [[BTN-012]], [[DLG-006]]

### BTN-002 — Minimum touch target 44pt / 48dp
- **Rule:** Every button MUST have a hit area ≥44×44pt on iOS and ≥48×48dp on Android, expanding via padding or `hitSlop` when the visible bounds are smaller.
- **Why:** WCAG 2.2 SC 2.5.8 and platform HIG/Material minimums; small targets cause mis-taps, worst for motor-impaired users.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` measures rendered hit area.
- **Exceptions:** Inline text links within a paragraph (SC 2.5.8 inline exception).
- **See also:** [[A11Y-003]], [[ICN-001]]

### BTN-003 — Space adjacent buttons ≥8dp apart
- **Rule:** Neighboring tappable buttons MUST have ≥8dp of clear spacing between their hit areas.
- **Why:** Prevents accidental activation of the wrong control in a cluster.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` gap check.
- **Exceptions:** Segmented controls / button groups that are a single visual unit with clear internal dividers.
- **See also:** [[SPC-003]], [[A11Y-003]]

### BTN-004 — Ship every interactive state
- **Rule:** Buttons MUST define tokens for default, focus, pressed, disabled, and loading states (plus hover where a pointer exists). Never ship a button styled only for its default state.
- **Why:** Missing states are the #1 AI-generation failure; users need visible feedback for focus, press, and busy.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify state coverage in the component definition.
- **Exceptions:** Purely decorative, non-interactive labels styled as buttons (avoid; prefer a non-button element).
- **See also:** [[BTN-005]], [[BTN-006]], [[BTN-007]], [[STATE-001]]

### BTN-005 — Pressed feedback: scale 0.96–0.98
- **Rule:** On press, animate the button to scale 0.96–0.98 over ~100ms with a token easing curve and reverse on release; pair with a light haptic for confirming actions.
- **Why:** Immediate tactile-visual feedback signals the tap registered and feels responsive.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — inspect press animation.
- **Exceptions:** When reduce-motion is enabled, substitute an opacity/overlay state change instead of scale.
- **See also:** [[MIC-001]], [[HAP-001]], [[A11Y-009]]

### BTN-006 — Loading state locks the button and its width
- **Rule:** While an action is in flight, the button MUST show an inline spinner/progress, block further taps, keep its width fixed to avoid layout shift, and announce "loading/busy" to assistive tech.
- **Why:** Prevents duplicate submissions and layout jumps; communicates progress to all users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trigger the async action and observe.
- **Exceptions:** Instant (<100ms) actions need no spinner.
- **See also:** [[BTN-018]], [[PRG-002]], [[A11Y-006]]

### BTN-007 — Disabled buttons stay perceivable and explained
- **Rule:** Disabled buttons MUST use the disabled token set, remain perceivable, expose a disabled state to assistive tech, and — where the reason is non-obvious — surface why (helper text/tooltip) rather than being a dead end.
- **Why:** Unexplained disabled controls confuse users; hidden requirements block task completion.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** WCAG exempts disabled controls from the 4.5:1/3:1 contrast minimums, but keep them visibly present.
- **See also:** [[FRM-014]], [[A11Y-005]]

### BTN-008 — Labels are action verbs that never truncate
- **Rule:** Button text MUST be an action phrase (verb-first, e.g., "Save changes"), fit on one line at default type, and wrap or scale — never truncate with an ellipsis — at the largest Dynamic Type / font-scale setting.
- **Why:** Truncated or vague labels ("OK", "…") hide the action's consequence and break at large text sizes.
- **Platforms:** all
- **Severity:** warning
- **Check:** `dynamic_type_check.py` flags fixed-height/truncating button containers.
- **Exceptions:** Standard platform affirmatives ("Done", "Cancel") in system dialogs.
- **See also:** [[A11Y-008]], [[TYP-006]]

### BTN-009 — Destructive buttons are distinct and confirmed
- **Rule:** Destructive/irreversible actions MUST use the error/destructive color role AND require explicit confirmation (dialog or undo window); never place an unconfirmed destructive primary in the default thumb-tap position.
- **Why:** Prevents accidental, unrecoverable actions (delete account, wipe data).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trace destructive actions to a confirmation or undo path.
- **Exceptions:** Reversible destructive actions with an immediate Undo snackbar may skip a modal (see [[BDG-002]]).
- **See also:** [[DLG-005]], [[COL-002]], [[BDG-002]]

### BTN-010 — Icon-only buttons need an accessible name
- **Rule:** Icon-only buttons MUST provide an accessible label (`accessibilityLabel` / `contentDescription`) describing the action, plus a tooltip/hint on long-press where the platform supports it.
- **Why:** Screen-reader users cannot infer meaning from a glyph alone.
- **Platforms:** all
- **Severity:** error
- **Check:** manual / a11y audit — every icon button has a non-empty name.
- **Exceptions:** None.
- **See also:** [[A11Y-004]], [[ICN-001]]

### BTN-011 — Expose button role and toggle state
- **Rule:** Buttons MUST expose the button role/trait; toggle or segmented buttons MUST additionally expose selected/pressed state to assistive tech.
- **Why:** Roles and states let screen readers announce "button" and "selected/on-off" correctly.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-005]], [[CHP-003]]

### BTN-012 — Anchor the primary mobile CTA in the thumb zone
- **Rule:** On task screens (forms, checkout, onboarding) the primary CTA SHOULD be full-width and pinned in the bottom thumb arc, ≥16dp from screen edges and clear of the home-indicator inset (34pt iOS).
- **Why:** One-handed reachability; the bottom third of the screen is the natural thumb zone.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Dense toolbars or multi-action screens where a full-width CTA is impractical.
- **See also:** [[BSH-005]], [[BTN-001]]

### BTN-013 — One FAB per screen (Android/M3 only)
- **Rule:** Use at most one Floating Action Button, representing the screen's single most common action, sized ≥56dp (regular) and placed clear of system insets; do not use a FAB on iOS.
- **Why:** The FAB is a Material pattern; multiple FABs or an iOS FAB reads as "neither-native."
- **Platforms:** android
- **Severity:** warning
- **Check:** manual — platform + FAB count.
- **Exceptions:** M3 FAB menu / extended FAB for a single promoted action.
- **See also:** [[PLAT-001]], [[NAV-016]]

### BTN-014 — Place confirm buttons per platform convention
- **Rule:** Confirm/primary buttons MUST follow platform placement: iOS alerts put the preferred action bold on the right (or bottom of a stacked pair); Android/M3 places the confirming text button at the end (right in LTR).
- **Why:** Muscle memory differs per OS; wrong placement causes wrong taps.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Adaptive components that already apply the correct per-platform layout.
- **See also:** [[DLG-007]], [[PLAT-002]]

### BTN-015 — Emphasis is never color-only
- **Rule:** Primary vs secondary vs tertiary emphasis MUST be distinguishable by fill, elevation, border, or weight — not hue alone.
- **Why:** Color-blind users and grayscale contexts must still perceive the action hierarchy (WCAG 1.4.1).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — desaturate the UI and confirm hierarchy survives.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[COL-001]]

### BTN-016 — Style buttons from tokens only
- **Rule:** All button color, radius, padding, elevation, and typography MUST reference component or semantic tokens; no hardcoded hex, dp, or point literals.
- **Why:** Token binding enables theming, dark mode, and density switches without touching component code.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** Hairline borders (1px) and dynamically read platform insets.
- **See also:** [[COL-001]], [[SHP-001]], [[DRK-001]]

### BTN-017 — Label contrast ≥4.5:1 (≥3:1 large)
- **Rule:** Button label text MUST meet ≥4.5:1 contrast against the button fill (≥3:1 for text ≥24px, or ≥18.66px bold) in every theme.
- **Why:** WCAG 2.2 SC 1.4.3; low-contrast labels are unreadable in sunlight and for low-vision users.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` on label/fill token pairs, per theme.
- **Exceptions:** Disabled buttons (per [[BTN-007]]).
- **See also:** [[A11Y-001]], [[DRK-001]]

### BTN-018 — Debounce to prevent double submit
- **Rule:** Buttons that trigger network mutations or navigation MUST guard against rapid double-taps — disable on first tap or debounce ≥ the press-animation duration — so one intent produces one action.
- **Why:** Double taps cause duplicate charges, duplicate posts, or double navigation.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — rapid-tap the button and assert a single effect.
- **Exceptions:** Idempotent, side-effect-free actions (e.g., toggling a local filter).
- **See also:** [[BTN-006]], [[OFF-001]]

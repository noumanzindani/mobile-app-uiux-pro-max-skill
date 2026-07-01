# Badges, Banners & Snackbars (BDG)

> Rules for count/status badges, snackbars/toasts, and inline banners — including transient timing, Undo/Retry, and the non-blocking offline banner.

## Contents
- [BDG-001 — Snackbars are transient and auto-dismiss](#bdg-001--snackbars-are-transient-and-auto-dismiss)
- [BDG-002 — Reversible actions offer Undo; failures offer Retry](#bdg-002--reversible-actions-offer-undo-failures-offer-retry)
- [BDG-003 — One snackbar at a time, above bottom insets](#bdg-003--one-snackbar-at-a-time-above-bottom-insets)
- [BDG-004 — Status is never color-only](#bdg-004--status-is-never-color-only)
- [BDG-005 — Count badges cap and label the true count](#bdg-005--count-badges-cap-and-label-the-true-count)
- [BDG-006 — Badges don't obscure their anchor's target](#bdg-006--badges-dont-obscure-their-anchors-target)
- [BDG-007 — Announce transient messages to assistive tech](#bdg-007--announce-transient-messages-to-assistive-tech)
- [BDG-008 — The offline banner is non-blocking and auto-recovers](#bdg-008--the-offline-banner-is-non-blocking-and-auto-recovers)
- [BDG-009 — Don't put essential actions only in a timed snackbar](#bdg-009--dont-put-essential-actions-only-in-a-timed-snackbar)
- [BDG-010 — Badge and banner contrast ≥4.5:1 / ≥3:1](#bdg-010--badge-and-banner-contrast-451--31)
- [BDG-011 — Style from semantic status tokens](#bdg-011--style-from-semantic-status-tokens)
- [BDG-012 — Persistent errors use inline banners, not snackbars](#bdg-012--persistent-errors-use-inline-banners-not-snackbars)

---

### BDG-001 — Snackbars are transient and auto-dismiss
- **Rule:** Snackbars/toasts MUST auto-dismiss after 4–10s (≥4s minimum per Material; longer when an action is offered) and MUST be dismissible by swipe; they MUST NOT block interaction with the rest of the screen.
- **Why:** Transient confirmations shouldn't trap the user; too-short timing is unreadable, too-long is intrusive.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — time the dismissal.
- **Exceptions:** WCAG 2.2.1 — if content is essential and time-sensitive, allow the user to extend/pause.
- **See also:** [[BDG-002]], [[BDG-009]]

### BDG-002 — Reversible actions offer Undo; failures offer Retry
- **Rule:** A snackbar confirming a reversible/destructive action MUST include an Undo action for the visible window; a snackbar reporting a recoverable failure MUST include Retry.
- **Why:** Undo enables safe, fast destructive actions without a modal; Retry recovers transient errors in place.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — trigger delete/failure paths.
- **Exceptions:** Irreversible high-stakes actions use an explicit confirmation dialog instead ([[DLG-005]]).
- **See also:** [[BTN-009]], [[OFF-001]]

### BDG-003 — One snackbar at a time, above bottom insets
- **Rule:** Show at most one snackbar at a time (queue the rest) and position it above the bottom navigation, FAB, and home-indicator inset (34pt iOS) so it never overlaps them.
- **Why:** Stacked snackbars and inset overlap hide content and controls.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[BSH-004]], [[NAV-012]]

### BDG-004 — Status is never color-only
- **Rule:** Status badges/dots (online, error, warning, success) MUST pair color with a shape, icon, or text label so meaning survives without color perception.
- **Why:** WCAG 2.2 SC 1.4.1; red/green status is invisible to many color-blind users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — desaturate the UI.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[AVT-005]]

### BDG-005 — Count badges cap and label the true count
- **Rule:** Numeric badges MUST cap overflow (e.g., "99+") and expose the exact count to assistive tech via the accessible label ("12 unread notifications"), not just the truncated glyph.
- **Why:** Screen-reader users need the real number; uncapped counts overflow the badge.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-004]], [[NAV-013]]

### BDG-006 — Badges don't obscure their anchor's target
- **Rule:** A badge overlaid on an icon/avatar MUST NOT shrink the anchor's tap target below 44pt/48dp or cover content needed to identify it.
- **Why:** Overlapping badges can eat the tappable area and hide the icon.
- **Platforms:** all
- **Severity:** warning
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[NAV-013]]

### BDG-007 — Announce transient messages to assistive tech
- **Rule:** Snackbars, toasts, and banners MUST announce their message via a polite live region (or platform announcement API) so screen-reader users hear it without moving focus.
- **Why:** Silent transient UI is invisible to non-visual users; WCAG 4.1.3 status messages.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[BDG-001]]

### BDG-008 — The offline banner is non-blocking and auto-recovers
- **Rule:** An offline/connectivity banner MUST be a non-blocking inline banner (not a modal), keep cached content usable, and auto-dismiss when connectivity returns — optionally confirming "Back online".
- **Why:** Blocking the whole app on network loss destroys offline-first UX; the banner should inform, not gate.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — toggle airplane mode.
- **Exceptions:** Screens that genuinely cannot function offline may disable specific actions with an explanation (still non-modal).
- **See also:** [[STATE-004]], [[OFF-002]]

### BDG-009 — Don't put essential actions only in a timed snackbar
- **Rule:** Actions the user must be able to take MUST NOT live exclusively in an auto-dismissing snackbar; provide a persistent path (banner, inline control, or history) as well.
- **Why:** Timed messages disappear before slower or distracted users act (WCAG 2.2.1 / cognitive load).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Undo, which is inherently a limited-window convenience with a non-destructive default.
- **See also:** [[BDG-002]], [[BDG-012]]

### BDG-010 — Badge and banner contrast ≥4.5:1 / ≥3:1
- **Rule:** Badge/banner text MUST meet ≥4.5:1 against its fill (≥3:1 for large text), and a status dot MUST meet ≥3:1 against its background in every theme.
- **Why:** WCAG 1.4.3/1.4.11; status must be legible in light and dark.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-001]], [[A11Y-002]]

### BDG-011 — Style from semantic status tokens
- **Rule:** Badge/banner/snackbar colors MUST reference semantic status tokens (info/success/warning/error/neutral), never raw hex, so they theme correctly across light/dark/high-contrast.
- **Why:** Token binding keeps status colors consistent and theme-aware.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[COL-001]], [[DRK-001]]

### BDG-012 — Persistent errors use inline banners, not snackbars
- **Rule:** Errors the user must resolve (validation summary, failed sync needing action) MUST use a persistent inline banner near the relevant content, not a transient snackbar.
- **Why:** Blocking or important errors that auto-dismiss get missed and can't be re-read.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[STATE-003]], [[FRM-012]]

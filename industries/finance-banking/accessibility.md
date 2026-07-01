# Finance / Banking — Domain Accessibility

> Finance-specific accessibility on top of core `[[A11Y-…]]` rules. The money-app
> a11y risks concentrate around **numerals, color-coded status, and screen-reader
> announcements of changing values.**

## Focus areas

### Numerals & amounts
- Tabular/monospaced figures and right alignment aid low-vision column scanning
  (`[[FIN-002]]`). Ensure amounts scale with Dynamic Type / font scale up to 200%
  without truncation or overlap (core `[[TYP-006]]`, `[[A11Y-007]]`) — long amounts
  wrap or resize, they don't clip.
- Keep decimals; a screen reader must voice "two hundred forty dollars and zero
  cents," not "240."

### Color-independent status
- Transaction status (`[[FIN-005]]`) and credit/debit direction (`[[FIN-015]]`) must
  never depend on color alone — pair with text, icon, or sign (`[[FIN-012]]`, core
  `[[CHT-002]]`). Verify by grayscale review.
- Meet contrast minimums for text (4.5:1) and status icons/affordances (3:1) per
  `[[A11Y-007]]`, in both light and dark themes.

### Screen-reader announcements
- Announce **balance and amount changes** via a live region so a blind user knows a
  transfer completed and the new balance (`[[FIN-018]]`).
- The privacy toggle's accessible name is action-only and never reads the hidden
  value; hidden values are removed from the a11y tree (`[[FIN-003]]`, `[[FIN-016]]`).
- Give every amount/status a meaningful accessible label ("−$240.00, debit,
  pending"), not just the visual glyphs.

### Auth accessibility
- Paste/password-manager/passkey support is an accessibility feature, not just
  convenience (WCAG 3.3.8) — blocking them harms users with cognitive/motor
  disabilities (`[[FIN-006]]`, core `[[AUTH-003]]`).
- Biometric flows always have an accessible non-biometric fallback (core `[[BIO-001]]`).

### Forms & keyboards
- Money amount fields use the correct numeric keyboard, clear labels, and inline,
  programmatically-associated error text (core `[[FRM-007]]`, `[[FRM-012]]`).

---

## Rules

### FIN-012 — Never convey transaction status by color alone
- **Rule:** Transaction status and any risk/alert state MUST be conveyed by at least one non-color channel (text label, icon, shape, or weight) in addition to color, and MUST pass a grayscale review. Applies to pending/cleared/failed indicators and to positive/negative deltas.
- **Why:** WCAG 1.4.1; color-vision-deficient and low-vision users cannot rely on red/green. Status drives financial decisions, so color-only encoding is decision-blocking, not cosmetic.
- **Platforms:** all
- **Severity:** error
- **Check:** Status/deltas readable in grayscale; each has a text or icon cue; contrast ≥ required minimums.
- **See also:** [[FIN-005]], [[FIN-015]], [[CHT-002]], [[A11Y-007]]

### FIN-018 — Announce balance and amount changes to assistive tech
- **Rule:** When a balance or amount updates as a result of a user action (transfer completes, deposit posts, filter changes a total), the change MUST be announced via a live region, and every amount/status MUST expose a meaningful accessible label (localized value + direction + state), not raw glyphs.
- **Why:** Blind/low-vision users otherwise can't tell whether a money action succeeded or what the new balance is — a critical trust and correctness gap.
- **Platforms:** all (live-region APIs platform-specific)
- **Severity:** warning
- **Check:** Balance/total updates fire an AT announcement; amount nodes have descriptive accessible names including sign/direction and state.
- **See also:** [[FIN-002]], [[FIN-015]], [[FIN-003]], [[A11Y-007]]

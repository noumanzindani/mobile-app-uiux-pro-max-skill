# Avatars & Media Thumbnails (AVT)

> Rules for avatars and thumbnail images: fallbacks, alt text, sizing, and reserved space.

### AVT-001 — Always provide a fallback
- **Rule:** Avatars MUST render a deterministic fallback (initials or a neutral person/entity icon) when the image is missing, fails to load, or is null.
- **Why:** Broken-image glyphs look defective and leak that a user has no photo.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — render with a null/404 image source.
- **Exceptions:** None.
- **See also:** [[AVT-002]], [[STATE-002]]

### AVT-002 — Meaningful avatars carry an accessible name; decorative ones are hidden
- **Rule:** An avatar that conveys identity MUST expose an accessible label (the person/entity name); a purely decorative avatar next to its own visible name MUST be marked decorative so it isn't announced twice.
- **Why:** Screen readers should announce identity once, not "image" or a duplicate.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-004]], [[AVT-001]]

### AVT-003 — Reserve avatar/thumb space to avoid reflow
- **Rule:** Avatars and thumbnails MUST occupy their final fixed size (a spacing token) before the image loads so text and rows do not reflow on load.
- **Why:** Prevents layout shift and mis-taps in lists.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — load on a throttled connection.
- **Exceptions:** None.
- **See also:** [[CRD-007]], [[PERF-003]]

### AVT-004 — Use token sizes and shape
- **Rule:** Avatar diameters and thumbnail dimensions MUST come from the size/spacing token scale, and shape (circle for people, token radius for content) MUST be consistent within a surface; the image is clipped to that shape.
- **Why:** Consistent sizing and shape read as one system; clipping prevents overflow.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[SHP-001]], [[CRD-006]]

### AVT-005 — Fallback and status contrast ≥3:1
- **Rule:** Initials/icon on the fallback background MUST meet ≥4.5:1 (text) and any presence/status dot or ring MUST meet ≥3:1 against its adjacent color and not encode meaning by color alone.
- **Why:** WCAG 1.4.3/1.4.11; low-vision and color-blind users must read initials and status.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-001]], [[A11Y-010]], [[BDG-004]]

### AVT-006 — Tappable avatars are full targets
- **Rule:** When an avatar is interactive (opens a profile), its hit area MUST be ≥44pt/48dp with an accessible label describing the action ("View <name>'s profile").
- **Why:** Small avatars are common tap targets; undersized/unlabeled ones fail motor and screen-reader users.
- **Platforms:** all
- **Severity:** warning
- **Check:** `target_size_lint.py` + a11y audit.
- **Exceptions:** Non-interactive display avatars.
- **See also:** [[A11Y-003]], [[BTN-010]]

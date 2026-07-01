# Accessibility Review

**Purpose:** Audit a screen against WCAG 2.2 AA and the platform accessibility APIs, returning a PASS/FAIL result per criterion with concrete fixes.

**Inputs:**
- *Required:* **The screen** — source code and/or screenshot.
- *Required:* **Framework** (drives which a11y API is expected — Flutter `Semantics`, RN `accessibilityLabel/Role/State`, SwiftUI `.accessibility*`, Compose `Modifier.semantics`).
- **Platform target** — sets the target-size minimum (iOS 44pt vs Android 48dp) and screen-reader (VoiceOver/TalkBack).
- **Token source** — if provided, contrast is checked from token pairs rather than rendered pixels.

**Procedure:**
1. Load `rules/system/accessibility.md` (the A11Y rule set) and the a11y checklist `quality-checks/checklists/accessibility.md` and `contrast.md`.
2. Load the framework's a11y API reference — `frameworks/<framework>/components.md` (a11y section) — to know the idiomatic label/role/state calls.
3. **Run the a11y validators** (execute, don't load): `contrast_check.py` (text ≥4.5:1, large ≥3:1, UI/icon/focus ≥3:1 — both themes), `target_size_lint.py` (≥44pt/48dp targets, ≥8dp spacing), `dynamic_type_check.py` (no fixed text heights; scales to 200%), and `rtl_check.py` (directionality-safe).
4. Reason through the WCAG 2.2 criteria the validators can't mechanize: labels+roles+state on every interactive element, focus/reading order, live-region announcements for the 7 states, no color-only meaning (add non-color cue), dragging has a tap alternative (**2.5.7**), focus not obscured (**2.4.11**), accessible authentication allows paste/password-managers/passkeys (**3.3.8**).
5. Check dark-mode + high-contrast resolution — `rules/system/dark-mode.md` — and re-run `contrast_check.py` for the dark theme.

**Output format:** A **criterion-by-criterion PASS/FAIL table**:
- Column set: WCAG criterion / rule ID · status (PASS/FAIL/N-A) · location · finding · fix.
- Grouped as: **contrast**, **target size & spacing**, **labels/roles/state**, **focus & reading order**, **Dynamic Type**, **color-independence**, **WCAG 2.2 additions (2.4.11 / 2.5.7 / 2.5.8 / 3.3.8)**, **RTL**.
- The embedded `contrast_check.py` / `target_size_lint.py` / `dynamic_type_check.py` / `rtl_check.py` reports.
- A one-line **AA verdict**.

**Self-check:** Confirm all four a11y validators ran and their output is embedded; confirm contrast was evaluated in **both** light and dark themes; verify every interactive element was assessed for label+role+state; ensure each FAIL has a rule ID and a concrete fix.

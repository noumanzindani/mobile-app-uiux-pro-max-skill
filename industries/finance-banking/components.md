# Finance / Banking — Domain Components

> Domain-specific components and their required states/behaviors. Each maps to core
> component rules (`[[BTN-…]]`, `[[LST-…]]`, `[[FRM-…]]`) and adds finance
> constraints. Build these token-driven; no magic values.

## Table of contents

1. [Amount label](#1-amount-label)
2. [Transaction row](#2-transaction-row)
3. [Balance card + privacy toggle](#3-balance-card--privacy-toggle)
4. [Payee / recipient picker](#4-payee--recipient-picker)
5. [Card tile (masked)](#5-card-tile-masked)
6. [Fee / total breakdown](#6-fee--total-breakdown)
7. [Rules](#rules)

---

## 1. Amount label

The atomic unit of a finance UI. One shared component; used everywhere a monetary
value appears.

- **Tabular/monospaced figures** so digits align across rows and never reflow as
  values change (`[[FIN-002]]`, core `[[TAB-004]]`).
- **Right-aligned** in lists and tables.
- **Explicit currency** — symbol or ISO code; never assume locale (`[[L10N-005]]`).
- **Signed & direction-coded without color** — leading `+`/`−`, or an inflow/outflow
  affordance, so credit vs debit reads on a monochrome screen (`[[FIN-015]]`).
- **Screen-reader form** reads the full localized value ("minus two hundred forty
  dollars, debit"), not "dash 240" (`[[FIN-018]]`).

## 2. Transaction row

Composed from an avatar/merchant glyph, description, date, **status**, and amount label.

- Status chip is text + non-color cue (`[[FIN-005]]`, `[[FIN-012]]`).
- Whole row is one primary tap target → detail; secondary actions via swipe or
  long-press, each with a tap-accessible equivalent (core `[[CRD-…]]`, gesture-fallback).
- Pending rows visually de-emphasized but explicitly labeled.
- Virtualized list (core `[[LST-…]]`); skeleton rows while loading.

## 3. Balance card + privacy toggle

- Large balance in tabular numerals; account name; masked account number (last 4).
- **Hide/show toggle** (`[[FIN-003]]`): tapping masks the balance to `••••` and
  masks account digits. State persists for the session and applies to all instances.
- The toggle's accessible label is state-only ("Hide balance" / "Show balance") and
  **never announces the hidden value**; when hidden, the value node is removed from
  the accessibility tree, not just visually covered (`[[FIN-016]]`).

## 4. Payee / recipient picker

- Recents + search; each payee shows a **verified/last-used** cue to reduce
  misdirected payments.
- **First-time payee** is visibly flagged and triggers step-up on commit (`[[FIN-006]]`).
- Never expose full account numbers in the list — show last 4 + nickname (`[[FIN-009]]`).

## 5. Card tile (masked)

- Show brand, nickname, and **last 4 only**; the full PAN, CVV, and expiry are never
  rendered by default and never logged (`[[FIN-009]]`).
- "Reveal details" is an explicit, re-auth-gated action; revealed values auto-hide
  and are excluded from screenshots (`[[FIN-016]]`).

## 6. Fee / total breakdown

- Itemized rows (each fee named) + a dominant **Total** row (`[[FIN-010]]`).
- Right-aligned tabular amounts; FX rate and margin shown when currencies differ.
- Appears on the review screen before commit; the total matches the charged amount
  exactly.

---

## Rules

### FIN-003 — Balance privacy toggle (hide/show)
- **Rule:** Any screen displaying account balances or holdings MUST offer a one-tap hide/show control. Hidden state masks all balances and account numbers app-wide, persists for the session, and its accessible label conveys only the action ("Show balance"/"Hide balance") — never the value.
- **Why:** People check finances in public (transit, offices). Shoulder-surfing is a real threat; a privacy toggle is now an expected banking-app affordance.
- **Platforms:** all
- **Severity:** warning
- **Check:** Toggle present on balance surfaces; hidden state masks value and removes it from the a11y tree; state shared across instances.
- **See also:** [[FIN-016]], [[FIN-002]], [[A11Y-007]]

### FIN-002 — Use tabular/monospaced numerals and right-align amounts
- **Rule:** All monetary values MUST use tabular (monospaced) figures and be right-aligned in lists/tables so digits align and column-scanning works. Decimal places are consistent per currency.
- **Why:** Proportional numerals shift horizontally as values change, breaking vertical scanning and making totals hard to compare — a core legibility and trust issue in finance.
- **Platforms:** all
- **Severity:** error
- **Check:** Amount text uses a tabular/font-feature `tnum` or monospaced face; list amounts are right-aligned; decimal count consistent per currency.
- **See also:** [[FIN-015]], [[FIN-018]], [[TAB-004]], [[TYP-006]]

### FIN-015 — Encode credit/debit direction without relying on color
- **Rule:** Inflow vs outflow (credit/debit) MUST be distinguishable without color — via sign (`+`/`−`), an icon/affordance, or an explicit label — in addition to any color used.
- **Why:** ~8% of men have color-vision deficiency; red/green-only amounts are unreadable to them and fail WCAG 1.4.1. Money direction is decision-critical.
- **Platforms:** all
- **Severity:** error
- **Check:** Credit/debit differ by a non-color channel; passes a grayscale review.
- **See also:** [[FIN-002]], [[FIN-012]], [[CHT-002]], [[A11Y-007]]

### FIN-009 — PCI-safe: never render or log the raw PAN
- **Rule:** The full card number (PAN), CVV, and full track data MUST NEVER be rendered by default, stored in app logs/analytics, or included in screenshots/exports. Show last 4 only; gate any full-detail reveal behind re-auth and exclude it from capture.
- **Why:** PCI-DSS scope and basic fraud prevention: displayed/logged PANs are a breach and compliance liability. This is non-negotiable in any card context.
- **Platforms:** all
- **Severity:** error
- **Check:** Grep for PAN rendering/logging; card UI shows last 4; reveal is re-auth-gated and screenshot-excluded.
- **See also:** [[FIN-016]], [[FIN-006]], [[FIN-007]]

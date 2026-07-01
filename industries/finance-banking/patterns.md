# Finance / Banking — Screen Patterns

> Domain screen recipes: how core rules combine into correct money-app flows.
> Rules here are money-movement and money-display patterns. Cross-references use
> `[[ID]]`; core rules are referenced, never restated.

## Table of contents

1. [Account dashboard](#1-account-dashboard)
2. [Transfer / pay flow (the two-step commit)](#2-transfer--pay-flow-the-two-step-commit)
3. [Review-before-commit screen](#3-review-before-commit-screen)
4. [Transaction feed & detail](#4-transaction-feed--detail)
5. [Statements, receipts & export](#5-statements-receipts--export)
6. [Money data states (empty / loading / error / offline)](#6-money-data-states)
7. [Rules](#rules)

---

## 1. Account dashboard

The landing surface of a money app. Priorities, top to bottom:

- **Balance first, but privacy-aware.** Primary balance is the most prominent
  element, rendered with tabular numerals (`[[FIN-002]]`), and paired with a
  hide/show toggle (`[[FIN-003]]`). Default visible for a signed-in session unless
  the user previously hid it; remember the choice per session.
- **Glanceable, not dense.** Show 1–3 accounts/cards, most-recent 3–5
  transactions, and one primary action (usually "Pay" or "Transfer"). Deep detail
  lives one tap away — the dashboard is a summary, not a ledger.
- **Primary money action reachable; irreversible actions are not one-tap.** A
  "Pay/Transfer" entry point can sit in the thumb zone, but it opens a *flow*, not
  an immediate transfer. The actual commit is gated by review (`[[FIN-013]]`).
- **Trust cues persist** — institution name/logo, secure-session indicator, and
  last-login timestamp are visible or one tap away (`[[FIN-001]]`).

## 2. Transfer / pay flow (the two-step commit)

Canonical stages: **Compose → Review → Result.** Never collapse Compose and commit
into a single tap.

1. **Compose** — pick source, pick payee/destination, enter amount. Amount field
   uses the correct numeric keyboard and locale currency formatting (core `[[FRM-012]]`,
   `[[L10N-005]]`). Validate funds and limits inline (core `[[FRM-007]]`).
2. **Review** — a dedicated screen (§3) showing exactly what will happen. This is
   where fees and the final total appear (`[[FIN-010]]`).
3. **Result** — a success state with a reference/confirmation number, the debited
   amount, and a path to a receipt (`[[FIN-007]]`) and to "report a problem"
   (`[[FIN-008]]`). Handle the failed/returned outcome as a first-class state
   (`[[FIN-005]]`), not a toast that vanishes.

For card payments to merchants, prefer native Pay sheets per core `[[PAY-001]]`.

## 3. Review-before-commit screen

The single most important screen in a banking app. It exists to make an
irreversible action deliberate.

- Restate **payee, source, amount, fees, and total** unambiguously. Total is the
  visually dominant number (`[[FIN-010]]`).
- Place the **commit button outside the resting-thumb arc** and label it with the
  consequence ("Send $240.00"), not a generic "Confirm" (`[[FIN-004]]`, core `[[DLG-005]]`).
- First-time or high-value payees trigger **step-up auth / re-auth** before commit
  (`[[FIN-006]]`, `[[FIN-011]]`).
- Provide an obvious **Edit/Back** that returns to Compose with values intact.

## 4. Transaction feed & detail

- **States are honest and distinct.** Pending, cleared, scheduled, failed, and
  returned each read differently in text and iconography — never color alone
  (`[[FIN-005]]`, `[[FIN-012]]`). Pending items are visually de-emphasized but
  clearly labeled "Pending," not hidden.
- **Amounts right-aligned, tabular, signed.** Debits and credits are
  distinguishable without color (`[[FIN-002]]`, `[[FIN-015]]`).
- **Group by date; sticky date headers.** Support search and filter by
  date/amount/type. Zero-results and filtered-empty are distinct states (`[[FIN-014]]`).
- **Detail view** shows merchant, category, status timeline, running balance
  impact, and actions: split, categorize, download receipt (`[[FIN-007]]`),
  **report/dispute** (`[[FIN-008]]`).

## 5. Statements, receipts & export

- Every transaction and account offers **export/share** (PDF/CSV) with an
  accessible, standard share affordance (`[[FIN-007]]`).
- Exports must **mask sensitive identifiers** (full PAN never appears; show last 4)
  (`[[FIN-009]]`).
- Long generation is a determinate/indeterminate loading state with a clear result,
  not a silent wait (core `[[STATE-001]]`).

## 6. Money data states

Money data must degrade safely. For every balance/holdings/feed view design:

- **Loading** — skeleton rows; never show a stale-looking `$0.00` as if real.
- **Empty** — "No transactions yet" differs from "No results for this filter."
- **Error** — "Couldn't load your balance" with retry; never render an ambiguous
  blank or a fabricated number (`[[FIN-014]]`).
- **Offline** — show last-synced value **with an explicit "as of <time>" stamp**;
  disable money-movement actions that require a live balance and say why
  (core `[[OFF-002]]`).

---

## Rules

### FIN-004 — Place irreversible money actions outside the resting-thumb arc
- **Rule:** The commit control for any irreversible or high-consequence money action (transfer, pay, trade, withdraw, close account) MUST NOT sit in the natural resting-thumb zone of one-handed use, MUST be labeled with its concrete consequence (e.g. "Send $240.00"), and MUST be preceded by an explicit review step. Do not auto-focus or pre-arm it.
- **Why:** Thumb-zone placement optimizes *frequent* actions; money commits are the opposite — accidental taps are costly and often irreversible. Distance + explicit labeling force deliberation.
- **Platforms:** all
- **Severity:** error
- **Check:** Audit: commit button's vertical position is in the upper/mid region or otherwise offset from the primary reach arc; label contains amount; a review screen precedes it.
- **Exceptions:** Reversible/low-value actions (e.g. round-up toggles, saving a draft) may sit in the thumb zone.
- **See also:** [[FIN-013]], [[FIN-010]], [[DLG-005]], [[PAY-001]]

### FIN-005 — Render transaction states explicitly (pending / cleared / failed / scheduled / returned)
- **Rule:** Each transaction MUST show its lifecycle state in text and a non-color cue (icon/shape/weight). At minimum support: pending, cleared/posted, scheduled/upcoming, failed, and returned/reversed. Pending items must be labeled "Pending" and must not be counted into available balance without disclosure.
- **Why:** Users make real financial decisions on whether money has actually moved. Ambiguous or color-only status causes overdrafts, double-payments, and mistrust.
- **Platforms:** all
- **Severity:** error
- **Check:** Each row exposes a text status label; status is not conveyed by color alone (see [[FIN-012]]); pending vs cleared are visually distinct.
- **See also:** [[FIN-012]], [[FIN-015]], [[FIN-014]], [[STATE-001]], [[CHT-002]]

### FIN-007 — Provide statement/receipt export and share
- **Rule:** Transactions, accounts, and payment results MUST offer an export/receipt path (view + share/download as PDF or CSV) using the platform's standard share sheet. Generated artifacts must mask sensitive identifiers (see [[FIN-009]]).
- **Why:** Users need proof of payment for reimbursement, taxes, and disputes; a missing receipt path erodes trust and generates support load.
- **Platforms:** all
- **Severity:** warning
- **Check:** A share/download affordance exists on transaction detail and statements; exported artifact shows last-4 only.
- **See also:** [[FIN-008]], [[FIN-009]]

### FIN-010 — Show all fees and the final total before charge
- **Rule:** Before any commit, the review surface MUST display every fee (transfer fee, FX margin, network fee) itemized and a clearly dominant **final total** in the charged currency. No fee may first appear after the charge.
- **Why:** Hidden fees are the top trust-killer in finance apps and a regulatory/consumer-protection risk. The user must consent to the exact amount.
- **Platforms:** all
- **Severity:** error
- **Check:** Review screen enumerates fees line-by-line; total is present and visually dominant; total currency is explicit.
- **See also:** [[FIN-004]], [[FIN-013]], [[PAY-001]], [[L10N-005]]

### FIN-013 — Require a two-step (compose → review → commit) flow for money movement
- **Rule:** Transfers, payments, and trades MUST route through a distinct review screen between data entry and commit. The review screen restates payee/source/amount/fees/total and is the only place the irreversible commit lives.
- **Why:** A single-tap "pay" invites costly mistakes; a separate review step is the industry-standard guardrail and pairs with re-auth for high-risk actions.
- **Platforms:** all
- **Severity:** error
- **Check:** Flow contains a review route; commit action is absent from the compose screen.
- **See also:** [[FIN-004]], [[FIN-010]], [[FIN-006]], [[DLG-005]]

### FIN-014 — Design empty, error, and offline states for money data
- **Rule:** Balance, holdings, and transaction views MUST implement distinct empty, loading (skeleton), error (with retry), and offline (last-synced "as of <time>") states. Never render a fabricated or ambiguous value; disable live-balance-dependent actions when offline and say why.
- **Why:** A blank or defaulted `$0.00` shown as real data causes panic and bad decisions; users must know whether a number is live, stale, or unavailable.
- **Platforms:** all
- **Severity:** warning
- **Check:** Each money view enumerates the four states; offline shows a timestamp; error shows retry; no default `0` rendered as live.
- **See also:** [[FIN-005]], [[OFF-002]], [[STATE-001]]

# Finance / Banking — Industry Pack

> **Tier-3 industry pack.** Read this when the app moves money, shows balances, or
> handles account/financial data: retail banking, neobanks, brokerages, crypto
> wallets, budgeting/PFM, cards, lending, payroll, or B2B payments. It layers
> **domain-specific** rules on top of the core corpus (`rules/`); it never restates
> core rules — it references them by ID (`[[PAY-001]]`).

## When to use this pack

Activate when the screen or flow involves any of:

- **Money movement** — transfer, send/pay, bill pay, top-up, withdraw, invest, trade.
- **Balances & holdings** — account dashboard, portfolio, wallet, card balance.
- **Transaction history** — feeds/ledgers with pending/cleared/failed states.
- **Financial identity & auth** — login to a money app, step-up auth, re-auth.
- **Money artifacts** — statements, receipts, tax docs, card details.
- **Trust-sensitive actions** — adding a payee, changing limits, disputing a charge.

If the app only *mentions* money peripherally (e.g. an e-commerce checkout), use the
**E-commerce** pack for the storefront and pull `[[PAY-001]]`-family rules from core;
reach for this pack when the product's core job **is** the money.

## The 5 most load-bearing patterns

These five carry the most weight in finance UX. Get them right first.

1. **Confirm-and-review before irreversible money movement** — every
   transfer/pay/trade routes through an explicit review screen showing
   payee, amount, fees, and total, with the commit action placed **outside the
   resting-thumb arc**. → `[[FIN-004]]`, `[[FIN-010]]`, `[[FIN-013]]`, core `[[PAY-001]]`, `[[DLG-005]]`.
2. **Trustworthy money display** — tabular/monospaced numerals, right-aligned
   amounts, explicit currency, and non-color credit/debit direction. → `[[FIN-002]]`,
   `[[FIN-012]]`, `[[FIN-015]]`, core `[[TAB-004]]`.
3. **Balance privacy toggle** — one-tap hide/show for balances and account numbers,
   remembered per session, with an accessible label that never leaks the value.
   → `[[FIN-003]]`, `[[FIN-016]]`.
4. **Transaction states, honestly rendered** — pending vs cleared vs failed vs
   scheduled/returned are visually and textually distinct, never color-only.
   → `[[FIN-005]]`, `[[FIN-012]]`, core `[[STATE-001]]`, `[[CHT-002]]`.
5. **Frictionless-but-hard auth** — biometric unlock, paste-friendly / password-
   manager-friendly fields (WCAG 3.3.8), session timeout with graceful re-auth, and
   step-up before high-risk actions. → `[[FIN-006]]`, `[[FIN-011]]`, core `[[AUTH-003]]`, `[[BIO-001]]`.

## Domain rules in this pack (FIN-\*\*\*)

| ID | Title | File | Severity |
|---|---|---|---|
| [[FIN-001]] | Persistent trust & security cues on money surfaces | trust-and-safety.md | warning |
| [[FIN-002]] | Tabular/monospaced numerals; right-align amounts | components.md | error |
| [[FIN-003]] | Balance privacy toggle (hide/show) | components.md | warning |
| [[FIN-004]] | Irreversible actions out of the resting-thumb arc | patterns.md | error |
| [[FIN-005]] | Transaction states: pending / cleared / failed / scheduled | patterns.md | error |
| [[FIN-006]] | Biometric + paste-friendly auth (WCAG 3.3.8) | trust-and-safety.md | error |
| [[FIN-007]] | Statement / receipt export & share | patterns.md | warning |
| [[FIN-008]] | Always-reachable fraud & error reporting | trust-and-safety.md | error |
| [[FIN-009]] | PCI-safe: never render or log raw PAN | components.md | error |
| [[FIN-010]] | Show all fees & the final total before charge | patterns.md | error |
| [[FIN-011]] | Idle session timeout + graceful re-auth | trust-and-safety.md | error |
| [[FIN-012]] | Color-independent transaction status | accessibility.md | error |
| [[FIN-013]] | Two-step commit for transfers/payments | patterns.md | error |
| [[FIN-014]] | Empty & error states for money data | patterns.md | warning |
| [[FIN-015]] | Non-color credit/debit direction (sign + affordance) | components.md | error |
| [[FIN-016]] | Screen-capture / background masking of PII | trust-and-safety.md | warning |
| [[FIN-017]] | Clear, blameless money error copy | copy-and-tone.md | warning |
| [[FIN-018]] | Announce balance & amount changes to AT | accessibility.md | warning |

## Table of contents

- [`patterns.md`](./patterns.md) — account dashboard, transfer/pay flow, review screen, transaction feed, statements.
- [`components.md`](./components.md) — transaction row, amount label, balance card + privacy toggle, payee picker, card tile, fee breakdown.
- [`trust-and-safety.md`](./trust-and-safety.md) — trust cues, auth, session, PCI/PII handling, fraud reporting, compliance UX.
- [`copy-and-tone.md`](./copy-and-tone.md) — voice, microcopy, money-error messaging, regulatory disclosures.
- [`accessibility.md`](./accessibility.md) — numerals, color-independent status, screen-reader money announcements.
- [`pitfalls.md`](./pitfalls.md) — the common finance UX mistakes and how to avoid them.

## Core rules this pack leans on

`[[PAY-001]]` (native Pay / review before charge), `[[AUTH-003]]` (paste/passkeys 3.3.8),
`[[BIO-001]]` (passcode fallback), `[[TAB-004]]` (tabular numerals), `[[DLG-005]]`
(explicit destructive confirm), `[[STATE-001]]` (enumerate the 7 states),
`[[CHT-002]]` (no color-only encoding), `[[A11Y-007]]` (contrast/target size),
`[[L10N-005]]` (locale currency formatting), `[[OFF-002]]` (offline queue + rollback).

# Finance / Banking — Copy & Tone

> Voice, microcopy, error messaging, and disclosure norms for money apps. Finance
> copy must be **clear, calm, precise, and blameless** — never cute at the moment
> someone's money is at stake.

## Voice principles

- **Precise over friendly.** Money words are literal: "pending," "posted,"
  "available," "scheduled." Do not use synonyms interchangeably — pick a term per
  concept and use it everywhere (mirrors `[[FIN-005]]` states).
- **Calm and plain.** Short sentences, plain language, no jargon or hype. Reserve
  exclamation marks and celebration for genuinely positive, unambiguous moments
  (e.g. a completed transfer), never for fee or debt screens.
- **Blameless.** Errors describe what happened and what to do next, never "you did
  X wrong." (`[[FIN-017]]`)
- **Honest.** State fees, timing, and consequences directly. "Arrives in 1–3
  business days" beats "Sent!" when it hasn't actually settled.

## Microcopy norms

| Situation | Do | Don't |
|---|---|---|
| Confirm a transfer | "Send $240.00 to Jordan?" | "Confirm" (no amount/payee) |
| Pending item | "Pending — may take 1–3 business days" | "Done" / green check |
| Fee present | "Transfer fee $1.50 · Total $241.50" | hide fee until after |
| Insufficient funds | "This transfer needs $12.00 more than your available balance." | "Transaction failed" |
| First-time payee | "First time sending to this account. Double-check the details." | silent |
| Hidden balance | button: "Show balance" | button: "Show $4,210.55" |

- **Numbers are exact and formatted for locale** — currency symbol/code, grouping,
  and decimals per `[[L10N-005]]`; never truncate cents on a money-critical value.
- **Dates are unambiguous** — "Jun 3, 2026," not "3/6" (locale-dependent), especially
  for statements and scheduled payments.

## Error messaging

Finance errors carry real anxiety. Every money error message should answer three
questions:

1. **What happened?** — in plain terms ("Your payment didn't go through").
2. **Did money move?** — the single most important reassurance ("No money has left
   your account").
3. **What now?** — a clear next step ("Try again" / "Contact support" / "Report a
   problem"), linking to fraud/dispute paths where relevant (`[[FIN-008]]`).

Never show a raw error code alone; if you include one for support, pair it with human
language. Never blame the user for a system failure. (`[[FIN-017]]`)

## Disclosures & regulated copy

- Put **required disclosures at the point of decision** — APR, fees, FX margin, and
  regulatory notices appear on the review/commit surface, not only in T&Cs
  (`[[FIN-010]]`).
- Keep legally required wording intact; don't paraphrase mandated disclosures, but
  present them legibly (adequate contrast/size, no 8pt gray fine print).
- Separate marketing consent from required processing; copy for optional items is
  clearly optional.

---

## Rules

### FIN-017 — Write clear, blameless, reassuring money-error copy
- **Rule:** Money-related error and status messages MUST state (1) what happened in plain language, (2) whether funds moved/left the account, and (3) the next step — and MUST NOT blame the user for system failures or show a bare error code. Use consistent, literal financial terms per concept.
- **Why:** Financial errors trigger anxiety about lost money; answering "did money move?" and giving a next step reduces panic, support load, and mistrust. Blame and jargon amplify fear.
- **Platforms:** all
- **Severity:** warning
- **Check:** Money error strings include a funds-status statement + a next action; no user-blaming phrasing; no bare codes; terms consistent with [[FIN-005]] states.
- **See also:** [[FIN-005]], [[FIN-008]], [[FIN-010]], [[FIN-014]]

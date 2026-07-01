# Example Spec — Checkout

> Purpose: Reference specification for a trustworthy, low-friction checkout flow — guest checkout, native Pay, honest totals, an editable review step, and an idempotent payment that cannot double-charge. This is a spec, not code — it defines intent, the 7-state map (with payment-processing as the safety-critical state), layout/thumb-zone, accessibility, tokens, motion, and the validator-backed acceptance gate. Implementations live in `checkout/<framework>/`.

## Contents
- [Intent / user goal](#intent--user-goal)
- [Platforms & frameworks](#platforms--frameworks)
- [Patterns & rules used](#patterns--rules-used)
- [Flow & layout](#flow--layout)
- [Thumb-zone](#thumb-zone)
- [States map (all 7)](#states-map-all-7)
- [Payment-processing (safety-critical)](#payment-processing-safety-critical)
- [Accessibility](#accessibility)
- [Token usage](#token-usage)
- [Motion](#motion)
- [Acceptance checklist](#acceptance-checklist)

---

## Intent / user goal

"Let me pay quickly, without surprises, and trust that it worked." The user reviews their cart, provides address + payment (ideally via native Pay or a saved method), confirms an honest total, and receives clear confirmation with a receipt.

**Success = a completed, correctly-charged order in the fewest steps, with zero hidden fees and zero double-charge risk.**

## Platforms & frameworks

- **Paradigm:** Adaptive. **Apple Pay** on iOS, **Google Pay** on Android, surfaced early and platform-styled ([[PAY-001]], [[PLAT-007]]). Native date/address pickers per platform ([[PLAT-006]]).
- **Frameworks (v1, flagship = all four):** Flutter, React Native, SwiftUI, Jetpack Compose — each integrating the platform Pay sheet and its keyboard-avoidance primitive.

## Patterns & rules used

- Patterns: [`checkout-patterns.md`](../../patterns/checkout-patterns.md), [`form-flows.md`](../../patterns/form-flows.md), [`empty-error-offline.md`](../../patterns/empty-error-offline.md).
- Rules: [[PAY-001]]…[[PAY-009]], [[AUTH-010]] (guest), [[FRM-013]] (review step), [[FRM-014]] (card masking, paste-safe), [[A11Y-015]] (accessible auth/paste), [[BTN-008]] (button states outcome), [[BTN-003]] (loading/disabled), [[BDG-001]] (cart Undo), [[TYP-006]] (tabular numerals), [[L10N-005]] (locale currency).

## Flow & layout

```
CART → CHECKOUT
  ├─ Identity: [ Continue as guest ]  or  sign in     [[PAY-003]] [[AUTH-010]]
  ├─ Native Pay shortcut (Apple/Google Pay)           [[PAY-001]]
  ├─ Address / shipping (autofill, validate)          [[PAY-009]]
  ├─ Payment (native Pay / saved card / new card)     [[PAY-005]]
  ├─ Review: line items + FULL itemized total, editable  [[PAY-002]] [[PAY-006]]
  └─ Pay $X → PROCESSING → CONFIRMATION + receipt      [[PAY-007]] [[PAY-008]]
```

- **Order summary always visible** (subtotal, shipping, tax, discount, total) — no surprise at the end ([[PAY-006]]).
- Fewest steps: if native Pay carries address + card, collapse to a single sheet ([[PAY-001]]).
- Single content column on compact; wider screens may show cart + summary side-by-side ([[GRD-001]], [[GRD-003]]).

## Thumb-zone

| Zone | Contents |
|---|---|
| Bottom arc (easy reach) | The **one primary action** per step — sticky, full-width, showing the amount ("Pay $48.20") ([[BTN-007]], [[BTN-008]]) |
| Middle | Line items, address form, payment selection, review summary |
| Top | Step title / progress, back/close, summary toggle |

The pay action is never a small top link; destructive/edit actions are secondary, out of the primary arc ([[BTN-006]]).

## States map (all 7)

| State | When | How it looks |
|---|---|---|
| **Ideal** | Ready to pay | Items + honest total; native Pay available; review editable; Pay button shows the amount. |
| **Empty** | No items | Empty-cart state with a "Browse" CTA — not a dead end ([[STATE-002]]). |
| **Loading** | Computing totals / placing order | Totals recompute with inline progress; on Place Order the button disables + spins and is **idempotent** ([[STATE-005]], [[PAY-007]]). |
| **Error** | Declined / network fail | Specific, recoverable message ("Card declined — try another method"); **all entered data preserved**; retry without re-entry ([[STATE-007]], [[PAY-004]], [[FRM-009]]). |
| **Offline** | No connectivity | The charge is **blocked with a clear reason**; cart + entries preserved; retry when back online — never silently fire or double-fire ([[STATE-008]], [[OFF-002]]). |
| **Success** | Order placed | Confirmation screen: order number, receipt, ETA, next steps (track/view); offer "save details / create account" ([[STATE-009]], [[PAY-008]]). |
| **Permission-denied** | Biometric/NFC for Pay unavailable | Explain + fall back to manual card entry; never block checkout on it ([[STATE-010]], [[PERM-004]]). |

## Payment-processing (safety-critical)

The most safety-critical state in the whole skill ([[PAY-007]]):

- **Idempotent submit** — a client-side idempotency key so a retry or double-tap cannot create two charges.
- Button **disabled + spinner** the instant it's tapped; no second tap possible ([[BTN-003]]).
- **Definitive outcome** — resolve to a clear success or a clear, recoverable failure; **never an ambiguous limbo**.
- No fake progress bars; progress reflects the real operation ([[PRG-001]]).
- If the network drops mid-charge, reconcile on reconnect and show the true result rather than re-charging.

## Accessibility

- **Accessible auth / paste (3.3.8):** card, expiry, CVV, and address fields allow paste, autofill, and password managers; card masking never blocks paste ([[A11Y-015]], [[FRM-014]]).
- Every field labeled and error-associated; correct keyboards (number pad for card/CVV, zip) ([[A11Y-004]], [[FRM-002]]).
- **Order total and any change to it are announced** via a live region; processing announces "Processing payment"; result announces success/failure ([[A11Y-019]]).
- Native Pay buttons expose correct role/label; step progress announced ([[A11Y-005]], [[A11Y-017]]).
- Totals not conveyed by color/emphasis alone; contrast ≥4.5:1 both themes ([[A11Y-012]], [[A11Y-001]], [[DRK-004]]).
- **Tabular figures + locale currency/date** formatting ([[TYP-006]], [[L10N-005]]).
- Targets ≥44pt/48dp; Dynamic Type to 200% keeps totals/labels legible without clipping ([[A11Y-003]], [[A11Y-010]]).
- RTL mirrors layout; currency/number formatting follows locale ([[L10N-001]], [[L10N-005]]).

## Token usage

| Element | Token |
|---|---|
| Screen / summary background | `color.surface` / `color.surface.container` |
| Total emphasis text | `type.title.md`, tabular; `color.on.surface.strong` |
| Primary Pay button | `color.action.primary` / `color.on.action.primary` |
| Security / trust cue | `color.status.success` (honest, paired with text/icon) |
| Error text | `color.status.error` + icon ([[COL-003]]) |
| Native Pay button | platform-standard styling (Apple/Google spec, not re-tokenized) |
| Field / step spacing | `space.4` field gap, `space.4` edge; review rows `space.3` |
| Button radius / min height | `radius.md` / `size.target.min` |

Zero literals except platform-mandated native Pay styling ([[COL-001]], [[SPC-004]]); `token_lint.py` clean.

## Motion

- Step transitions: horizontal shared-axis, small tier; reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Total updates: subtle number transition so a change is noticed ([[MOT-001]]).
- Processing: honest determinate/indeterminate progress matching the operation ([[PRG-001]]).
- Success: brief check animation, then the receipt (never gate the receipt behind it) ([[MIC-002]], [[MOT-005]]).
- Only transform/opacity; no distracting motion during payment ([[PERF-001]]).

## Acceptance checklist

Validators (`run_all.py`):

- [ ] `token_lint.py` PASS — tokens only (native Pay styling excepted) ([[COL-001]]).
- [ ] `contrast_check.py` PASS — totals/labels ≥4.5:1, both themes ([[A11Y-001]]).
- [ ] `target_size_lint.py` PASS — Pay/edit/steppers ≥44pt/48dp, ≥8dp apart ([[A11Y-003]]).
- [ ] `state_coverage.py` PASS — empty/loading/error/offline (+ success, processing) ([[STATE-001]]).
- [ ] `dynamic_type_check.py` PASS — totals/labels reflow to 200% ([[A11Y-010]]).
- [ ] `rtl_check.py` PASS — layout + currency mirror/localize ([[L10N-001]], [[L10N-005]]).

Manual / prose:

- [ ] Guest checkout offered prominently; account ask deferred to post-purchase ([[PAY-003]]).
- [ ] Native Pay surfaced early; saved methods one-tap ([[PAY-001]], [[PAY-005]]).
- [ ] Total always visible, itemized, honest, unchanged at charge ([[PAY-006]]).
- [ ] Editable review step before charge ([[PAY-002]], [[FRM-013]]).
- [ ] Pay button states the amount; processing disables it and is idempotent (no double-charge) ([[BTN-008]], [[PAY-007]]).
- [ ] Card/address allow paste + autofill; declines preserve all input ([[A11Y-015]], [[FRM-009]]).
- [ ] Offline blocks the charge safely (no silent/double fire) ([[OFF-002]]).
- [ ] Confirmation with order number + receipt + next steps ([[PAY-008]]).
- [ ] Totals/processing/result announced to assistive tech ([[A11Y-019]]).
- [ ] No hidden fees or dark patterns; reduce-motion respected ([[MOT-004]]).

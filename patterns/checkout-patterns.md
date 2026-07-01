# Checkout Patterns

> Purpose: Move a user from cart to confirmed purchase with the least friction and the most trust — offer guest checkout, surface native Pay early, keep totals honest and always visible, review before charging, and make a failed or double-tapped payment impossible to turn into a double charge. Checkout is where UX quality converts directly to revenue.

## Contents
- [When to use](#when-to-use)
- [Flow shape](#flow-shape)
- [Cart](#cart)
- [Guest checkout & native Pay](#guest-checkout--native-pay)
- [Address & shipping](#address--shipping)
- [Payment](#payment)
- [Review & confirm](#review--confirm)
- [Trust & transparency](#trust--transparency)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states](#the-7-states)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

Any purchase, subscription, top-up, or booking payment flow. Builds on [form-flows.md](form-flows.md) (address/card entry) and is the flagship of the E-commerce industry pack.

## Flow shape

```
CART  → (native Pay shortcut?) → CHECKOUT
                                  ├─ Identity: GUEST or sign-in (don't force account) [[PAY-003]] [[AUTH-010]]
                                  ├─ ADDRESS / shipping (autofill, validate)          [[PAY-009]]
                                  ├─ PAYMENT (native Pay / saved / new card)          [[PAY-001]] [[PAY-005]]
                                  ├─ REVIEW: line items + full total, editable        [[PAY-002]] [[PAY-006]]
                                  └─ PLACE ORDER → processing → CONFIRMATION + receipt [[PAY-007]] [[PAY-008]]
```

Fewest steps possible. If native Pay (Apple Pay / Google Pay) is available and has address + card, collapse the whole flow into **one sheet** ([[PAY-001]]).

## Cart

- Each line: image, name, variant, qty stepper, unit + line price; edit/remove inline with **Undo** ([[BDG-001]]).
- **Order summary always visible**: subtotal, shipping, tax, discounts, and a prominent **total** — no surprises later ([[PAY-006]]).
- Quantity changes update the total optimistically ([[OFF-001]]).
- Empty cart is a real empty state with a path back to browse ([[STATE-002]]).
- Primary CTA "Checkout" is a sticky, thumb-reachable, full-width button showing the total ([[BTN-007]], [[SPC-016]]).

## Guest checkout & native Pay

- **Offer guest checkout** prominently; never force account creation to buy ([[PAY-003]], [[AUTH-010]]). Offer account creation *after* purchase ("Save your details?").
- Surface **native Pay** buttons early and styled to platform spec (Apple Pay on iOS, Google Pay on Android) — they carry address + card and cut the flow to seconds ([[PAY-001]], [[PLAT-007]]).
- Saved payment methods for returning users, selectable in one tap ([[PAY-005]]).
- Don't bury guest checkout beneath a login wall or make it the visually weaker option.

## Address & shipping

- Use platform **autofill / contact autofill**; validate and format as the user types ([[PAY-009]], [[FRM-007]], [[FRM-014]]).
- Distinct fields with correct keyboards (postal code = number/zip, phone = phone) ([[FRM-002]]).
- Let users pick a saved address; support separate billing/shipping only when needed (progressive disclosure).
- Show shipping options with price + ETA; the selection updates the always-visible total ([[PAY-006]]).

## Payment

- Native Pay first; then saved cards; then a new-card form.
- Card fields: masked, formatted, **paste-allowed**, with card-type detection; CVV/expiry with numeric keyboards ([[FRM-014]], [[A11Y-015]], [[FRM-002]]).
- Security cues near the card fields (lock icon, "encrypted") that are honest, not decorative ([[PAY-004]] trust).
- **Never store or log full PAN / CVV**; tokenize via the platform/PSP.
- Errors (declined, expired) are specific and recoverable, preserving all other entries ([[PAY-004]], [[FRM-009]]).

## Review & confirm

- A **review step before the charge**: all line items, address, payment method, shipping, and the **final total** with every fee itemized ([[PAY-002]], [[PAY-006]]).
- Each section is **editable** (jump back) without losing progress ([[FRM-013]]).
- The action button reads the outcome explicitly: "Pay $48.20", not "Submit" ([[BTN-008]]).
- Placing the order enters a **processing state** that disables the button and **prevents double-submit / double-charge** ([[PAY-007]], [[BTN-003]]).

## Trust & transparency

- No hidden fees; total shown early and unchanged at charge time ([[PAY-006]]).
- Clear return/refund/cancellation info reachable before purchase.
- Honest security signals; real merchant identity; no fake scarcity/pressure dark patterns.
- Confirmation with an **order number + receipt** and clear next steps (track order, view details) ([[PAY-008]], [[STATE-009]]).

## Thumb-zone layout

| Zone | Checkout role |
|---|---|
| Bottom arc | The single primary action of each step (Checkout / Continue / Pay $X) — sticky, full-width, showing the amount |
| Middle | Line items, address form, payment selection, review summary |
| Top | Step title / progress; Back/close; order summary toggle |

The pay action stays in the easy-reach arc; it is never a small top-right link. Destructive/edit actions are secondary and out of the primary arc ([[BTN-006]]).

## The 7 states

| State | Checkout behavior |
|---|---|
| Ideal | Steps flow; totals compute; native Pay available |
| Empty | Empty cart with a browse CTA ([[STATE-002]]) |
| Loading | Computing totals/shipping and **placing the order**: progress + disabled button, no double-submit ([[STATE-005]], [[PAY-007]]) |
| Error | Payment declined / network fail → specific, recoverable error; all entered data preserved; retry without re-entry ([[STATE-007]], [[PAY-004]], [[FRM-009]]) |
| Offline | Block the actual charge with a clear message; keep the cart/entries; retry when back online — never silently drop or double-fire ([[STATE-008]], [[OFF-002]]) |
| Success | Confirmation screen: order number, receipt, ETA, next steps ([[STATE-009]], [[PAY-008]]) |
| Permission-denied | Rare (e.g., NFC/biometric for Pay); explain + fallback to card ([[STATE-010]], [[BIO-001]] where present) |

**Payment-processing is the most safety-critical state in the whole skill:** idempotent submit, disabled button, spinner, and a definitive success/failure — never an ambiguous limbo.

## Accessibility

- Order total and any change to it are announced via a live region ([[A11Y-019]]).
- Every field labeled and error-associated; card/expiry/CVV allow paste and autofill ([[A11Y-004]], [[A11Y-015]]).
- Native Pay buttons expose their proper accessible role/label; step progress is announced ([[A11Y-005]], [[A11Y-017]]).
- Price/total contrast ≥4.5:1 in both themes; totals not conveyed by color/emphasis alone ([[A11Y-001]], [[A11Y-012]]).
- Processing state announces "Processing payment, please wait"; result announces success/failure ([[A11Y-019]]).
- Numbers use tabular figures and locale-correct currency formatting ([[TYP-006]], [[L10N-005]]).

## Motion

- Step transitions: horizontal shared-axis, small tier; reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Processing: determinate/indeterminate progress consistent with the actual operation; no fake progress bars ([[PRG-001]]).
- Success: a brief confirmation animation (check), then the receipt — don't gate the receipt behind it ([[MIC-002]], [[MOT-005]]).
- Total updates: animate the number change subtly so it's noticed but not distracting ([[MOT-001]]).

## Applied rules

| Intent | Rule |
|---|---|
| Native Pay buttons | [[PAY-001]] |
| Review before charge | [[PAY-002]] |
| Guest checkout | [[PAY-003]] |
| Error recovery | [[PAY-004]] |
| Saved payment methods | [[PAY-005]] |
| Total transparency | [[PAY-006]] |
| No double-charge / processing | [[PAY-007]] |
| Confirmation + receipt | [[PAY-008]] |
| Address autofill/validate | [[PAY-009]] |
| Card masking, paste-safe | [[FRM-014]], [[A11Y-015]] |
| Editable review step | [[FRM-013]] |
| Sticky primary w/ amount | [[BTN-007]], [[BTN-008]] |
| Undo on cart edits | [[BDG-001]] |
| Announce total changes | [[A11Y-019]] |
| Tabular/locale currency | [[TYP-006]], [[L10N-005]] |

## Anti-patterns

- ❌ Forcing account creation before allowing purchase ([[PAY-003]]).
- ❌ Hiding fees until the final screen (total jumps at charge time) ([[PAY-006]]).
- ❌ "Submit" button with no amount and no double-submit guard → double charge ([[PAY-007]], [[BTN-008]]).
- ❌ Clearing the card form on a decline ([[FRM-009]]).
- ❌ Blocking paste in card/CVV fields ([[A11Y-015]]).
- ❌ Native Pay hidden below a long manual form ([[PAY-001]]).
- ❌ Ambiguous processing limbo with no definitive success/fail ([[PAY-007]]).
- ❌ Dark patterns: fake countdowns, pre-checked add-ons, disguised guest option.

## Acceptance checklist

- [ ] Guest checkout offered prominently; account ask deferred to after purchase ([[PAY-003]], [[AUTH-010]]).
- [ ] Native Pay surfaced early, platform-styled; saved methods one-tap ([[PAY-001]], [[PAY-005]]).
- [ ] Order total always visible, itemized, honest, and unchanged at charge ([[PAY-006]]).
- [ ] Review step before charge; every section editable without data loss ([[PAY-002]], [[FRM-013]]).
- [ ] Pay button states the amount; processing disables it and is idempotent (no double-charge) ([[BTN-008]], [[PAY-007]]).
- [ ] Address + card autofill/paste allowed; declines are specific and preserve all input ([[PAY-009]], [[A11Y-015]], [[FRM-009]]).
- [ ] Confirmation with order number + receipt + next steps ([[PAY-008]]).
- [ ] All 7 states, with offline blocking the charge safely (no silent drop/double-fire) ([[STATE-001]], [[OFF-002]]).
- [ ] Totals/processing/result announced to assistive tech; currency locale-correct ([[A11Y-019]], [[L10N-005]]).
- [ ] No hidden fees or dark patterns; refund/return info reachable pre-purchase.

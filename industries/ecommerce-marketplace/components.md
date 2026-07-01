# E-commerce / Marketplace — Domain Components

> Domain-specific components and their required states/behaviors. Each maps to core
> component rules (`[[BTN-…]]`, `[[LST-…]]`, `[[BDG-…]]`) and adds commerce
> constraints. Build these token-driven; no magic values.

## Table of contents

1. [Product card](#1-product-card)
2. [Price & discount label](#2-price--discount-label)
3. [Cart badge](#3-cart-badge)
4. [Quantity stepper](#4-quantity-stepper)
5. [Wishlist / save toggle](#5-wishlist--save-toggle)
6. [Native Pay button](#6-native-pay-button)
7. [Rules](#rules)

---

## 1. Product card

The atomic unit of the catalog. One shared component; used in grids, carousels, and
search results.

- **One primary tap target.** The whole card (or its image + title region) navigates
  to the PDP. Save/wishlist is a **distinct secondary** control with its own hit area,
  so tapping "save" never accidentally opens the PDP and vice-versa (`[[SHOP-012]]`,
  core `[[A11Y-005]]`).
- **Composed of** image (lazy-loaded, alt text — `[[SHOP-020]]`, core `[[PERF-005]]`),
  title (truncated consistently), price with any discount (`[[SHOP-009]]`), rating
  summary (`[[SHOP-021]]`), and optional badges (e.g. "Free shipping," "Low stock").
- **Stock and promo cues are non-color.** "Low stock" or "Sold out" uses text/icon,
  not a red tint alone (core `[[COL-005]]`, `[[A11Y-014]]`).
- **Press feedback.** Card and save control give a press scale + haptic on tap (core
  `[[MIC-002]]`).

## 2. Price & discount label

Price is the most scrutinized number on the screen; render it precisely and honestly.

- **Tabular numerals, locale-formatted.** Currency symbol/code, grouping, and decimals
  follow the user's locale; digits are tabular so prices align in lists (core
  `[[TAB-004]]`, `[[L10N-005]]`).
- **Was/now discounts are truthful.** When showing a strikethrough "was" price, it must
  be a real prior price; show the current price dominantly and, where used, a "% off"
  that matches the arithmetic (`[[SHOP-009]]`). No fake anchors.
- **Unit price where relevant** (per 100g, per item in a pack) for groceries and
  bulk goods.
- **Accessible reading.** The strikethrough "was" price is announced as the original
  price and the current price as the price to pay — not read as one run-on number
  (`[[SHOP-021]]`).

## 3. Cart badge

- **Count is accurate and reconciled.** The badge reflects the server-truth item count
  (or distinct-lines count — pick one and be consistent), updates optimistically on
  add, and corrects on rollback (`[[SHOP-010]]`, `[[SHOP-002]]`, core `[[BDG-005]]`).
- **Change is announced.** When the count changes, it's announced to assistive tech via
  a live region ("Cart, 3 items"), and the badge has an accessible label — never a
  bare "3" with no context (`[[SHOP-010]]`, core `[[A11Y-011]]`, `[[A11Y-007]]`).
- **Zero state.** An empty cart shows no numeric badge (or a documented empty
  affordance), never "0" glued to the icon.

## 4. Quantity stepper

- **Enforces min/max and stock.** Decrement stops at 1 (or offers remove), increment
  stops at available stock or per-order cap, with a message when a cap is hit
  (`[[SHOP-013]]`). The typed value is validated the same way.
- **Targets and feedback.** `+`/`−` controls meet minimum target size (core
  `[[A11Y-005]]`); each change updates the line total optimistically and reconciles
  (`[[SHOP-002]]`).
- **Announced.** The current quantity and its changes are exposed to assistive tech
  with a labeled role and state (core `[[A11Y-007]]`, `[[A11Y-011]]`).

## 5. Wishlist / save toggle

- **Clear two-state affordance.** Saved vs not-saved differ by more than color — icon
  fill/shape change plus an accessible state — and the control's label reflects the
  action/state ("Save," "Saved") (`[[SHOP-011]]`, core `[[A11Y-007]]`, `[[COL-005]]`).
- **Immediate, honest feedback.** Toggling gives instant visual + haptic feedback (core
  `[[MIC-002]]`) and, if the save is a server write, reconciles like the cart with
  rollback on failure (`[[SHOP-002]]`).
- **Doesn't hijack navigation.** As a secondary control on a card, it never triggers
  PDP navigation (`[[SHOP-012]]`).

## 6. Native Pay button

- **Surfaced first, styled per platform.** Where Apple Pay / Google Pay is available,
  its button appears at the top of the payment step using the platform-provided
  component and branding — not a custom look-alike (`[[SHOP-008]]`, core `[[PAY-001]]`).
- **Falls back gracefully.** When native Pay is unavailable, card entry is
  paste/autofill/passkey-friendly (core `[[AUTH-003]]`) and the manual path is not
  hidden or penalized.
- **Amount-labeled commit.** The final pay action states the amount ("Pay $64.20"),
  and the full total was shown on review before this point (`[[SHOP-017]]`).

---

## Rules

### SHOP-008 — Surface the native Pay button first at checkout
- **Rule:** When a platform express-payment method (Apple Pay, Google Pay) is available on the device, checkout MUST present its official, platform-styled button prominently at the top of the payment step, above manual card entry. Custom look-alike buttons MUST NOT substitute for the native component. When unavailable, manual entry MUST remain fully functional and paste/autofill/passkey-friendly.
- **Why:** Native Pay is faster, more secure (tokenized), and converts markedly better on mobile; burying it below a card form leaves conversion and trust on the table.
- **Platforms:** iOS (Apple Pay), Android (Google Pay)
- **Severity:** warning
- **Check:** On a device with express pay configured, the native button renders first using the platform component; disabling it reveals a working, autofill-friendly manual path.
- **See also:** [[SHOP-003]], [[SHOP-017]], [[PAY-001]], [[AUTH-003]]

### SHOP-009 — Render price and discounts with clarity and honesty
- **Rule:** Prices MUST use tabular numerals and locale currency formatting. When a discount is shown, the current price MUST be dominant; any "was"/strikethrough price MUST reflect a genuine prior price and any "% off" MUST match the arithmetic. Show unit price where relevant. The app MUST NOT display fabricated reference prices or misleading discount math.
- **Why:** Price is decision-critical and legally sensitive; fake anchors and mismatched percentages are deceptive, erode trust, and draw regulatory scrutiny.
- **Platforms:** all
- **Severity:** error
- **Check:** Discounted items show current price dominant, a truthful was-price, and a % that equals (was−now)/was; amounts use tabular/locale formatting; unit price present where applicable.
- **See also:** [[SHOP-017]], [[SHOP-021]], [[TAB-004]], [[L10N-005]], [[SHOP-019]]

### SHOP-010 — Keep the cart badge accurate and announce changes
- **Rule:** The cart badge MUST reflect the reconciled server item count (using a consistent counting rule), update optimistically on add/remove, and correct on rollback. Changes MUST be announced to assistive tech via a live region and the badge MUST carry an accessible label with context ("Cart, 3 items"), never a bare number.
- **Why:** An inaccurate or silent badge misleads users about what they're buying and is invisible to screen-reader users; accuracy plus announcement keeps the cart trustworthy for everyone.
- **Platforms:** all
- **Severity:** warning
- **Check:** Add/remove items and force a rollback: badge tracks the true count, corrects on failure, announces via live region, and exposes a contextual label to AT.
- **See also:** [[SHOP-002]], [[SHOP-013]], [[BDG-005]], [[A11Y-011]], [[A11Y-007]]

### SHOP-011 — Give the wishlist/save toggle a clear affordance and feedback
- **Rule:** A save/wishlist control MUST distinguish saved from not-saved by more than color (icon fill/shape plus accessible state), expose its state and action to assistive tech, and give immediate visual + haptic feedback on toggle. If saving is a server write, it MUST reconcile with rollback on failure.
- **Why:** Save is a low-commitment engagement action that only works if its state is unambiguous and perceivable without color; ambiguous toggles frustrate and get abandoned.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Toggle save on a card/PDP: saved vs unsaved differ non-color, state is announced, feedback is immediate, and a failed save reverts visibly.
- **See also:** [[SHOP-012]], [[SHOP-002]], [[COL-005]], [[A11Y-007]], [[MIC-002]]

### SHOP-012 — Product card: one primary tap target plus a distinct secondary save
- **Rule:** A product card MUST have a single primary tap target that navigates to the PDP and, when a save/wishlist control is present, that control MUST be a distinct secondary target with its own adequately sized hit area. Tapping save MUST NOT navigate, and tapping the card body MUST NOT toggle save.
- **Why:** Overlapping or ambiguous targets cause mis-taps — opening a PDP when the user meant to save, or vice-versa — which is a common, avoidable mobile-grid frustration.
- **Platforms:** all
- **Severity:** warning
- **Check:** On a card with a save control, tap the save icon and the card body separately: each performs only its own action; both hit areas meet minimum target size and don't overlap.
- **See also:** [[SHOP-011]], [[SHOP-001]], [[A11Y-005]], [[MIC-002]]

### SHOP-013 — Enforce quantity limits and stock in the stepper
- **Rule:** The quantity stepper MUST enforce a minimum (stop at 1 or offer remove), a maximum bounded by available stock and any per-order cap, and MUST message the user when a cap is reached. Typed quantities MUST be validated the same way. Quantity changes update the line/cart total optimistically and reconcile with the server; the current quantity is exposed to assistive tech.
- **Why:** Letting users add more than is available produces checkout failures and disappointment; unbounded steppers create bad totals and support load.
- **Platforms:** all
- **Severity:** warning
- **Check:** Increment past available stock and past any cap: the stepper stops and explains why; typing an over-limit value is corrected; quantity and changes are announced to AT.
- **See also:** [[SHOP-002]], [[SHOP-007]], [[A11Y-005]], [[A11Y-011]]

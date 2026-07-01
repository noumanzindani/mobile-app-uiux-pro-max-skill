# E-commerce / Marketplace — Screen Patterns

> Domain screen recipes: how core rules combine into correct shopping flows. Rules
> here govern catalog browsing, product detail, cart behavior, and the checkout
> funnel. Cross-references use `[[ID]]`; core rules are referenced, never restated.

## Table of contents

1. [Catalog: product grid & list](#1-catalog-product-grid--list)
2. [Filter & sort](#2-filter--sort)
3. [Search & zero-results](#3-search--zero-results)
4. [Product detail (PDP)](#4-product-detail-pdp)
5. [Cart & optimistic add-to-cart](#5-cart--optimistic-add-to-cart)
6. [Checkout funnel (cart → address → pay → confirm)](#6-checkout-funnel)
7. [Guest checkout & the account wall](#7-guest-checkout--the-account-wall)
8. [Rules](#rules)

---

## 1. Catalog: product grid & list

The catalog is where most sessions live, so it must reflow gracefully and load fast.

- **Responsive across size classes.** One column on compact phones, two-to-three on
  large phones and small tablets, and a genuine multi-pane or wider grid at ≥840dp
  (`[[SHOP-001]]`, core `[[GRD-001]]`, `[[GRD-004]]`). Don't stretch two phone-width
  columns across a tablet; recompute column count from available width, not device
  name.
- **Virtualized and lazy.** Long catalogs use a virtualized list/grid so scroll stays
  smooth (core `[[LST-001]]`), images load lazily (core `[[PERF-005]]`), and initial
  paint shows skeleton cards, not a spinner over blank space (core `[[LST-002]]`).
- **Card is a summary, PDP is the detail.** Each card carries image, title, price
  (with discount if any, `[[SHOP-009]]`), rating, and one primary tap target plus an
  optional secondary save control (`[[SHOP-012]]`). Everything else waits for the PDP.
- **Grid vs list toggle** (when offered) preserves scroll position and applied
  filters across the switch.

## 2. Filter & sort

Filtering is how users cut a 10,000-item catalog down to a decision. It must be
legible in every state.

- **Applied state is visible and non-color-only.** Active filters render as chips or
  a labeled count ("Filters · 3"), and a selected filter is marked by more than color
  — a check, fill, or bold weight (`[[SHOP-006]]`, core `[[CHP-001]]`).
- **Filtered-empty is its own state.** "No items match these filters" is different
  from "this category is empty" and different from a network error. It must offer a
  one-tap **Clear filters** and, ideally, name the constraint that eliminated
  everything (`[[SHOP-006]]`, and see §3, `[[SHOP-005]]`).
- **Cleared state returns cleanly.** Clearing filters restores the full result set and
  resets the applied-count indicator to zero; it never leaves stale chips behind.
- **Sort is explicit and sticky.** The current sort ("Sort: Price low→high") is always
  visible, and changing it re-runs against the current filter set, not the whole
  catalog.

## 3. Search & zero-results

- **Zero-results is a designed screen, not a blank.** When a query returns nothing,
  show a distinct empty state that (a) restates the query, (b) suggests a fix (check
  spelling, broaden terms, remove a filter), and (c) offers an escape hatch —
  popular categories, recent items, or "browse all" (`[[SHOP-005]]`, core
  `[[SRCH-005]]`). Never show the same visual as "still loading."
- **Distinguish the empties.** No-query-yet (suggestions), zero-results
  (actionable), and filtered-empty (`[[SHOP-006]]`) are three different states — as
  are loading, error, and offline (core `[[STATE-001]]`, `[[STATE-004]]`).

## 4. Product detail (PDP)

The PDP is where the buy decision happens. Optimize for confidence and thumb reach.

- **Gallery first.** A swipeable image gallery with pagination dots, pinch-zoom, and
  alt text on every image (`[[SHOP-007]]`, `[[SHOP-020]]`). Show real product photos;
  don't hide variant differences behind a single stock shot.
- **Variants are unmistakable.** Size/color/style selectors show availability per
  option; an out-of-stock variant is disabled with a non-color cue and a reason, not
  silently missing (`[[SHOP-007]]`, `[[SHOP-013]]`). Selecting a variant updates
  price, image, and stock.
- **Price and discount are honest.** Was/now, unit price, and % off render clearly and
  truthfully (`[[SHOP-009]]`).
- **Add-to-cart is in the thumb zone; irreversible steps are not.** The primary
  **Add to cart** button is reachable one-handed, often as a sticky bottom bar
  (`[[SHOP-007]]`, core `[[A11Y-005]]`). Adding to cart is reversible and optimistic
  (§5); *paying* is the deliberate step, gated later in checkout.
- **Trust inline.** Ratings summary (`[[SHOP-015]]`), and in a marketplace the seller
  card with rating/fulfillment/returns (`[[SHOP-016]]`), sit near the buy button.

## 5. Cart & optimistic add-to-cart

Adding to cart should feel instant, but the cart is the source of truth for money, so
it must stay honest.

- **Optimistic, then reconciled.** On tap, immediately update the cart badge
  (`[[SHOP-010]]`) and show lightweight confirmation (snackbar, brief press
  animation with haptic per core `[[MIC-002]]`). Queue the write and reconcile with
  the server (core `[[OFF-002]]`).
- **Visible rollback on failure.** If the server rejects the add — out of stock, price
  changed, quantity capped — the optimistic change must **visibly roll back**: the
  badge decrements, and a clear message explains what happened and what to do
  (`[[SHOP-002]]`, `[[SHOP-018]]`). Never leave a phantom item that vanishes at
  checkout.
- **Undo, not surprise.** Removing an item offers Undo via snackbar (core
  `[[BDG-001]]`); accidental removal is one tap to recover.
- **Cart persists and survives offline.** Show last-known cart when offline with an
  "updating…" affordance; block checkout actions that need live stock/price and say
  why (core `[[STATE-004]]`, `[[OFF-002]]`).
- **Quantity edits respect stock.** The quantity stepper enforces min/max and stock
  limits (`[[SHOP-013]]`).

## 6. Checkout funnel

Canonical stages: **Cart → Address → Payment → Review → Confirmation.** Keep it
linear; one decision per step; always show where the user is and what's left.

1. **Cart** — line items, quantities, per-item and subtotal prices, and an obvious
   path forward. Estimated totals may appear here but the binding total comes before
   pay (`[[SHOP-017]]`).
2. **Address / shipping** — inputs use the correct keyboard and autofill (core
   `[[FRM-008]]`), validate inline (core `[[FRM-002]]`), and support saved addresses.
   Shipping options show cost and ETA.
3. **Payment** — native Pay (Apple Pay / Google Pay) is surfaced **first** where
   available (`[[SHOP-008]]`, core `[[PAY-001]]`); card entry is paste/autofill/
   passkey friendly (core `[[AUTH-003]]`).
4. **Review** — the single surface that shows the full, final total with taxes,
   shipping, and fees itemized before the charge (`[[SHOP-017]]`); the pay button is
   labeled with the amount ("Pay $64.20").
5. **Confirmation** — order number, itemized receipt, ETA, and a path to order status
   and support. Handle failure (declined card, address issue, item just sold out) as
   a first-class state with recovery, not a dead end (`[[SHOP-018]]`).

Never override the system back gesture between steps; back returns to the prior step
with input intact (core `[[NAV-003]]`).

## 7. Guest checkout & the account wall

- **Guest checkout comes before any account wall.** A first-time buyer must be able to
  reach payment without creating an account. Offer "Continue as guest" at least as
  prominently as "Sign in," and defer the *optional* account-creation offer to
  **after** the order is placed ("Save your details for next time?")
  (`[[SHOP-004]]`, core `[[PAY-003]]`).
- **No dark-pattern gating.** Do not disguise the guest path, pre-check "create an
  account," or require it to see the total. Forcing account creation to buy is a
  banned dark pattern (`[[SHOP-022]]`).
- **Email is enough to transact.** Collect only what fulfillment and receipts require;
  everything else is post-purchase and opt-in.

---

## Rules

### SHOP-001 — Make the product grid/list responsive across size classes
- **Rule:** Catalog grids/lists MUST recompute their column count and item sizing from available width — one column on compact widths (<600dp), two-to-three at medium widths, and a wider grid or two-pane layout at ≥840dp — rather than hard-coding a device-specific column count. Scroll position, applied filters, and sort MUST survive layout/orientation changes.
- **Why:** A layout tuned only for a 390dp phone wastes tablet and foldable space and breaks on rotation; width-driven reflow keeps density and tap targets correct on every size class.
- **Platforms:** all (tablet, foldable especially)
- **Severity:** warning
- **Check:** Resize/rotate and split-screen the catalog: columns change with width thresholds; targets stay ≥44pt/48dp; scroll and filter state persist. Confirm layout derives from width, not device model.
- **See also:** [[SHOP-007]], [[GRD-001]], [[GRD-004]], [[LST-001]], [[A11Y-005]]

### SHOP-002 — Make add-to-cart optimistic with a visible rollback on failure
- **Rule:** Add/update/remove-from-cart MAY update the UI optimistically, but a server rejection (out of stock, price change, quantity cap, network failure) MUST visibly roll the change back — decrement the badge, restore prior state — and surface a specific message. The app MUST NOT leave a phantom item that silently disappears later.
- **Why:** Optimistic UI makes shopping feel fast, but the cart drives money; a silent divergence between shown cart and server cart causes checkout failures, wrong totals, and lost trust.
- **Platforms:** all
- **Severity:** error
- **Check:** Force a server rejection (mock out-of-stock): the optimistic add reverses in the UI, the badge count corrects, and a reason is shown; no phantom line item remains at checkout.
- **See also:** [[SHOP-010]], [[SHOP-013]], [[SHOP-018]], [[OFF-002]], [[BDG-001]], [[BDG-005]]

### SHOP-003 — Use a linear, step-labeled checkout flow
- **Rule:** Checkout MUST progress through discrete, ordered steps (cart → address/shipping → payment → review → confirmation) with a visible indication of current step and progress. Each step validates before advancing; system back returns to the prior step with input intact. The binding order total appears on the review step before the charge.
- **Why:** A linear, transparent funnel reduces cognitive load and abandonment; hiding steps or collapsing address+pay+confirm into one dense screen increases errors and cart abandonment.
- **Platforms:** all
- **Severity:** error
- **Check:** Walk checkout: steps are ordered and labeled, progress is visible, back preserves input, and a review step precedes the charge. See [[SHOP-017]] for total.
- **See also:** [[SHOP-004]], [[SHOP-008]], [[SHOP-017]], [[PAY-001]], [[NAV-003]], [[FRM-002]]

### SHOP-004 — Offer guest checkout before any account wall
- **Rule:** A first-time buyer MUST be able to reach and complete payment without creating an account. A "Continue as guest" path MUST be at least as prominent as sign-in and MUST NOT be hidden, pre-empted, or blocked behind mandatory registration. Any account-creation offer is deferred to after the order is placed and is optional.
- **Why:** Forced registration is a top driver of checkout abandonment and a recognized dark pattern; guest checkout respects intent and converts better.
- **Platforms:** all
- **Severity:** error
- **Check:** From an empty session, complete a purchase without an account; guest path is visible and equal-weight to sign-in; account offer (if any) appears only post-order and is skippable.
- **See also:** [[SHOP-003]], [[SHOP-022]], [[PAY-003]]

### SHOP-005 — Make zero-results a distinct, actionable empty state
- **Rule:** A search or browse that returns no items MUST render a dedicated empty state that restates the query/constraint, suggests a concrete fix (spelling, broaden terms, remove a filter), and offers an escape (browse all, popular, recent). It MUST be visually distinct from loading, error, and offline states, and MUST NOT render as a blank scroll area.
- **Why:** A blank result screen reads as broken and dead-ends the session; an actionable empty state recovers the user toward a purchase.
- **Platforms:** all
- **Severity:** error
- **Check:** Search a nonsense query: a designed empty state appears with query echo, a suggested fix, and an escape action; it differs from the loading and error visuals.
- **See also:** [[SHOP-006]], [[STATE-001]], [[STATE-004]], [[SRCH-005]]

### SHOP-006 — Design filter & sort applied, empty, and cleared states
- **Rule:** Filter and sort UI MUST show (1) an applied state where active filters are indicated by more than color (chip, count, check/fill) and reversible, (2) a filtered-empty state distinct from category-empty that offers one-tap Clear filters, and (3) a cleared state that fully restores the result set and resets the applied indicator. Current sort MUST always be visible.
- **Why:** Users get stranded when they can't tell what's filtering the view or how to undo it; a filtered-empty screen that looks like "no products exist" causes abandonment.
- **Platforms:** all
- **Severity:** warning
- **Check:** Apply filters to an empty result: applied chips/count show non-color state, a Clear action is present, clearing restores results and zeroes the indicator; current sort is labeled throughout.
- **See also:** [[SHOP-005]], [[CHP-001]], [[STATE-001]], [[A11Y-014]]

### SHOP-007 — Product detail: gallery, variant clarity, thumb-zone add-to-cart
- **Rule:** The PDP MUST provide a swipeable, zoomable image gallery with alt text; variant selectors that show per-option availability and update price/image/stock on selection (out-of-stock options disabled with a non-color cue and reason); and a primary Add-to-cart control reachable in the one-handed thumb zone (commonly a sticky bottom bar). Add-to-cart is reversible; paying is the deliberate later step.
- **Why:** Confidence to buy depends on seeing the product and understanding exactly which variant, at what price and availability, is being added; unreachable or ambiguous controls depress conversion and cause wrong-variant orders.
- **Platforms:** all
- **Severity:** warning
- **Check:** On a variant product: gallery zooms and has alt text, selecting a variant updates price/image/stock, OOS variants are disabled with a reason, and Add-to-cart sits within thumb reach at ≥44pt/48dp.
- **See also:** [[SHOP-013]], [[SHOP-009]], [[SHOP-020]], [[A11Y-005]], [[MIC-002]]

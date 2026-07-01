# E-commerce / Marketplace — Industry Pack

> **Tier-3 industry pack.** Read this when the app sells physical or digital goods:
> single-brand storefronts, multi-vendor marketplaces, grocery/quick-commerce,
> fashion, electronics, resale, ticketing, or any flow that ends in a cart and a
> checkout. It layers **domain-specific** rules on top of the core corpus (`rules/`);
> it never restates core rules — it references them by ID (`[[PAY-001]]`).

## When to use this pack

Activate when the screen or flow involves any of:

- **Browsing catalog** — product grid/list, category pages, search, filter & sort.
- **Product detail** — gallery, variants, price, reviews, add-to-cart.
- **Cart & saved items** — add/remove, quantity, wishlist, "save for later."
- **Checkout** — address, shipping, payment, order review, confirmation.
- **Trust & conversion surfaces** — reviews/ratings, seller profiles, trust badges,
  price/discount display, total-cost breakdown.
- **Post-purchase** — order status, returns, and reorder (touch these lightly here;
  most live in the transactional-messaging and account areas of core).

If the product's core job **is** moving money between parties (a wallet, a P2P
transfer app), use the **Finance** pack instead and pull `[[PAY-001]]`-family rules
from core. Reach for this pack whenever the job is **discover → decide → buy**.

## The 5 most load-bearing patterns

These five carry the most weight in commerce UX. Get them right first.

1. **Frictionless add-to-cart with an honest rollback.** Adding to cart is
   optimistic — the badge and cart update instantly — but a server rejection
   (out of stock, price change) must visibly roll the change back and tell the user
   why, never silently swallow it. → `[[SHOP-002]]`, `[[SHOP-010]]`, core `[[OFF-002]]`, `[[BDG-001]]`, `[[BDG-005]]`.
2. **A linear, guest-first checkout.** Cart → address → pay → confirm, one clear
   step at a time, with **guest checkout offered before any account wall** and native
   Pay surfaced first. → `[[SHOP-003]]`, `[[SHOP-004]]`, `[[SHOP-008]]`, core `[[PAY-001]]`, `[[PAY-003]]`.
3. **Total-cost honesty before the charge.** Taxes, shipping, and fees are shown
   and summed into a dominant final total **before** the pay button is pressed — no
   surprise line items on the confirmation screen. → `[[SHOP-017]]`, `[[SHOP-009]]`, core `[[TAB-004]]`, `[[L10N-005]]`.
4. **Responsive catalog with real empty states.** The grid reflows across phone,
   tablet, and foldable size classes, and zero-results / filtered-empty are
   distinct, actionable states — not a blank scroll. → `[[SHOP-001]]`, `[[SHOP-005]]`, `[[SHOP-006]]`, core `[[GRD-001]]`, `[[GRD-004]]`, `[[SRCH-005]]`.
5. **Trustworthy price, review, and seller signals.** Was/now pricing and % off are
   truthful, ratings show count + distribution, and marketplace sellers expose
   rating, fulfillment, and returns — none of it color-only or fabricated.
   → `[[SHOP-009]]`, `[[SHOP-015]]`, `[[SHOP-016]]`, `[[SHOP-021]]`, core `[[A11Y-014]]`.

## Domain rules in this pack (SHOP-\*\*\*)

| ID | Title | File | Severity |
|---|---|---|---|
| [[SHOP-001]] | Responsive product grid/list across size classes | patterns.md | warning |
| [[SHOP-002]] | Optimistic add-to-cart with visible rollback | patterns.md | error |
| [[SHOP-003]] | Linear checkout flow (cart → address → pay → confirm) | patterns.md | error |
| [[SHOP-004]] | Offer guest checkout before any account wall | patterns.md | error |
| [[SHOP-005]] | Zero-results is a distinct, actionable empty state | patterns.md | error |
| [[SHOP-006]] | Filter & sort: applied, empty, and cleared states | patterns.md | warning |
| [[SHOP-007]] | Product detail: gallery, variants, thumb-zone add-to-cart | patterns.md | warning |
| [[SHOP-008]] | Native Pay button surfaced first at checkout | components.md | warning |
| [[SHOP-009]] | Price & discount clarity (was/now, unit price, % off) | components.md | error |
| [[SHOP-010]] | Cart badge count accuracy & live announcement | components.md | warning |
| [[SHOP-011]] | Wishlist/save toggle affordance & feedback | components.md | suggestion |
| [[SHOP-012]] | Product card: single primary tap target + secondary save | components.md | warning |
| [[SHOP-013]] | Quantity stepper & stock limits | components.md | warning |
| [[SHOP-014]] | Security & trust cues at payment | trust-and-safety.md | warning |
| [[SHOP-015]] | Reviews & ratings shown honestly | trust-and-safety.md | warning |
| [[SHOP-016]] | Seller trust signals in a marketplace | trust-and-safety.md | warning |
| [[SHOP-017]] | Total cost transparency before charge | trust-and-safety.md | error |
| [[SHOP-018]] | Error copy for declines, out-of-stock, address issues | copy-and-tone.md | warning |
| [[SHOP-019]] | Honest scarcity/urgency copy (no dark patterns) | copy-and-tone.md | warning |
| [[SHOP-020]] | Product images: alt text, zoom, non-color cues | accessibility.md | error |
| [[SHOP-021]] | Ratings & price announced to AT, not color-only | accessibility.md | error |
| [[SHOP-022]] | Ban dark patterns: forced account, hidden costs, fake urgency | pitfalls.md | error |

## Table of contents

- [`patterns.md`](./patterns.md) — catalog grid/list, product detail, cart + optimistic add, linear checkout, guest checkout, zero-results & filter states.
- [`components.md`](./components.md) — product card, price/discount label, cart badge, quantity stepper, wishlist toggle, native Pay button.
- [`trust-and-safety.md`](./trust-and-safety.md) — payment trust cues, honest reviews/ratings, seller signals, total-cost transparency.
- [`copy-and-tone.md`](./copy-and-tone.md) — voice, error microcopy, honest scarcity/urgency, do/don't tables.
- [`accessibility.md`](./accessibility.md) — image alt/zoom, non-color stock & price cues, ratings/price announced to AT.
- [`pitfalls.md`](./pitfalls.md) — the common commerce UX mistakes, dark-pattern bans, and how to avoid them.

## Core rules this pack leans on

`[[PAY-001]]` (native Pay / review before charge), `[[PAY-003]]` (guest checkout),
`[[OFF-002]]` (optimistic UI + queue + visible rollback), `[[STATE-001]]` (enumerate
the 7 states), `[[SRCH-005]]` (zero-results empty state), `[[GRD-001]]`/`[[GRD-004]]`
(responsive columns), `[[LST-001]]`/`[[LST-002]]` (virtualize + skeleton),
`[[BDG-005]]` (badge count accuracy), `[[CHP-001]]` (selected filter not color-only),
`[[A11Y-005]]` (44pt/48dp targets), `[[A11Y-011]]` (live-region announce),
`[[A11Y-014]]` (no color-only meaning), `[[TAB-004]]` (tabular numerals),
`[[L10N-005]]` (locale currency formatting), `[[PERF-005]]` (lazy images).

# E-commerce / Marketplace — Trust & Safety

> Trust signals at payment, honest reviews and ratings, seller credibility in a
> marketplace, and total-cost transparency. In commerce, trust is conversion: a buyer
> who doubts the price, the seller, or the security abandons the cart.

## Table of contents

1. [Payment trust cues](#1-payment-trust-cues)
2. [Reviews & ratings, shown honestly](#2-reviews--ratings-shown-honestly)
3. [Seller trust in a marketplace](#3-seller-trust-in-a-marketplace)
4. [Total-cost transparency](#4-total-cost-transparency)
5. [Rules](#rules)

---

## 1. Payment trust cues

At the moment of payment, the buyer is deciding whether it's safe to hand over money.
Reinforce legitimacy with honest, standard cues:

- **Secure-context indicators** — a lock/secure-checkout label, the accepted card
  network marks, and (where applicable) a "processed by <PSP>" line so the buyer knows
  who handles the card (`[[SHOP-014]]`).
- **PCI-safe input** — use native Pay first (`[[SHOP-008]]`, core `[[PAY-001]]`); never
  render or log full card numbers; card fields are paste/autofill/passkey friendly
  (core `[[AUTH-003]]`).
- **No dark patterns at the till** — no pre-checked add-ons, no fake countdowns on the
  pay button, no hidden fees revealed only after charge (`[[SHOP-017]]`, `[[SHOP-019]]`,
  and the bans in `[[SHOP-022]]`).

Trust is cumulative and fragile: one surprise fee (`[[SHOP-017]]`) or one fake "only 1
left!" (`[[SHOP-019]]`) undoes it.

## 2. Reviews & ratings, shown honestly

Reviews are the highest-leverage trust surface in commerce — and the easiest to render
dishonestly.

- **Show the count and the distribution, not just the average.** A "4.6" means little
  without "based on 812 reviews" and the star breakdown; a single 5-star review must
  not read like a consensus (`[[SHOP-015]]`).
- **Mark verified purchases** where the platform supports it, and don't hide negative
  reviews or sort them out of reach — filtering to low-star reviews must be possible
  (`[[SHOP-015]]`).
- **No fabricated ratings.** Don't seed default stars, inflate averages, or show a
  rating when there are zero reviews — an unrated item says "No reviews yet"
  (`[[SHOP-015]]`).
- **Accessible.** Star ratings are announced numerically to assistive tech, not left
  as color-only glyphs (`[[SHOP-021]]`, core `[[A11Y-014]]`).

## 3. Seller trust in a marketplace

In a multi-vendor marketplace the buyer is trusting a **seller**, not just the
platform. Surface the signals that let them judge:

- **Seller identity and rating** — name, aggregate rating with review count, and time
  on platform, reachable from the PDP (`[[SHOP-016]]`).
- **Fulfillment expectations** — who ships, dispatch/handling time, and estimated
  delivery, so "sold by X, fulfilled by Y" is unambiguous.
- **Returns & guarantees** — the return window, who pays return shipping, and any
  buyer-protection/guarantee, stated before purchase — not buried in a policy page
  (`[[SHOP-016]]`, `[[SHOP-017]]`).
- **Reporting** — a path to report a listing or seller keeps the marketplace safe and
  is expected by app-store and regional (e.g. EU DSA) policy.

## 4. Total-cost transparency

The single biggest trust-and-abandonment lever in checkout is whether the price the
buyer sees is the price they pay.

- **Show the full total before the charge.** Taxes, shipping, and any service/handling
  fees are itemized and summed into a dominant final total on the review step, in the
  charged currency, **before** the pay button is pressed (`[[SHOP-017]]`, core
  `[[TAB-004]]`, `[[L10N-005]]`).
- **No fee first appears after payment.** Every mandatory cost is disclosed at or
  before review; "drip pricing" (revealing fees one screen at a time, or only on the
  receipt) is a banned dark pattern (`[[SHOP-022]]`).
- **Estimates are labeled as estimates** until an address makes them exact; the binding
  total is unambiguous at the point of consent.

---

## Rules

### SHOP-014 — Show security & trust cues at payment
- **Rule:** The payment step MUST present honest security cues: a secure-checkout indicator, the accepted card-network marks, and (where a third party processes the card) a "processed by <PSP>" attribution. The app MUST NOT render or log full card numbers and MUST prefer tokenized native Pay. No pre-checked add-ons or fake urgency may appear on the payment surface.
- **Why:** Buyers abandon when a checkout feels unsafe or unfamiliar; standard, truthful security cues reduce doubt and phishing susceptibility, while dark patterns at the till destroy trust and invite regulatory action.
- **Platforms:** all
- **Severity:** warning
- **Check:** Payment step shows secure indicator + accepted networks + processor attribution; grep confirms no full-PAN render/log; audit for pre-checked add-ons and countdowns on the pay action.
- **See also:** [[SHOP-008]], [[SHOP-017]], [[SHOP-019]], [[SHOP-022]], [[PAY-001]], [[AUTH-003]]

### SHOP-015 — Show reviews & ratings honestly
- **Rule:** Rating displays MUST show the review count and, on detail surfaces, the star distribution alongside any average; MUST mark verified purchases where supported; MUST allow access to negative/low-star reviews (filtering/sorting to them is possible); and MUST NOT fabricate, seed, or inflate ratings or show a rating for an item with zero reviews (show "No reviews yet" instead).
- **Why:** Reviews drive purchase decisions; averages without counts or hidden negatives deceive buyers, and fabricated ratings are both a trust catastrophe and a legal risk.
- **Platforms:** all
- **Severity:** warning
- **Check:** Rated items show count (+ distribution on PDP); low-star reviews are reachable; verified badges present where supported; an unrated item shows "No reviews yet," not stars.
- **See also:** [[SHOP-016]], [[SHOP-021]], [[SHOP-019]], [[A11Y-014]]

### SHOP-016 — Surface seller trust signals in a marketplace
- **Rule:** In a multi-vendor marketplace, the PDP and checkout MUST identify the seller and surface seller rating with review count, fulfillment expectation (who ships, handling time, delivery ETA), and returns/guarantee terms (window, return-shipping responsibility, buyer protection) before purchase. A path to report a listing/seller MUST exist.
- **Why:** Buyers are trusting an unknown third-party seller; without visible seller credibility, fulfillment clarity, and return terms, marketplace purchases feel risky and abandonment rises — and reporting is increasingly legally required.
- **Platforms:** all
- **Severity:** warning
- **Check:** On a third-party listing: seller identity + rating/count, fulfillment/ETA, and return terms are visible pre-purchase; a report-listing/seller path is reachable.
- **See also:** [[SHOP-015]], [[SHOP-017]], [[SHOP-018]]

### SHOP-017 — Show the full total (taxes, shipping, fees) before the charge
- **Rule:** Before the pay action is pressed, the review surface MUST itemize every mandatory cost — subtotal, taxes, shipping, and any service/handling fees — and present a dominant final total in the charged currency. No mandatory cost may first appear after payment or be revealed one screen at a time (drip pricing). Estimates must be labeled as estimates until an address makes them exact.
- **Why:** Surprise fees are the top cause of cart abandonment and a core dark-pattern/consumer-protection concern; the buyer must consent to the exact amount they will be charged.
- **Platforms:** all
- **Severity:** error
- **Check:** At review, all fees are itemized and summed into a dominant total in the correct currency; no new mandatory charge appears on confirmation/receipt; estimates are labeled until finalized.
- **See also:** [[SHOP-003]], [[SHOP-009]], [[SHOP-022]], [[TAB-004]], [[L10N-005]], [[PAY-001]]

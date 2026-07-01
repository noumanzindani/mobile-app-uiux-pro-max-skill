# E-commerce / Marketplace — Accessibility

> Domain accessibility beyond the core `[[A11Y-…]]` corpus: product imagery, and the
> price/rating/stock information that commerce apps too often encode in color or
> images alone. If a blind or low-vision shopper can't tell the price, the rating, or
> whether an item is in stock, they can't buy.

## Table of contents

1. [Product images](#1-product-images)
2. [Stock & availability cues](#2-stock--availability-cues)
3. [Ratings & price to assistive tech](#3-ratings--price-to-assistive-tech)
4. [Touch, zoom & Dynamic Type](#4-touch-zoom--dynamic-type)
5. [Rules](#rules)

---

## 1. Product images

Images *are* the product on a shopping surface, so they must carry information for
non-visual users, not just decoration.

- **Meaningful alt text.** Every product image has alt text describing the product
  ("Red canvas high-top sneaker, side view"), not the filename or "image"
  (`[[SHOP-020]]`, core `[[AVT-001]]`). Gallery images each get distinct alt text;
  purely decorative chrome is marked decorative so it's skipped.
- **Zoom for low vision.** Product galleries support pinch-zoom / double-tap-zoom so
  low-vision shoppers can inspect detail (`[[SHOP-020]]`).
- **Fallbacks.** A broken or missing image renders a labeled placeholder, never an
  empty tap target (core `[[AVT-001]]`, `[[PERF-005]]`).

## 2. Stock & availability cues

- **Never color-only.** "In stock" vs "Low stock" vs "Sold out" must be conveyed by
  text and/or icon, not a green/amber/red swatch alone (`[[SHOP-020]]`, core
  `[[COL-005]]`, `[[A11Y-014]]`). A disabled/out-of-stock variant carries a reason in
  text, exposed to assistive tech (`[[SHOP-007]]`).
- **Announced on change.** When selecting a variant changes availability, announce the
  new state via a live region (core `[[A11Y-011]]`).

## 3. Ratings & price to assistive tech

- **Ratings are numeric to AT.** A star rating must be announced as a value ("4.6 out
  of 5, 812 reviews"), not left as five colored glyphs a screen reader reads as
  "image image image" (`[[SHOP-021]]`, core `[[A11Y-014]]`, `[[A11Y-007]]`).
- **Discount prices read correctly.** A struck-through "was" price and current price
  must be announced distinctly — original price then price-to-pay — not concatenated
  into one confusing number (`[[SHOP-021]]`, `[[SHOP-009]]`).
- **Amounts use tabular numerals** so sighted low-vision users can scan columns (core
  `[[TAB-004]]`), and prices are formatted per locale (core `[[L10N-005]]`).

## 4. Touch, zoom & Dynamic Type

- **Targets.** Add-to-cart, save, quantity `+`/`−`, and card controls meet 44pt/48dp
  minimums and don't overlap (core `[[A11Y-005]]`, `[[SHOP-012]]`).
- **Dynamic Type / font scaling.** Prices, titles, and totals reflow and remain fully
  visible at large text sizes — no truncated price, no clipped total (core
  `[[TYP-005]]`).
- **Contrast.** Price, rating, and stock text meet 4.5:1; don't render a sale price in
  a light red that fails contrast (core `[[A11Y-002]]`).

---

## Rules

### SHOP-020 — Product images: alt text, zoom, and non-color stock/price cues
- **Rule:** Every meaningful product image MUST have descriptive alt text (gallery images each distinct; decorative chrome marked decorative), product galleries MUST support zoom for low vision, and stock/availability status MUST be conveyed by text and/or icon rather than color alone. Missing images MUST render a labeled placeholder.
- **Why:** Images carry the product's information; without alt text, zoom, and non-color status, blind and low-vision shoppers cannot evaluate or buy the item — an accessibility and often legal failure.
- **Platforms:** all
- **Severity:** error
- **Check:** With a screen reader, each product image announces a meaningful description; the gallery zooms; stock status reads in text/icon (passes grayscale review); a broken image shows a labeled placeholder.
- **See also:** [[SHOP-007]], [[SHOP-021]], [[AVT-001]], [[COL-005]], [[A11Y-014]], [[A11Y-011]]

### SHOP-021 — Announce ratings and price to assistive tech, not color-only
- **Rule:** Star ratings MUST be exposed to assistive tech as a numeric value with review count ("4.6 out of 5, 812 reviews"), not as color-only glyphs; discounted prices MUST announce the original and current prices distinctly; and price/rating meaning MUST NOT depend on color alone. Amounts use tabular numerals and locale currency formatting.
- **Why:** Ratings and price are the decision-critical facts of a purchase; encoding them only in stars-as-images or color makes them unusable for screen-reader and color-blind shoppers and fails WCAG 1.4.1.
- **Platforms:** all
- **Severity:** error
- **Check:** With a screen reader, a rating announces value + count and a discounted item announces was-price then current price; grayscale review confirms rating/price meaning survives without color.
- **See also:** [[SHOP-009]], [[SHOP-015]], [[SHOP-020]], [[A11Y-014]], [[A11Y-007]], [[TAB-004]], [[L10N-005]]

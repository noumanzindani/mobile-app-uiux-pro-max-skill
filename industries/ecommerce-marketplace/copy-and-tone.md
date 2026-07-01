# E-commerce / Marketplace — Copy & Tone

> Voice, microcopy, error messaging, and honesty norms for shopping apps. Commerce
> copy should be **clear, specific, and non-manipulative** — it can be warm and
> persuasive, but never deceptive at the moment money is on the line.

## Voice principles

- **Specific over vague.** Say what's true and actionable: "Ships in 2–3 days,"
  "Only ships within the US," "2 left in your size" — not "Almost gone!" with nothing
  behind it (`[[SHOP-019]]`).
- **Persuasive, not manipulative.** Encouraging is fine; fabricating pressure is not.
  Scarcity and urgency copy must reflect real inventory or a real deadline
  (`[[SHOP-019]]`, and the bans in `[[SHOP-022]]`).
- **Blameless errors.** When a card declines or an item sells out, describe what
  happened and the way forward — never imply the shopper did something wrong
  (`[[SHOP-018]]`).
- **Consistent terms.** Pick one word per concept — "cart" not "cart/bag/basket"
  interchangeably; "Saved" not "Wishlisted/Favorited/Liked" across screens.

## Microcopy: scarcity & urgency

| Situation | Do | Don't |
|---|---|---|
| Low real stock | "2 left in Medium" | "Almost gone — hurry!" (no number) |
| Real sale deadline | "Sale ends Sun, Jun 7" | "Ends soon!!!" (no date) |
| No real deadline | *(say nothing about time)* | fake countdown timer that resets |
| Popular item | "128 sold this week" (if true) | "Everyone's buying this!" |
| Back in stock | "Back in stock" | "Won't last — act now" |

## Microcopy: errors & edge cases

| Situation | Do | Don't |
|---|---|---|
| Card declined | "Your card was declined. Check the details or try another card. No charge was made." | "Payment failed." |
| Item sold out at checkout | "Sorry — the last one just sold. We've removed it; your other items are safe." | silently drop the item |
| Out of stock (PDP) | "Sold out. Notify me when it's back." | greyed button, no reason |
| Invalid address | "We couldn't find that address. Check the ZIP and street." | "Invalid input." |
| Quantity over stock | "Only 3 available — we set the quantity to 3." | reject with no explanation |
| Zero search results | "No results for 'reddd sneakers.' Check spelling or try 'red sneakers.'" | blank screen |
| Guest checkout offer | "Continue as guest" (equal weight to Sign in) | hide it / pre-check "Create account" |

## Error messaging

Commerce errors sit right on top of a purchase, so anxiety is real — especially at
payment. Every checkout error message should answer:

1. **What happened?** — plainly ("Your card was declined").
2. **Was I charged?** — the key reassurance ("No charge was made").
3. **What now?** — a concrete next step ("Try another card," "Update your address,"
   "Notify me when it's back"), routed to the right recovery path (`[[SHOP-018]]`).

Never show a bare gateway/decline code alone; if you include one for support, pair it
with human language. Never blame the shopper for a system or inventory failure.

## Discounts & pricing language

- **Discount claims must be true.** "50% off" must match the arithmetic against a
  genuine prior price; don't imply a limited-time deal that's actually the permanent
  price (`[[SHOP-009]]`, `[[SHOP-019]]`).
- **Totals are exact and labeled.** "Total $64.20" is the charged amount; estimates say
  "Estimated" until finalized (`[[SHOP-017]]`).
- **Fees are named, not buried.** "Service fee $2.00" with a one-line reason beats an
  unexplained line item.

---

## Rules

### SHOP-018 — Write clear, blameless error copy for declines, stock, and address issues
- **Rule:** Checkout and cart error messages (payment declines, out-of-stock at add/checkout, invalid/undeliverable address, quantity-over-stock) MUST state (1) what happened in plain language, (2) whether the shopper was charged where money is involved, and (3) a concrete next step or recovery path. They MUST NOT blame the shopper for system/inventory failures or show a bare error/decline code alone.
- **Why:** Payment and stock errors spike anxiety and abandonment; answering "was I charged?" and offering a clear recovery keeps the sale alive and reduces support load, while blame and raw codes drive shoppers away.
- **Platforms:** all
- **Severity:** warning
- **Check:** Trigger a declined card, an out-of-stock item, and a bad address: each message is plain, states charge status where relevant, offers a next step, and shows no user-blaming phrasing or bare code.
- **See also:** [[SHOP-002]], [[SHOP-013]], [[SHOP-017]], [[FRM-002]]

### SHOP-019 — Keep scarcity and urgency copy honest (no dark patterns)
- **Rule:** Scarcity ("N left"), urgency ("sale ends…"), and social-proof ("N sold") claims MUST reflect real inventory, a real deadline, or real data. The app MUST NOT show fabricated stock counts, countdown timers that reset or don't correspond to a real deadline, or invented popularity claims. If there is no real scarcity or deadline, say nothing about it.
- **Why:** Fake urgency is a deceptive dark pattern that erodes trust, damages brand, and is increasingly subject to consumer-protection enforcement; honest scarcity still converts without the risk.
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify each scarcity/urgency/social-proof string is backed by a real value (inventory, deadline, count); confirm no countdown resets on reload and no static "Almost gone" without data.
- **See also:** [[SHOP-009]], [[SHOP-015]], [[SHOP-017]], [[SHOP-022]]

# E-commerce / Marketplace — Pitfalls

> The commerce UX mistakes that quietly kill conversion and trust — and the rule that
> bans the worst offenders outright. Most of these are dark patterns: they may lift a
> metric this quarter, but they erode trust, invite regulatory action, and raise
> refunds and support load. Fix them at the source.

## Table of contents

1. [Narrative: how good shopping UX goes wrong](#narrative-how-good-shopping-ux-goes-wrong)
2. [Common mistakes → fix](#common-mistakes--fix)
3. [Rules](#rules)

---

## Narrative: how good shopping UX goes wrong

**Forcing account creation to buy.** The most common conversion-killer: a shopper is
ready to pay and is blocked by a "create an account" wall. Guest checkout must come
first (`[[SHOP-004]]`); making it mandatory is a banned dark pattern (`[[SHOP-022]]`).

**Hidden and dripped costs.** The price looks great until shipping, tax, and a "service
fee" appear one screen at a time — or worse, on the receipt after the charge. Every
mandatory cost belongs on the review step, summed into a dominant total, before the
pay button (`[[SHOP-017]]`, `[[SHOP-022]]`).

**Fake urgency and scarcity.** Countdown timers that reset on reload, "Only 1 left!"
on infinite inventory, and "128 people are viewing this" pulled from thin air. If the
scarcity or deadline isn't real, don't claim it (`[[SHOP-019]]`, `[[SHOP-022]]`).

**Silent cart divergence.** An optimistic add-to-cart that never reconciles, so the
item quietly vanishes at checkout or the total shifts. Optimistic UI must roll back
visibly and explain why (`[[SHOP-002]]`, `[[SHOP-010]]`).

**Blank zero-results and filter dead-ends.** A search that returns nothing shows an
empty scroll that reads as "broken," or a filter combination strands the user with no
way back. Both need designed, actionable empty states (`[[SHOP-005]]`, `[[SHOP-006]]`).

**A catalog built for one phone.** Two phone-width columns stretched across a tablet,
or a grid that resets scroll and filters on rotation. Reflow from width, preserve
state (`[[SHOP-001]]`).

**Color-only meaning.** Sale price in red, "in stock" in green, star ratings as colored
glyphs with no numeric value — invisible to color-blind and screen-reader shoppers
(`[[SHOP-020]]`, `[[SHOP-021]]`).

**Fabricated or one-sided reviews.** Seeded 5-star averages, hidden negative reviews,
or a rating shown when there are zero reviews. Show count, distribution, and honest
access to the bad ones (`[[SHOP-015]]`).

**Overriding system back.** Hijacking the back gesture mid-checkout so the user can't
retreat a step without losing input (`[[SHOP-003]]`, core `[[NAV-003]]`).

**Pre-checked add-ons and confirmshaming.** A pre-ticked warranty, insurance, or
newsletter, or a decline option worded to guilt the shopper ("No thanks, I don't want
to save money"). Opt-in must be unchecked and neutral (`[[SHOP-022]]`).

## Common mistakes → fix

| Mistake | Fix | Rule |
|---|---|---|
| Must create an account to check out | Offer guest checkout first, equal weight to sign-in | [[SHOP-004]], [[SHOP-022]] |
| Shipping/tax/fees appear after the charge (drip pricing) | Itemize all costs into a dominant total on review, before pay | [[SHOP-017]], [[SHOP-022]] |
| Fake countdown / "Only 1 left" on infinite stock | Show real inventory/deadline or say nothing about time | [[SHOP-019]], [[SHOP-022]] |
| Add-to-cart never reconciles; item vanishes at checkout | Optimistic add with visible rollback + reason | [[SHOP-002]], [[SHOP-010]] |
| Zero-results shows a blank scroll | Designed, actionable empty state with query echo + escape | [[SHOP-005]] |
| Filters strand the user with no way out | Filtered-empty state + one-tap Clear filters | [[SHOP-006]] |
| Two phone columns stretched on tablet; state lost on rotate | Reflow columns from width; preserve scroll/filter state | [[SHOP-001]] |
| Sale price / stock / ratings encoded in color only | Text/icon cues + numeric rating announced to AT | [[SHOP-020]], [[SHOP-021]] |
| Seeded or one-sided reviews; rating with zero reviews | Show count + distribution; allow negatives; "No reviews yet" | [[SHOP-015]] |
| Buy button unreachable one-handed on the PDP | Sticky thumb-zone add-to-cart at ≥44pt/48dp | [[SHOP-007]] |
| Native Pay buried below the card form | Surface the platform Pay button first | [[SHOP-008]] |
| Back gesture hijacked mid-checkout | Never override system back; preserve step input | [[SHOP-003]] |
| Pre-checked add-ons / confirmshaming decline copy | Unchecked, neutral opt-in; plain decline wording | [[SHOP-022]] |

---

## Rules

### SHOP-022 — Ban commerce dark patterns (forced accounts, hidden costs, fake urgency)
- **Rule:** The app MUST NOT ship recognized commerce dark patterns, including: (a) forcing account creation to complete a purchase (guest checkout must be available, per [[SHOP-004]]); (b) hidden or dripped mandatory costs revealed after the total is shown or after the charge (all costs on review, per [[SHOP-017]]); (c) fabricated scarcity/urgency — resetting countdowns, false "N left," invented viewer/purchase counts (honest per [[SHOP-019]]); (d) pre-checked paid add-ons or opt-ins; and (e) confirmshaming decline copy. Any opt-in for extra products/marketing MUST default to unchecked with neutral wording.
- **Why:** Dark patterns extract short-term conversions at the cost of trust, refunds, chargebacks, brand damage, and growing regulatory exposure (FTC, EU consumer-protection/DSA); banning them protects both users and the business.
- **Platforms:** all
- **Severity:** error
- **Check:** Audit checkout end-to-end: guest path exists; all mandatory costs shown before charge; every scarcity/urgency claim is data-backed and non-resetting; add-ons/marketing opt-ins are unchecked by default; no decline option uses guilt/confirmshaming language.
- **See also:** [[SHOP-004]], [[SHOP-017]], [[SHOP-019]], [[SHOP-014]], [[SHOP-015]], [[NAV-003]]

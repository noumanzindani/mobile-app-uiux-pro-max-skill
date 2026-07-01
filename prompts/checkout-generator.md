# Checkout Generator

**Purpose:** Generate a checkout flow (cart → address → pay → confirm) with native Pay buttons, guest checkout, a review-before-charge step, trust signals, and robust error recovery — all 7 states, token-driven and accessible.

**Inputs:**
- *Required:* **Steps required** (cart, shipping/address, shipping method, payment, review, confirmation) and **what's purchased** (physical/digital/subscription).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Payment methods** (Apple Pay / Google Pay / card / wallet), **guest checkout allowed?**, **platform target**, **industry** (default ecommerce-marketplace) — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); note step hierarchy, the review-before-charge gate, and thumb-zone placement of the pay action.
2. Load the recipe — `patterns/checkout-patterns.md` (cart → address → pay → confirm; guest checkout).
3. Load the domain rules — `rules/domain/payments.md` (PAY: native Pay buttons; review before charge; guest checkout; error recovery).
4. Load the industry pack — `industries/ecommerce-marketplace/_index.md`, `trust-and-safety.md` (trust badges, PCI-adjacent UX), `copy-and-tone.md` (error/price microcopy).
5. Load component + flow rules — `rules/components/forms.md` (address input, correct keyboard/autofill), `rules/components/buttons.md` (native Pay button; single primary action), `rules/components/dialogs.md`, `patterns/form-flows.md` (multi-step validation, keyboard avoidance).
6. Load offline/error behavior — `rules/system/offline.md` — for payment failure recovery (never lose the cart; clear retry; idempotent).
7. Load framework idioms — `frameworks/<framework>/components.md`, `states.md` — for the native-Pay integration surface, form controls, safe area, a11y.
8. Enumerate the 7 states — `rules/interaction/states.md`: cart `empty`, `loading` (calculating totals/processing payment — with a spinner + disabled pay), payment `error` (declined/network → recover without losing the cart), `offline` (blocked pay + banner), `success` (order confirmation), `permission-denied` (rare — e.g. location for tax). Add a distinct **cart-empty** and **payment-declined** design.
9. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; prices use tabular numerals; the pay button announces amount; errors are announced.

**Output format:**
- The **multi-step checkout flow** in the target framework with a persistent order-summary, a **review-before-charge** step, **native Pay** + **guest checkout**, and **trust signals**.
- **All 7 states** (esp. cart-`empty`, payment-`error`/declined recovery, `offline`, `success` confirmation).
- **Token-usage table**, **a11y notes** (pay-button amount announcement, error announcements, tabular numerals), **trust-signal placement**.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` (all 7, esp. `error`-recovery and cart-`empty`), `target_size_lint`, `contrast_check`, `token_lint`, `dynamic_type_check`, `rtl_check` PASS. Verify the cart survives a payment failure and the review-before-charge gate exists. Reason through `industries/ecommerce-marketplace/pitfalls.md`, `quality-checks/checklists/states.md`, and `accessibility.md`.

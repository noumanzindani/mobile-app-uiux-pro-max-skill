# Payments & Checkout (PAY)

> Purpose: Charge users safely and transparently — native Pay buttons, PCI-safe card handling, a review-before-charge step, guest checkout, clear totals, and recoverable errors with a success confirmation.

## Contents
- [PAY-001 — Use native platform Pay buttons](#pay-001--use-native-platform-pay-buttons)
- [PAY-002 — Never render or store the raw card number](#pay-002--never-render-or-store-the-raw-card-number)
- [PAY-003 — Show an explicit review-before-charge step](#pay-003--show-an-explicit-review-before-charge-step)
- [PAY-004 — Display the full itemized total including all fees](#pay-004--display-the-full-itemized-total-including-all-fees)
- [PAY-005 — Offer guest checkout](#pay-005--offer-guest-checkout)
- [PAY-006 — Save-card is opt-in with explicit consent](#pay-006--save-card-is-opt-in-with-explicit-consent)
- [PAY-007 — Payment errors are specific and retryable without data loss](#pay-007--payment-errors-are-specific-and-retryable-without-data-loss)
- [PAY-008 — Show a success confirmation with order details](#pay-008--show-a-success-confirmation-with-order-details)
- [PAY-009 — Use correct input formatting and autofill for card fields](#pay-009--use-correct-input-formatting-and-autofill-for-card-fields)
- [PAY-010 — Use in-app purchase for digital goods on iOS](#pay-010--use-in-app-purchase-for-digital-goods-on-ios)
- [PAY-011 — Show a processing state and prevent double charges](#pay-011--show-a-processing-state-and-prevent-double-charges)
- [PAY-012 — Let the wallet sheet own address and contact collection](#pay-012--let-the-wallet-sheet-own-address-and-contact-collection)
- [PAY-013 — Surface accepted methods and trust signals near the CTA](#pay-013--surface-accepted-methods-and-trust-signals-near-the-cta)
- [PAY-014 — Place price and pay action in the thumb zone with deliberate confirm](#pay-014--place-price-and-pay-action-in-the-thumb-zone-with-deliberate-confirm)
- [PAY-015 — Handle 3-D Secure / SCA challenges inline](#pay-015--handle-3-d-secure--sca-challenges-inline)
- [PAY-016 — Format currency and amounts for the locale](#pay-016--format-currency-and-amounts-for-the-locale)
- [PAY-017 — Provide all 7 states across the checkout flow](#pay-017--provide-all-7-states-across-the-checkout-flow)
- [PAY-018 — Make receipts, refunds, and cancellation reachable after purchase](#pay-018--make-receipts-refunds-and-cancellation-reachable-after-purchase)

---

### PAY-001 — Use native platform Pay buttons
- **Rule:** Offer Apple Pay on iOS and Google Pay on Android using the OFFICIAL button components, correct wording/asset, and platform minimum height (Apple Pay ≥30pt tall / typically 44pt+ target); do not restyle the mark.
- **Why:** Native Pay buttons cut checkout to one authenticated tap, are the most trusted CTA, and their appearance is mandated by Apple/Google brand guidelines.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm the platform-native button component and brand-compliant styling/size.
- **Exceptions:** Regions/merchants where the wallet is unavailable; then fall back to a card form.
- **See also:** [[PAY-012]], [[PAY-013]], [[BTN-001]]

### PAY-002 — Never render or store the raw card number
- **Rule:** The app MUST NOT display, log, or persist a full PAN/CVV; use tokenization (wallet token, PSP token, or SDK-hosted fields). Show only brand + last 4 for saved cards.
- **Why:** Rendering or storing raw card data breaks PCI-DSS SAQ scope and is a serious security and store-review risk.
- **Platforms:** all
- **Severity:** error
- **Check:** grep for card-number logging/persistence; manual — saved cards show only last 4.
- **Exceptions:** None.
- **See also:** [[PAY-006]], [[PAY-009]]

### PAY-003 — Show an explicit review-before-charge step
- **Rule:** Before any charge, present a review screen (or wallet sheet) listing items, amounts, payment method, and the exact total; the charge only fires on a distinct confirm action.
- **Why:** A confirm step prevents accidental purchases and satisfies the user's need to verify before committing money.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify no charge occurs before an explicit confirm.
- **Exceptions:** Wallet sheets (Apple/Google Pay) that themselves present a review + biometric confirm.
- **See also:** [[PAY-004]], [[PAY-014]]

### PAY-004 — Display the full itemized total including all fees
- **Rule:** Before the pay action, show the complete price breakdown — subtotal, taxes, shipping, service/processing fees, discounts — and the final total. No fees may first appear after charging.
- **Why:** Hidden or drip-priced fees erode trust, drive chargebacks, and increasingly violate consumer-protection 'all-in pricing' regulations.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm every fee is visible pre-charge and matches the amount charged.
- **Exceptions:** Genuinely variable costs (e.g. metered usage) shown as a clearly-labeled estimate.
- **See also:** [[PAY-003]], [[PAY-016]]

### PAY-005 — Offer guest checkout
- **Rule:** Allow completing a purchase without creating an account; capture only what is needed to fulfill the order, and offer optional account creation AFTER the purchase.
- **Why:** Forced account creation is a top cause of cart abandonment; guest checkout measurably lifts conversion.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — complete a purchase without signing up.
- **Exceptions:** Subscriptions or regulated goods that legally require an identified account.
- **See also:** [[AUTH-017]], [[PAY-008]]

### PAY-006 — Save-card is opt-in with explicit consent
- **Rule:** A 'save this card for next time' control MUST default to OFF and require an explicit user action; saved cards must be viewable and deletable later.
- **Why:** Silently vaulting card details violates consent expectations and PSP/store rules; opt-in respects user control.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify the save toggle defaults off and saved cards are manageable.
- **Exceptions:** Merchant-initiated/subscription cards where storage is inherent and clearly disclosed at agreement.
- **See also:** [[PAY-002]], [[PROF-006]]

### PAY-007 — Payment errors are specific and retryable without data loss
- **Rule:** Declines/failures MUST show a specific, non-technical reason and a retry path (or switch method) while preserving the cart and all entered data; never dump the user back to an empty cart.
- **Why:** Payment is the highest-stakes moment; a lost cart after a decline is an immediate lost sale and a support ticket.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — force a decline (test card) and confirm cart/data survive with a clear retry.
- **Exceptions:** Issuer messages that cannot be disambiguated may map to a safe generic 'card declined — try another'.
- **See also:** [[PAY-011]], [[STATE-014]], [[OFF-003]]

### PAY-008 — Show a success confirmation with order details
- **Rule:** A completed payment MUST land on a distinct confirmation screen showing an order/reference ID, the charged total, and clear next steps (receipt, tracking, or access to the purchase).
- **Why:** An explicit confirmation closes the transaction loop, reassures the user, and reduces duplicate-purchase anxiety.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — complete a purchase and verify the confirmation includes an order reference.
- **Exceptions:** None.
- **See also:** [[PAY-018]], [[PAY-011]]

### PAY-009 — Use correct input formatting and autofill for card fields
- **Rule:** Manual card entry MUST use a number pad, live-format the card number/expiry, validate with Luhn inline, and declare credit-card autofill content types so the OS/scan-card can fill them.
- **Why:** Formatting and autofill slash entry errors in the most abandonment-prone form on mobile.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify number pad, live formatting, inline validation, and autofill/scan.
- **Exceptions:** SDK-hosted PCI fields where formatting is provided by the PSP component.
- **See also:** [[PAY-002]], [[FRM-011]]

### PAY-010 — Use in-app purchase for digital goods on iOS
- **Rule:** Digital content/services consumed in-app MUST use StoreKit/Play Billing, not an external card form. Physical goods/services use standard payment processors. Where an external-purchase link entitlement applies (2025 rulings), follow the current store rules for disclosure.
- **Why:** Routing digital goods around IAP is a hard App Store rejection and a Play policy violation.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — classify goods as digital vs physical and confirm the correct rail.
- **Exceptions:** Physical goods/services; reader apps and other explicit store carve-outs; approved external-link entitlements.
- **See also:** [[PAY-001]], [[PAY-018]]

### PAY-011 — Show a processing state and prevent double charges
- **Rule:** On submit, show a processing state, disable the pay button, and make the request idempotent (client idempotency key) so a retry or double-tap cannot double-charge.
- **Why:** Payment latency invites impatient re-taps; without idempotency that becomes a duplicate charge and a refund/dispute.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — double-tap pay and confirm a single charge; verify idempotency key usage.
- **Exceptions:** None.
- **See also:** [[PAY-007]], [[STATE-005]], [[BTN-008]]

### PAY-012 — Let the wallet sheet own address and contact collection
- **Rule:** When Apple Pay/Google Pay can supply shipping, billing, and contact info, request it via the wallet sheet rather than duplicating those fields in your own form.
- **Why:** Reusing wallet-provided data removes entire form screens and is the whole point of native Pay.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm address/contact come from the wallet when Pay is used.
- **Exceptions:** Fields the wallet cannot provide (e.g. gift message, delivery instructions).
- **See also:** [[PAY-001]], [[PAY-004]]

### PAY-013 — Surface accepted methods and trust signals near the CTA
- **Rule:** Show accepted card brands/wallets and a security cue (lock icon + 'secure checkout' / PSP badge) adjacent to the pay button.
- **Why:** Visible trust signals at the point of payment measurably reduce abandonment and reassure first-time buyers.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify method marks and a security cue sit near the CTA.
- **Exceptions:** Wallet-only flows where the native sheet already conveys trust.
- **See also:** [[PAY-001]], [[PAY-002]]

### PAY-014 — Place price and pay action in the thumb zone with deliberate confirm
- **Rule:** The final total and pay button MUST sit in the lower thumb-reachable region; the pay action requires a deliberate tap (no swipe-to-pay, no auto-advance) and is visually distinct from secondary actions.
- **Why:** Money-moving actions must be reachable one-handed yet impossible to trigger accidentally.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on the pay CTA; manual — confirm no gesture-only charge path.
- **Exceptions:** Tablet/large layouts may anchor the summary in a side column.
- **See also:** [[PAY-003]], [[GES-004]], [[BTN-007]]

### PAY-015 — Handle 3-D Secure / SCA challenges inline
- **Rule:** Bank authentication (3DS2/SCA, OTP, app redirect) MUST be presented inline or via the PSP's sheet and return the user to the exact checkout state on success or cancel.
- **Why:** SCA is mandatory in many regions; a challenge that loses checkout context strands the payment.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trigger a 3DS test card and confirm smooth return to the flow.
- **Exceptions:** Regions/transactions exempt from SCA.
- **See also:** [[PAY-007]], [[AUTH-012]]

### PAY-016 — Format currency and amounts for the locale
- **Rule:** Amounts MUST use locale-correct currency symbol, placement, grouping, and decimal separators, rendered with tabular (monospaced) numerals so columns align.
- **Why:** Mis-formatted money reads as untrustworthy or wrong; tabular numerals keep totals scannable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — switch locale and verify currency formatting and numeral alignment.
- **Exceptions:** None.
- **See also:** [[PAY-004]], [[L10N-006]], [[TYP-014]]

### PAY-017 — Provide all 7 states across the checkout flow
- **Rule:** Cart and checkout MUST design ideal, empty (empty cart with a way back to shop), loading (fetching prices/processing), error (decline/validation), offline (lost connection mid-pay), success (order placed), and permission-denied (e.g. NFC/wallet unavailable).
- **Why:** Checkout is network- and hardware-dependent; unhandled states here directly cost revenue.
- **Platforms:** all
- **Severity:** error
- **Check:** state_coverage.py across the cart/checkout screens.
- **Exceptions:** Permission-denied is N/A when no OS permission or wallet hardware is used.
- **See also:** [[STATE-001]], [[PAY-007]], [[OFF-003]]

### PAY-018 — Make receipts, refunds, and cancellation reachable after purchase
- **Rule:** After a purchase, users MUST be able to find the receipt/order, and reach cancel/refund/manage-subscription within the app (not only via email or web).
- **Why:** Post-purchase management is expected by users and required by store policies for subscriptions and auto-renewals.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — locate receipt and cancel/refund path from the account/orders area.
- **Exceptions:** Final-sale goods with a clearly disclosed no-refund policy.
- **See also:** [[PAY-008]], [[PROF-001]], [[PROF-006]]

# Checkout — Jetpack Compose (Material 3 Expressive)

A real, compiling reference implementation of the [checkout spec](../spec.md) for **Jetpack
Compose** on Android, using **Material 3 Expressive**. It is the flagship "let me pay quickly,
without surprises, and trust that it worked" flow: guest-first, native-Pay-forward, honest
totals, an editable review, and an **idempotent payment that cannot double-charge** —
accessible, keyboard-safe, and edge-to-edge.

## Files

| File | Role |
|---|---|
| [`CheckoutTokens.kt`](CheckoutTokens.kt) | Semantic token layer — the **only** file with raw values (`Color`, `Dp` spacing/size/radius, millis, and the one platform-mandated Google Pay brand color). Colors/typography/shape resolve through `MaterialExpressiveTheme`; spacing/size/radius are carried as `Space` / `Size` / `Radius` token objects; the `on-surface-strong`, `status.success`, and native **Google Pay** roles ride a `CompositionLocal` (`LocalCheckoutColors`) read as `MaterialTheme.checkoutColors`. The `amount` / `total` text styles enable **tabular figures** (`fontFeatureSettings = "tnum"`). Every literal line is marked `// ux:ignore`. |
| [`CheckoutScreen.kt`](CheckoutScreen.kt) | The `CheckoutScreen` composable + a stateless `CheckoutScreenContent`, the `CheckoutStatus` / `CheckoutUiState` models, the idempotent `submit` path, `CheckoutActivity` (edge-to-edge host), and one `@Preview` per state. Consumes **only** tokens + `MaterialTheme` roles. |

## What it demonstrates

- **Always-visible, honest order summary.** A single `LazyColumn` whose summary card lists every
  line item and the **full itemized total** — subtotal, shipping, tax, discount, total — with
  **tabular figures** and **locale currency** via `NumberFormat.getCurrencyInstance(locale)`
  (`currency` pinned to the order's `currencyCode`). No hidden fees, no surprise at the charge.
- **Editable review.** Line items carry **quantity steppers** (`IconButton`, 48dp each); a change
  recomputes totals through the `Loading` state with **honest inline progress** (no fake bar), and
  the new **total is announced** through a polite `liveRegion` ("Order total $X").
- **Guest-first.** "Continue as guest" is the prominent primary; the account ask is **deferred to
  post-purchase** (offered on the confirmation), never a login wall (`AUTH-010`, `PAY-003`).
- **Native Google Pay, surfaced early.** A platform-styled shortcut at the top of the flow. Here
  it's a reference button whose **only** brand literal (`googlePayContainer`) lives in
  `CheckoutTokens`; in production swap in the **official Google Pay button** (see below).
- **Address + payment with the right keyboards + autofill.** Every field is an `OutlinedTextField`
  with `KeyboardOptions` (number pad for postal code / card / CVV) and **autofill semantics**
  (`contentType = ContentType.AddressStreet / PostalCode / CreditCardNumber / …`) so paste, OS
  autofill, and password/address managers all work (**WCAG 2.2 · 3.3.8**). The saved card is
  display-masked (`···· 4242`); the **new card is never intercepted, so paste stays safe**.
- **Sticky, full-width Pay button showing the amount.** In the bottom thumb arc, labeled
  **"Pay $X"**. The instant it's tapped it **disables + spins**, and submit is **idempotent** — a
  client idempotency key (created once, **reused on retry**) means a double-tap or retry cannot
  create two charges (`PAY-007`, `BTN-008`). It resolves to a **definitive** `Success` or a
  **recoverable** `Error` — never a limbo.
- **All 8 states** via a sealed `CheckoutStatus`: `Ideal`, `Empty`, `Loading`, `Processing`,
  `Error`, `Offline`, `Success`, `PermissionDenied`.
  - **Offline** *blocks* the charge with a clear reason ("we won't charge you until you're back
    online"), cart + all entries preserved — never a silent or double fire.
  - A **declined** card keeps **all** input (card + address) so retry needs no re-entry.
  - **Empty** cart → a **Browse** CTA, never a dead end.
  - **Permission-denied** (NFC/unlock unavailable for native Pay) → explain + fall back to manual
    card entry, with an optional Settings link; checkout is never blocked on it.
  - **Success** → order number + **receipt total** + **ETA** + next steps (Track order), plus the
    deferred "save these details" offer.
- **Announced to assistive tech.** Total changes (polite), "Processing payment" (assertive on the
  Pay button), and the success/error result are all exposed via `semantics { contentDescription /
  stateDescription / liveRegion }`; the Pay button is labeled with the amount and reflects
  disabled/processing state.
- **Keyboard-safe & edge-to-edge:** `enableEdgeToEdge()` in `CheckoutActivity`, `Scaffold` with
  `WindowInsets.safeDrawing`, and `Modifier.imePadding()` on both the scrolling content and the
  sticky Pay bar so fields and the CTA stay above the keyboard.
- **RTL-safe:** logical `padding(start/end)` / `PaddingValues(start, end)`, RTL-aware
  `Arrangement`/`Alignment`, and **amounts end-aligned** (`TextAlign.End`) so the price column
  mirrors correctly — no physical left/right anywhere.
- **Dynamic Type:** every text role comes from `MaterialTheme.typography` (scales to 200%); no
  fixed heights on text; the list reflows.
- **Motion:** only **opacity + offset** animate — the status-banner fade and the confirmation
  reveal — each with a **reduce-motion** `snap()` fallback via `rememberReduceMotion()` (reads
  `Settings.Global.ANIMATOR_DURATION_SCALE`). No motion during the charge itself.

> **Demo hooks (reference-only):** a *new* card number ending in `0002` simulates a decline; the
> charge otherwise succeeds after a short delay. Toggle `isOffline` to exercise the blocked-charge
> path, and `googlePayAvailable = false` to exercise the permission-denied fallback.

## Validators

Passes the five `CheckoutScreen.kt`-scoped rules audited by
[`quality-checks/validators/run_all.py`](../../../quality-checks/validators/run_all.py):
`token_lint`, `target_size_lint`, `dynamic_type_check`, `rtl_check`, `state_coverage` (plus the
repo-wide `contrast_check`) — **100/100**.

```bash
python3 quality-checks/validators/run_all.py "examples/checkout/jetpack-compose"
```

## Compose BOM note

Pin dependency versions through the **Compose BOM** (verified against **`2025.x`**, which ships
`androidx.compose.material3` with the **Expressive** APIs — `MaterialExpressiveTheme`,
`MotionScheme`, the 10-step corner scale, and `surfaceContainerHigh` — targeting Android 16 /
API 36). The autofill `ContentType` semantics (address + credit-card hints) require **Compose UI
1.8+**, included in BOM 2025.x.

The trust/summary glyphs (`Lock`, `CreditCard`, `Receipt`, `ShoppingBag`, `Person`, `CheckCircle`,
`Info`, `Warning`, `Add`, `Remove`) come from **`material-icons-extended`** — add that dependency,
or swap in your own icon set.

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.06.00")) // use the current 2025.x BOM

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended") // CreditCard / Receipt / …
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.activity:activity-compose:1.9.0+") // enableEdgeToEdge, setContent
}
```

## Native Google Pay (use a real library in production)

The `ExpressPay` composable here is a **placeholder** so the example compiles standalone. For a
real integration, present the **official Google Pay button** and load a `PaymentDataRequest`
through the Wallet API — do **not** re-style your own button (Google's brand guidelines require the
official asset, which is why native Pay styling is *not* re-tokenized in this skill):

```kotlin
dependencies {
    // Official Jetpack Compose Google Pay button (renders the branded asset + accessibility).
    implementation("com.google.pay.button:compose-pay-button:0.1.3")
    // Google Pay / Wallet API to build the PaymentDataRequest and launch the sheet.
    implementation("com.google.android.gms:play-services-wallet:19.4.0")
}
```

```kotlin
import com.google.pay.button.PayButton
import com.google.pay.button.ButtonType

PayButton(
    onClick = { /* PaymentsClient.loadPaymentData(paymentDataRequest) → charge with the token */ },
    allowedPaymentMethods = allowedPaymentMethodsJson, // your gateway's allowed methods
    type = ButtonType.Pay,
    modifier = Modifier.fillMaxWidth().heightIn(min = Size.minTarget),
)
```

On iOS the sibling SwiftUI example surfaces **Apple Pay** via `PayWithApplePayButton` /
`PKPaymentAuthorizationController`; the skill is adaptive — Apple Pay on iOS, Google Pay on Android.

> Material You dynamic color (Android 12+) can be layered on `CheckoutTheme` by sourcing the
> `ColorScheme` from `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` with
> the brand palette in `CheckoutTokens.kt` as the fallback. The `CheckoutColors` success/strong
> roles stay on `LocalCheckoutColors` so they swap with the theme regardless of the color source.

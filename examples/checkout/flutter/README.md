# Checkout — Flutter reference implementation

A real, compiling Flutter build of the checkout spec in [`../spec.md`](../spec.md).
A trustworthy, low-friction payment flow: an always-visible itemized order
summary, prominent guest checkout, a platform-styled native Pay shortcut,
autofilled + validated address, paste-safe card fields, an editable review, and a
**safety-critical, idempotent payment that cannot double-charge** — all **100 %
token driven** so a rebrand or dark-mode swap is a token change, not a refactor.

| File | Role |
|---|---|
| `checkout_tokens.dart` | The semantic token layer — color / spacing / radius / size / motion / typography. The **only** file allowed raw values (each raw line ends with `// ux:ignore`). Amounts use a **tabular-figures** text role (`FontFeature.tabularFigures`) so a recomputed total never jitters. The native Pay brand color is the one platform-mandated exception, marked `// ux:ignore` + "brand". |
| `checkout_screen.dart` | The `CheckoutScreen` widget — all 8 states, safety-critical payment, keyboard avoidance, RTL-safe, a11y. References tokens only. Money is formatted with `intl` (locale currency). |

Verified on **Flutter 3.41 / Dart 3** (`flutter analyze` clean) and scores
**100/100** on `quality-checks/validators/run_all.py`.

> **One dependency:** `intl` (for locale-aware `NumberFormat` currency). Add it
> with `flutter pub add intl` — it's a first-party Dart package. Everything else is
> pure `flutter/material` + `flutter/services`.

## What it demonstrates

**All states** via an explicit `enum CheckoutStatus { ideal, empty, loading,
processing, error, offline, success, permissionDenied }` — with `processing` as
the **safety-critical** payment state:

- **ideal** — items + an honest, itemized total (subtotal, shipping, tax,
  discount, total), native Pay available, review editable, Pay button states the
  amount.
- **empty** — a friendly empty-cart state with a **Browse the shop** CTA, never a
  dead end. (Reached by removing every line, or `initialItems: const []`.)
- **loading** — totals/cart computing: an inline spinner in the summary header and
  a skeleton body (`initialStatus: CheckoutStatus.loading`).
- **processing** *(safety-critical)* — see below.
- **error** — a **specific, recoverable** message ("Card declined — no charge was
  made…" / "Payment didn't go through and you were not charged…"). **All entered
  data is preserved** and retry needs no re-entry. Icon-paired, focus-moved,
  announced via `Semantics(liveRegion: true)`.
- **offline** — the charge is **blocked with a stated reason** ("We won't charge
  you until you're back online — your details are saved"); a live-region banner
  shows, the Pay button disables with a spoken reason, and **all entries are
  preserved**. Reconnecting never silently re-fires a charge.
- **success** — a confirmation screen with **order number + receipt (paid total) +
  ETA + next steps** (Track order / View receipt / Continue shopping) and a
  deferred "create an account" offer.
- **permissionDenied** — if Apple/Google Pay is unavailable (not set up / hardware
  off), a sheet explains and **falls back to manual card entry** — checkout is
  never blocked on it.

**Safety-critical payment (spec "Payment-processing"):**

- **Idempotent submit** — a client-side **idempotency key** (`_idempotencyKey`) is
  minted per checkout session and **reused across retries**, so a retry after a
  network error dedupes on the server instead of charging twice. A fresh key is
  minted only after a confirmed success.
- **No double-charge** — the instant Pay is tapped, `_status` becomes `processing`,
  the button's `onPressed` goes `null` (disabled) and swaps to a spinner, and
  `_pay()` early-returns on re-entry. A second tap is impossible.
- **Definitive outcome, never limbo** — every attempt resolves to exactly one of
  `PaymentOutcome.{success, declined, networkError}`; a thrown/dropped request is
  caught and mapped to a recoverable failure. The button never spins forever.
- **Offline blocks the charge** before it starts, with a reason, preserving all
  input — never a silent or double fire.
- **Honest progress** — an indeterminate spinner + "Processing payment…", announced
  via a live region. No fake determinate bar.

**Trust & totals (no surprises):**

- The **order summary is always visible** — a pinned, expandable, itemized panel
  (subtotal / shipping / tax / discount / total). The grand total is wrapped in a
  `Semantics(liveRegion: true)` so **any change is announced**, and it cross-fades
  subtly so a recompute is noticed.
- **Tabular figures + locale currency** — amounts use `FontFeature.tabularFigures`
  and `intl`'s `NumberFormat.simpleCurrency(locale: …)`; totals never conveyed by
  color/weight alone (the label always names the figure).
- The sticky Pay button **states the amount** ("Pay $56.47") and updates live.
- A free-shipping nudge ("Add $2.00 more for free shipping") shows honest,
  recomputed progress toward the threshold.

**Accessible checkout (WCAG 2.2 §3.3.8):**

- Card, expiry, CVV, address, and postal fields carry correct `autofillHints`
  (credit-card + address content types) inside an `AutofillGroup`, so **paste,
  autofill, and password/wallet managers all work**. Digit-grouping on the card
  number reformats on paste — it **never blocks paste** (`_CardGroupFormatter`).
- Correct keyboards: **number pad** for card number, CVV, and postal code.
- Every field is labeled (`labelText`) and its validation error is
  **programmatically associated** (`TextFormField` `errorText`).
- Payment methods are an accessible mutually-exclusive group; the Pay button is
  labeled with the **amount + enabled/disabled state**; "Processing payment" and
  the success result are announced.
- Targets ≥ 48 dp (Pay button, quantity steppers, edit buttons, method rows); text
  uses `Theme` text styles (no fixed heights, no sub-12 fonts) so it scales past
  200 %.

**Adaptive, RTL & motion:**

- Native Pay is **platform-styled**: Apple Pay on iOS, Google Pay elsewhere, with
  the platform-mandated brand fill (a black button in light, white in dark).
- Layout is **RTL-safe** throughout — `EdgeInsetsDirectional`,
  `AlignmentDirectional`, `TextAlign.start/end`; amounts are logically end-aligned
  so they mirror and column-align in any locale.
- **Motion** is transform/opacity only (total cross-fade, banner/error reveal,
  button swap, a brief success check), all collapsed to `Duration.zero` under
  `MediaQuery.disableAnimationsOf` (reduce motion). The receipt is never gated
  behind the check animation.

## Drop into an app

`CheckoutScreen` is self-contained — with no arguments it runs a demo that
simulates the charge. Wire the callbacks to make it real:

```dart
import 'checkout_screen.dart';

CheckoutScreen(
  // MUST be idempotent on request.idempotencyKey so a retry can't double-charge.
  // Return PaymentOutcome.success / .declined / .networkError.
  placeOrder: (request) => api.charge(
    idempotencyKey: request.idempotencyKey,
    amountCents: request.amountCents,
    method: request.method,
  ),
  // Present the platform Pay sheet / authenticate; return false to fall back.
  requestNativePay: () => wallet.canMakePayments(),
  initialItems: cart.lines,                    // const [] shows the empty state
  savedCard: const SavedCard(brand: 'Visa', last4: '4242'),
  isOffline: connectivity.isOffline,           // e.g. from connectivity_plus
  onBrowse: () => context.go('/shop'),
  onSignIn: () => context.push('/signin?return=checkout'),
  onTrackOrder: () => context.go('/orders/latest'),
  onViewReceipt: () => context.push('/receipt'),
  onContinueShopping: () => context.go('/shop'),
  onCreateAccount: () => context.push('/signup?prefill=1'),
  onOpenSettings: () => AppSettings.openAppSettings(),
);
```

Notes:

- **Try the states** in the demo: the two bottom **Simulate** switches preview the
  offline block and a declined card; remove a line to reach the empty state; pass
  `initialStatus: CheckoutStatus.loading` to preview the totals skeleton; tapping
  Express checkout runs the native-Pay path (and the permission-denied fallback if
  `requestNativePay` returns `false`). Promo code `WELCOME10` applies 10 % off.
- **Idempotency:** the key is minted per session and reused across retries so your
  backend can dedupe; a new key is minted only after a confirmed success. Make your
  `placeOrder` honor `request.idempotencyKey`.
- **Colors** resolve through `CheckoutColors.of(context)` off `Theme.brightness`.
  In production, promote `checkout_tokens.dart` onto a `ThemeExtension<T>` (see
  `frameworks/flutter/tokens.md`) and read via `Theme.of(context)`.
- **Localization & currency:** copy lives in the private `_Strings` class as a
  placeholder — route it through your i18n layer (whole messages, no
  concatenation). Currency follows `Localizations.localeOf(context)` via `intl`.
- The demo-only **Simulate** switches and `_demo*` helpers should be removed in
  production — connectivity and charge decisions come from the platform/server.

## Validate

```bash
python3 quality-checks/validators/run_all.py examples/checkout/flutter
# → Readiness score: 100/100 — PASS — clean
```

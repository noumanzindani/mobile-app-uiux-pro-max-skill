# Checkout — Ionic (React + Capacitor, TypeScript)

A real implementation of the [Checkout spec](../spec.md) for **Ionic 8**. Every visual
value resolves through CSS custom properties; every one of the 7 UI states is modeled
explicitly; the payment submit is **idempotent** and can never double-charge; and the
screen passes all six `quality-checks/validators` (**100/100**).

```
ionic/
  checkout.css        — token + style layer: --app-* / --ion-* variables and classes.
                        The ONLY file with raw values; the screen references var(...) only.
  CheckoutScreen.tsx  — the CheckoutScreen component (always-visible editable summary,
                        guest checkout, native Pay, address + payment, sticky Pay button,
                        all 7 states, idempotent submit, accessible).
  README.md           — this file.
```

> Bindings shown are `@ionic/react`; the same component/token approach applies to
> `@ionic/angular` and `@ionic/vue`.

## What it demonstrates

**All 7 states, as a discriminated union.** `CheckoutStatus` has members literally named
`idle · empty · loading · processing · error · offline · success`, so TypeScript forces
exhaustive handling. `processing` is the safety-critical member.

| State | Behaviour |
|---|---|
| **idle** | Ready to pay: editable itemized summary, native Pay, address + payment, sticky Pay button showing the amount. |
| **empty** | Designed empty-cart with a **Browse products** CTA — not a dead end. |
| **loading** | Brief *"Calculating your total…"* with an `IonSpinner` (`role="status"`) while totals settle. |
| **processing** | The Pay `IonButton` swaps its label for an `IonSpinner`, disables itself, and **blocks double-submit**; *"Processing payment"* is announced. |
| **error** | Inline *"Card declined…"* banner; `role="alert"` receives focus; **all entered data preserved**; retry via the Pay button without re-entry. |
| **offline** | Non-blocking banner + Retry (via `@capacitor/network`); the charge is **blocked with a clear reason**; entries preserved; Pay disabled until reconnect — never silently fires. |
| **success** | Confirmation: **order number + total paid + ETA** plus receipt / track / *"Save my details"* next steps; an `ion-toast` confirms. |

**The safety-critical submit.** A `submittingRef` returns early on re-entry; a client-side
**idempotency key** is created once and **reused across retries** so the processor dedupes;
the Pay button is `disabled` + shows an `IonSpinner` the instant it is tapped. `try/catch/
finally` always resolves to a definite `success` **or** a recoverable `error` — never a
limbo. Offline `handlePay` returns *before* the transport is called; a decline leaves all
input untouched, so **Pay again** retries with the same key.

**Always-visible, editable, honest order summary.** A single scroll opens with the
itemized summary — line items (each with a quantity **stepper**), then
`Subtotal · Shipping · Tax · Discount · Total`. Amounts use `font-variant-numeric:
tabular-nums` so digits stay column-aligned as totals recompute, and every figure is
formatted with **`Intl.NumberFormat(locale, { style: 'currency', currency })`** — change
`locale`/`currency` and the whole column re-localizes. The total also rides the sticky
button, so the price the user agreed to is what gets charged (PAY-006).

**Prominent guest checkout.** *Continue as guest* is the primary CTA; *Sign in* is a
secondary link and any account ask is deferred to the success screen — never a login wall
(PAY-003, AUTH-010).

**Native Pay, surfaced early, platform-styled.** An **Apple Pay** (iOS) / **Google Pay**
(Android) shortcut sits near the top, selected via `isPlatform()`. Its brand fill is the
one platform-mandated literal, held in `checkout.css` as `--app-native-pay-bg` /
`--app-native-pay-fg` so the component never inlines a brand hex. If the Pay sheet can't
start (biometric/NFC unavailable), the screen **falls back to manual card entry** and
never blocks checkout (PERM-004).

**Tokens via CSS variables.** `CheckoutScreen.tsx` holds zero raw `#hex`/`px` — colors come
from `--ion-color-*` / `--ion-color-step-*`, spacing/radius from `--app-space-*` /
`--app-radius-*`, all defined in `checkout.css`. Dark mode is a class **palette**
(`.ion-palette-dark`) — the component doesn't change, only the variable values do; verify
both with `contrast_check.py`.

**Adaptive (`mode`).** Ionic auto-renders `ios` vs `md` chrome/shape; the single component
tree feels native on both. Verify both modes before shipping (`PLAT-*`).

**Accessible payment (WCAG 2.2 · 3.3.8).** Card, expiry, CVV, and address fields use
`IonInput` with `autocomplete` hints (`cc-number`, `cc-exp`, `cc-csc`, `street-address`,
`postal-code`) and `inputmode="numeric"`, so **paste, autofill, and password managers**
all work — masking normalizes rather than blocks paste. Every field has a visible
`<label>`; the order total and any change to it announce via a `polite` live region, as do
*"Processing payment"* and the final result; icon-only actions carry `aria-label`.

**Thumb-zone & safe area.** The primary **Pay $X** action lives in a sticky footer padded
by `calc(var(--app-space-md) + var(--ion-safe-area-bottom))` so it clears the home
indicator; `IonContent` handles top insets (requires `viewport-fit=cover`).

**Targets.** All interactive controls are `IonButton` (≥48px) — including the quantity
steppers and payment-method options; no bare tappable icons.

**Dynamic Type & RTL.** No fixed text heights, no sub-12px fonts; totals are conveyed as
tabular text (never colour alone). Layout uses logical CSS (flex, `slot="start"/"end"`,
`padding-inline`) — no physical `left/right` — so it mirrors in RTL and currency follows
the locale.

## Dependencies

| Package | Why |
|---|---|
| `@ionic/react` + `ionicons` | Ionic components + icon set. |
| `@capacitor/network` | Connectivity that **blocks the charge** offline and drives the banner. |

```bash
npm install @ionic/react ionicons @capacitor/network
```

Add `<meta name="viewport" content="viewport-fit=cover" />` and import a dark palette
(`@ionic/react/css/palettes/dark.system.css` or `dark.class.css`) once in the app entry.

## Usage

```tsx
import CheckoutScreen from './examples/checkout/ionic/CheckoutScreen';

<CheckoutScreen
  locale="en-US"
  currency="USD"
  initialItems={cart.items}
  shipping={500}
  taxRate={0.084}
  discount={300}
  placeOrder={async ({ idempotencyKey, amount, currency }) =>
    api.charge({ idempotencyKey, amount, currency })   // reject => recoverable decline
  }
  requestNativePay={requestApplePay}                   // false/reject => card fallback
  onBrowse={() => history.push('/catalog')}            // empty-cart CTA
  onSignIn={() => history.push('/sign-in')}
  onViewReceipt={openReceipt}
  onTrackOrder={openTracking}
  onCreateAccount={() => history.push('/sign-up')}
  onClose={() => history.goBack()}
/>;
```

`placeOrder` / `requestNativePay` are injectable and default to mocks, so the file runs
standalone — **reject `placeOrder`** for the declined path (all fields survive), toggle
airplane mode to watch the charge get **blocked offline**, resolve `requestNativePay` to
`false` for the native-Pay → card fallback, and decrement every line item to reach the
designed empty-cart state.

## Validators

`python3 quality-checks/validators/run_all.py examples/checkout/ionic/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).

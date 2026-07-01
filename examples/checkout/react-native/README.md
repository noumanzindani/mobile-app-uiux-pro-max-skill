# Checkout — React Native (TypeScript)

A real, compiling implementation of the [Checkout spec](../spec.md) for React Native.
Every visual value resolves through semantic tokens; every screen condition is a
member of the `CheckoutStatus` union; the payment submit is **idempotent** and can
never double-charge; and the screen passes all six `quality-checks/validators` at
**100/100**.

```
react-native/
  checkoutTokens.ts  — semantic tokens (surface/container, action.primary + on,
                       status success/error, on-surface-strong, native-Pay brand fill,
                       spacing/radius/size/typography + `tabular` figures, motion).
                       The ONLY file allowed to hold raw literals; each is `// ux:ignore`.
  CheckoutScreen.tsx — the CheckoutScreen component (always-visible editable summary,
                       guest checkout, native Pay, address + payment, sticky Pay button,
                       all 8 states, idempotent submit, accessible).
  README.md          — this file.
```

## What it demonstrates

**Always-visible, editable, honest order summary.** A single `ScrollView` opens with
the itemized summary — line items (each with a quantity **stepper**), then
`Subtotal · Shipping · Tax · Discount · Total`. Amounts use `tabular`
(`fontVariant: ['tabular-nums']`) so digits stay column-aligned as totals recompute,
and every figure is formatted with **`Intl.NumberFormat(locale, { style: 'currency', currency })`**
— change `locale`/`currency` and the whole column re-localizes. The total also rides
the sticky button, so the price the user agreed to is what gets charged (PAY-006).

**Prominent guest checkout.** *Continue as guest* is the primary CTA in the identity
card; *Sign in* is a secondary link and any account ask is deferred to the success
screen (*"Save my details for next time"*) — never a login wall (PAY-003, AUTH-010).

**Native Pay, surfaced early, platform-styled.** An **Apple Pay** (iOS) / **Google Pay**
(Android) shortcut sits near the top. Its brand fill is the one platform-mandated
literal, and it lives in `checkoutTokens.ts` as `nativePayFill` / `onNativePay`
(tokenized, `// ux:ignore`) so the component never inlines a brand hex. If the Pay
sheet can't start (biometric/NFC unavailable) the screen **falls back to manual card
entry** and never blocks checkout (`permissionDenied`, PERM-004).

**Payment: native / saved / paste-safe new card.** The method selector offers native
Pay, a one-tap saved card (*Visa ending 4242*), or a new card. New-card entry uses the
**number pad** (`keyboardType="number-pad"`), `autoComplete` / `textContentType` hints
(`cc-number`, `cc-exp`, `cc-csc`), and **paste-safe masking**: `onChangeText` strips
non-digits and re-groups, so pasting `4242 4242 4242 4242` *or* `4242424242424242`
both work — masking never blocks paste (FRM-014, A11Y-015 / WCAG 2.2 §3.3.8).

**The safety-critical submit (PAY-007).**

```ts
const submittingRef = useRef(false);                 // hard double-charge guard
const idempotencyKey = useRef(makeIdempotencyKey()).current; // stable across retries
```

| Guarantee | How |
|---|---|
| **No double-charge** | `submittingRef` returns early on re-entry; the button is `disabled` + shows an `ActivityIndicator` the instant it's tapped; a client-side **idempotency key** is sent with every attempt and **reused on retry**, so the processor dedupes. |
| **No limbo** | `try/catch/finally` always resolves to a definite `success` **or** a recoverable `error` — the screen can never get stuck in `processing`. |
| **Offline blocks the charge** | If `!isConnected`, `handlePay` sets `offline`, announces a plain reason, and **returns without calling the transport**. All entries are preserved; the Pay button is disabled with a hint until connectivity returns (OFF-002). |
| **Decline preserves everything** | On rejection the input state is untouched, so the user taps **Pay again** with the *same* idempotency key — retry without re-entry (FRM-009). |

**All 8 states, as a union.** `CheckoutStatus =
'ideal' | 'empty' | 'loading' | 'processing' | 'error' | 'offline' | 'success' | 'permissionDenied'`:

| State | Behaviour in this screen |
|---|---|
| **loading** | Brief *"Calculating your total…"* with an `ActivityIndicator` (`role="progressbar"`). |
| **empty** | Designed empty-cart with a **Browse products** CTA — not a dead end (STATE-002). |
| **ideal** | Ready to pay: editable summary, native Pay, address + payment, sticky Pay button. |
| **processing** | Button disabled + spinner + *"Processing…"*; *"Processing payment"* announced. |
| **error** | Inline *"Card declined…"* banner; focus moves to it (`assertive`); all input kept; retry via Pay. |
| **offline** | Non-blocking banner; the charge is blocked with a reason; entries preserved. |
| **success** | Confirmation: **order number + total paid + ETA + receipt/track/save-details** next steps. |
| **permissionDenied** | Native Pay unavailable → inline note + automatic fallback to card; checkout continues. |

**Accessibility.** The total and any change to it announce via a `polite` live region
(`accessibilityLiveRegion` + `announceForAccessibility`); *"Processing payment"* and the
final success/decline announce too (A11Y-019). The Pay button is labeled with the amount
(*"Pay $55.95"*) and exposes `accessibilityState={{ disabled, busy }}`. Totals are conveyed
as text (never colour alone) and the discount pairs a *"Discount"* label with its value.
Steppers/edit/Pay are ≥48dp (min size + `hitSlop`). Text uses scalable token roles
(size ≥ 12, `allowFontScaling`, no fixed text heights) so it grows to 200% without clipping.

**Motion & reduce-motion.** The only animations are a subtle total cross-fade on change
and a brief success check-in — **`opacity`/`transform` only**, and the receipt is never
gated behind the check. Both collapse to an instant state change when
`AccessibilityInfo.isReduceMotionEnabled()` is on (MOT-004, PRG-001).

**Tokens & RTL.** `CheckoutScreen.tsx` contains zero raw hex/spacing literals — colours,
spacing (4/8 grid), radius, type roles, target sizes and motion all come from
`checkoutTokens.ts`; dark mode is automatic via `useColorScheme()` → `getColors()`.
Layout uses logical properties only (`flex-start`/`flex-end`, `paddingHorizontal`,
`writingDirection`) with **no `left`/`right`/`marginLeft`** anywhere, so amounts sit at
the row end and the whole screen mirrors under `I18nManager.isRTL` (L10N-001, L10N-005).

## Dependencies

Beyond `react` / `react-native`:

| Package | Why |
|---|---|
| [`react-native-safe-area-context`](https://github.com/th3rdwave/react-native-safe-area-context) | `useSafeAreaInsets()` + `SafeAreaView` — precise insets so the sticky Pay button clears the home indicator (never hardcode `34`/`44`). |
| [`@react-native-community/netinfo`](https://github.com/react-native-netinfo/react-native-netinfo) | Connectivity detection that **blocks the charge** offline, drives the offline banner, and re-enables Pay on reconnect. |

```bash
npm install react-native-safe-area-context @react-native-community/netinfo
# or: yarn add react-native-safe-area-context @react-native-community/netinfo
```

Wrap the app once in `<SafeAreaProvider>` (from `react-native-safe-area-context`) so
`useSafeAreaInsets()` resolves.

> **Native Pay in a real app.** The Apple Pay / Google Pay shortcut here is a
> platform-*styled* button wired to an injectable `requestNativePay` mock. In production,
> present the real sheet via a platform library — e.g.
> [`@stripe/stripe-react-native`](https://github.com/stripe/stripe-react-native) (`PlatformPay`)
> or `react-native-payments` — and pass the resulting token to your `placeOrder`. Keep the
> **same client-side idempotency key** across the native-Pay and card paths.

## Usage

```tsx
import CheckoutScreen from './examples/checkout/react-native/CheckoutScreen';

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
  onBrowse={() => navigation.navigate('Catalog')}      // empty-cart CTA
  onSignIn={() => navigation.navigate('SignIn')}
  onViewReceipt={openReceipt}
  onTrackOrder={openTracking}
  onCreateAccount={() => navigation.navigate('SignUp')}
  onClose={() => navigation.goBack()}
/>;
```

`placeOrder` and `requestNativePay` are injectable and default to lightweight mocks, so
the file compiles and runs standalone:

- **reject `placeOrder`** to exercise the `error` (declined) path — note all fields survive,
- toggle connectivity (airplane mode) to watch the charge get **blocked offline**,
- **resolve `requestNativePay` to `false`** (or throw) for the native-Pay → card fallback,
- decrement every line item to reach the designed **empty-cart** state.

## Validators

`python3 quality-checks/validators/run_all.py examples/checkout/react-native/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint ·
state_coverage · dynamic_type_check · rtl_check` all PASS).

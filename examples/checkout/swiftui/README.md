# Checkout — SwiftUI

A real, compiling SwiftUI implementation of the checkout example in [`../spec.md`](../spec.md).
It renders a trustworthy, low-friction checkout — prominent guest checkout, a
native Apple Pay shortcut, an always-visible honest total, an editable review,
and an **idempotent payment that cannot double-charge** — built entirely from
semantic tokens.

## Files

| File | Role |
|---|---|
| `CheckoutTokens.swift` | Semantic token layer — Color / spacing / radius / size / Font (incl. a `.monospacedDigit()` amount style) / motion. **The only file allowed raw values** (each raw line ends with `// ux:ignore`). |
| `CheckoutScreen.swift` | The `CheckoutScreen` view + `CheckoutViewModel` — all 8 states, always-visible summary, address + payment forms, sticky Pay bar, idempotent submit. Zero literals; everything reads from `CheckoutTokens`. |

> **One target / one module.** Both files belong to the **same Xcode target
> (module)**. `CheckoutScreen.swift` references `CheckoutTokens` directly
> (same-module, no `import`), and the private `Color` shim in
> `CheckoutTokens.swift` is `internal` to that module. Add **both** files to the
> same app/framework target — do not split them across modules or the token
> references won't resolve.

## PassKit / Apple Pay note

- The native Apple Pay shortcut uses **`PayWithApplePayButton`** from **PassKit**,
  which exists only on the **iOS** SDK. Both the `import PassKit` and the button
  are wrapped in `#if os(iOS) … #endif`; under the macOS SDK the screen falls back
  to an equivalent `.borderedProminent` "Pay with Apple Pay" `Button`, so the file
  compiles on **both** toolchains. (Verified: `swiftc -typecheck` passes against
  both the iOS and macOS SDKs.)
- This example **simulates** the Apple Pay result (it doesn't present a real
  `PKPaymentAuthorizationController`). In production, add the **Apple Pay
  capability** + a merchant ID, build a `PKPaymentRequest` from the line items and
  total, and start the charge from the button's action closure. The idempotency
  key in `CheckoutViewModel` is exactly the value you'd send as the payment
  processor's `Idempotency-Key` header.

## What it demonstrates

- **8-state model** via `enum CheckoutStatus { ideal, empty, loading, processing, error, offline, success, permissionDenied }` — the body switches on state instead of boolean soup. `processing` is the **safety-critical** state.
- **Always-visible, itemized order summary** (subtotal / shipping / tax / discount / total) at the top of the single scroll, so there's **no surprise at the end**. Amounts use the `.monospacedDigit()` `amountFont` / `totalAmountFont` for tabular figures and format with **locale currency** via `total.formatted(.currency(code:))`. The total change animates with `.contentTransition(.numericText())` and is **announced** to VoiceOver.
- **Prominent guest checkout:** "Checking out as guest — no account required" is the default; sign-in is a secondary link, and the account ask is **deferred to the success screen** ("Save your details?").
- **Native Apple Pay surfaced early** with `PayWithApplePayButton` (guarded, macOS fallback), plus a saved one-tap card and a new-card option.
- **Address + payment forms are paste / autofill / password-manager friendly** (WCAG 2.2 §3.3.8): `.textContentType(.name / .fullStreetAddress / .addressCity / .addressState / .postalCode / .emailAddress / .creditCardNumber)` and number-pad keyboards, with every iOS-only content type and `.keyboardType` wrapped in `#if os(iOS)`. The **card field is paste-safe** — nothing blocks a paste — and uses `.monospacedDigit()`.
- **Editable review** — each line item has a **Stepper** (≥48pt) that recomputes and re-announces the total, plus a **Remove** action; removing the last item drops to the **empty-cart** state with a **Browse** CTA (never a dead end).
- **Idempotent, un-double-chargeable submit.** `CheckoutViewModel.pay()` holds a **client idempotency key**; the moment it's tapped the button `.disabled(!canPay)` flips (because `canPay` is false while `.processing`) and shows a `ProgressView`, so **a second tap is impossible**. Every attempt resolves to a **definitive** outcome — a real success or a **recoverable** decline — **never a limbo**. A mid-charge connection drop reconciles to the offline reason **without re-charging** (the key stays stable across retries and only rotates once an order is placed).
- **Offline blocks the charge** with a clear reason via a top `.safeAreaInset` banner; the Pay button disables and **all entered data is preserved** — the charge never fires silently or twice.
- **Decline preserves ALL input** — a specific, recoverable message ("Card declined — try another payment method. Your details are saved.") with a **Try again** that needs no re-entry.
- **Permission-denied path:** if Apple Pay is unavailable (biometric/NFC), the flow **explains and falls back to manual card entry** — it never blocks checkout.
- **Success = a real receipt:** order number + total charged + estimated delivery ETA + next steps (Track / View details) + the deferred account offer.
- **Sticky, full-width primary button showing the amount** pinned with `.safeAreaInset(edge: .bottom)` (rides above the keyboard and home indicator); its accessibility label always carries the amount even while it reads "Processing…", and it announces "Processing payment" and the result via `AccessibilityNotification.Announcement`.
- **Motion** is opacity / number-transition only and collapses to ~instant under `@Environment(\.accessibilityReduceMotion)` via `CheckoutTokens.reveal` / `totalChange`.
- **Dynamic Type:** every text uses a scaling `Font` text style — no fixed point sizes, no fixed heights on text — so totals and labels reflow to 200% without clipping.
- **RTL-safe:** logical `.leading` / `.trailing` / `.horizontal` only — no physical left/right, so it mirrors automatically; currency/number formatting follows the locale.

## Cross-SDK color shim

`CheckoutTokens.swift` copies the login/chat cross-platform pattern **exactly**: a
`private extension Color` guarded with `#if canImport(UIKit) … #elseif
canImport(AppKit) … #endif`, returning Apple **semantic** system colors
(`.systemBackground` / `.windowBackgroundColor`, `.label` / `.labelColor`,
`.secondaryLabel`, `.separator`, `.systemGreen`, `.systemRed`, …). This keeps the
token layer compiling on **both** the iOS (UIKit) and macOS (AppKit) toolchains —
never bare `Color(uiColor:)` at the top level, which fails under the macOS SDK.
Light / dark / Increase-Contrast resolve automatically; in a shipping app these
token names would instead resolve to asset-catalog Color sets generated from the
design system's DTCG tokens.

## iOS target notes

- **Deployment target: iOS 17+ / macOS 14+.** Uses `AccessibilityNotification.Announcement`, the two-parameter `.onChange(of:)`, `.contentTransition(.numericText())`, and `.scrollDismissesKeyboard`. `PayWithApplePayButton` is iOS 16+; `Decimal.formatted(.currency(code:))` and `Locale.current.currency` are iOS 16+.
- **Reachability** uses `NWPathMonitor` (Network framework). A demo **"Offline"** toolbar toggle (plus "Simulate decline" and "Apple Pay available") lets you exercise the offline / error / permission-denied paths without dropping Wi‑Fi.
- **iOS 26 "Liquid Glass":** by using system components (`.buttonStyle(.borderedProminent)`, the `.bar` material behind the sticky footer, `PayWithApplePayButton`) the screen adopts Liquid Glass for free on iOS 26 and degrades to a solid-surface look on earlier releases. No hand-rolled translucency.
- Drop `CheckoutScreen()` into a `WindowGroup` / `NavigationStack` and pass `onBrowse` / `onDone` to wire navigation.

## Validators

Passes `quality-checks/validators/run_all.py examples/checkout/swiftui` — **100/100**:

- **token_lint** — no hex / `Color(0x…)` and no off-grid spacing in `CheckoutScreen.swift`; raw values live only in `CheckoutTokens.swift`, each suppressed with `// ux:ignore`. Spacing is on the 4/8 grid.
- **contrast_check** — theme token pairs meet WCAG 2.2 (label roles ≥ 4.5:1 both themes).
- **target_size_lint** — the Pay button, method rows, steppers, remove/track actions, and the toolbar button all use `.frame(minHeight: CheckoutTokens.buttonMinHeight / targetMin)` (48); no undersized interactive frames.
- **state_coverage** — `loading`, `empty` (`isEmpty`), `error` / `retry`, `offline` (and `success`) all referenced.
- **dynamic_type_check** — scaling `Font` text styles only; no fixed heights on text lines; no sub-12pt fonts.
- **rtl_check** — logical leading/trailing only; no physical directional properties.

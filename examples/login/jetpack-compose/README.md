# Login — Jetpack Compose (Material 3 Expressive)

A real, compiling reference implementation of the [login spec](../spec.md) for **Jetpack
Compose** on Android, using **Material 3 Expressive**. It is the flagship "get me into my
account with the fewest taps" screen: paste-friendly, all-states, accessible, keyboard-safe,
and edge-to-edge.

## Files

| File | Role |
|---|---|
| [`LoginTokens.kt`](LoginTokens.kt) | Semantic token layer — the **only** file with raw values (`Color`, `Dp` spacing/size/radius, millis). Colors/typography/shape resolve through `MaterialExpressiveTheme`; spacing/size/radius are carried as `Space` / `Size` / `Radius` token objects. Every literal line is marked `// ux:ignore`. |
| [`LoginScreen.kt`](LoginScreen.kt) | The `LoginScreen` composable + a stateless `LoginScreenContent`, the `LoginStatus` state model, `LoginActivity` (edge-to-edge host), and one `@Preview` per state. Consumes **only** tokens + `MaterialTheme` roles. |

## What it demonstrates

- **7 states** via a sealed `LoginStatus`: `Idle`, `Empty`, `Loading`, `Error`, `Offline`,
  `Success`, `PermissionDenied` — driven through a `when` so coverage is auditable.
- **Accessible authentication (WCAG 2.2 · 3.3.8):** email + password `OutlinedTextField`s with
  `KeyboardOptions(KeyboardType.Email / .Password)` and **autofill semantics**
  (`contentType = ContentType.EmailAddress` / `.Password`) so paste, password managers,
  passkeys, and OS autofill all work — no "retype your password" or CAPTCHA barrier.
- **Labeled show/hide password** as an `IconToggleButton` (48dp by default) that exposes its
  state via `stateDescription` ("Password shown" / "Password hidden") and a per-state
  `contentDescription` ("Show password" / "Hide password").
- **Generic error** ("Email or password is incorrect.") that **never reveals which field**
  failed, is announced through a status `Text` with `liveRegion = Assertive`, **preserves all
  input**, and **moves focus** back to the first field.
- **Offline banner** — non-blocking, announced politely; the primary action disables with a
  reason (auth needs a network), input preserved.
- **Success** offers **biometric opt-in with a password fallback** (opt-in, never forced);
  **permission-denied** falls back cleanly to password with an optional Settings link — never a
  dead end.
- **Full-width primary "Sign in"** with an inline spinner + "Signing in…" label; disabled during
  flight so **double-submit is blocked**. **Google + Sign in with Apple** SSO are visually
  subordinate. Forgot password / Create account / Continue as guest are all reachable.
- **Keyboard-safe & edge-to-edge:** `enableEdgeToEdge()` in `LoginActivity`, `Scaffold` with
  `WindowInsets.safeDrawing`, and `Modifier.imePadding()` on a scrolling column so fields and the
  CTA stay above the keyboard.
- **RTL-safe:** logical `padding(start/end)` / `padding(horizontal=)`, RTL-aware
  `Arrangement.End` / `Alignment.CenterHorizontally` — no physical left/right.
- **Dynamic Type:** every text role comes from `MaterialTheme.typography` (scales with font
  scale to 200%); no fixed heights on text; layout reflows via `verticalScroll`.
- **Motion:** only **opacity** animates (error fade ≤200ms, no shake), with a **reduce-motion**
  fallback — `rememberReduceMotion()` reads `Settings.Global.ANIMATOR_DURATION_SCALE` and swaps
  the spec to `snap()` (instant) when animations are turned off.

## Validators

Passes the five `LoginScreen.kt`-scoped rules audited by
[`quality-checks/validators/run_all.py`](../../../quality-checks/validators/run_all.py):
`token_lint`, `target_size_lint`, `dynamic_type_check`, `rtl_check`, `state_coverage`.

```bash
python3 quality-checks/validators/run_all.py "examples/login/jetpack-compose"
```

## Compose BOM note

Pin dependency versions through the **Compose BOM** (verified against **`2025.x`**, which ships
`androidx.compose.material3` with the **Expressive** APIs — `MaterialExpressiveTheme`,
`MotionScheme`, the 10-step corner scale — targeting Android 16 / API 36). The autofill
`ContentType` semantics require **Compose UI 1.8+** (included in BOM 2025.x).

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.06.00")) // use the current 2025.x BOM

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended") // Visibility / VisibilityOff
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.activity:activity-compose:1.9.0+") // enableEdgeToEdge, setContent
}
```

> Material You dynamic color (Android 12+) can be layered on `LoginTheme` by sourcing the
> `ColorScheme` from `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` with
> the brand palette in `LoginTokens.kt` as the fallback.

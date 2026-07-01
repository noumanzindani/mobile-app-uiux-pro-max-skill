# Chat — Jetpack Compose (Material 3 Expressive)

A real, compiling reference implementation of the [chat spec](../spec.md) for **Jetpack
Compose** on Android, using **Material 3 Expressive**. It is the flagship "send a message and
know it went through — instantly" screen: optimistic, offline-resilient, virtualized,
accessible, keyboard-safe, and edge-to-edge.

## Files

| File | Role |
|---|---|
| [`ChatTokens.kt`](ChatTokens.kt) | Semantic token layer — the **only** file with raw values (`Color`, `Dp` spacing/size/radius, millis). Colors/typography/shape resolve through `MaterialExpressiveTheme`; spacing/size/radius are carried as `Space` / `Size` / `Radius` token objects; the own/other **bubble + delivery-status** colors ride a `CompositionLocal` (`LocalChatColors`) read as `MaterialTheme.chatColors`. Every literal line is marked `// ux:ignore`. |
| [`ChatScreen.kt`](ChatScreen.kt) | The `ChatScreen` composable + a stateless `ChatScreenContent`, the `MessageStatus` and `ChatStatus` state models, `ChatActivity` (edge-to-edge host), and one `@Preview` per state. Consumes **only** tokens + `MaterialTheme` roles. |

## What it demonstrates

- **Virtualized, inverted list.** `LazyColumn(reverseLayout = true)` with stable `key = { it.key }`
  composes only visible bubbles and pins the newest to the bottom. Date separators are woven in
  as their own row type; a typing row is declared first so it renders below the newest message.
- **Own vs other bubbles on opposite sides.** RTL-aware `Arrangement.End` / `Arrangement.Start`
  plus `Alignment.End` / `Alignment.Start` — no physical left/right, so alignment and the
  auto-mirrored back/send icons flip correctly in right-to-left locales.
- **Optimistic send** via a sealed `MessageStatus`: `Sending`, `Sent`, `Delivered`, `Read`,
  `Failed`, `Queued`. An optimistic bubble is appended immediately, then transitions
  `sending → sent → delivered → read`. A **failed** send keeps its text and shows a
  **badge + tap-to-retry**; an **offline** send is **queued** and **auto-flushes with backoff**
  on reconnect — nothing is ever silently dropped.
- **Status = icon + TEXT, never color alone** (`A11Y-012`): a clock/check/double-check/error
  glyph paired with a "Sending / Sent / Delivered / Read / Failed / Queued" label, and each
  bubble is one **merged node** read as "sender, message, time, status" (`A11Y-014`).
- **"N new messages" pill** that fades in when you scroll up and **smooth-scrolls to the bottom**
  on tap (instant under reduce-motion).
- **Typing indicator** whose dots **pause under reduce-motion** and are exposed as status via
  `stateDescription` + a polite `liveRegion` — motion, not meaning.
- **7 states** via a sealed `ChatStatus`: `Idle`, `Empty`, `Loading`, `Error`, `Offline`,
  `Success`, `PermissionDenied` — a skeleton while history loads, a "Say hi 👋" first-use empty,
  an inline **retry** banner that keeps cached messages, a non-blocking **offline** banner, a
  discreet **delivered/read** announcement, and a graceful **attach permission-denied** fallback
  (pick from files · Settings) that never dead-ends the chat.
- **Keyboard-safe & edge-to-edge:** `enableEdgeToEdge()` in `ChatActivity`, `Scaffold` with
  `WindowInsets.safeDrawing`, and `Modifier.imePadding()` so the composer Row (attach · growing
  `OutlinedTextField` · send) rides above the keyboard and above the home indicator.
- **RTL-safe:** logical `padding(start/end)` / `padding(horizontal=)`, RTL-aware
  `Arrangement`/`Alignment`, and `Icons.AutoMirrored.*` for the back and send glyphs — no
  physical left/right anywhere.
- **Dynamic Type:** every text role comes from `MaterialTheme.typography` (scales to 200%); no
  fixed heights on text; bubbles and the composer grow with content.
- **Motion:** only **opacity + offset** animate — the outgoing bubble insert (`Modifier.animateItem`)
  and the pill fade — each with a **reduce-motion** `snap()` fallback via `rememberReduceMotion()`
  (reads `Settings.Global.ANIMATOR_DURATION_SCALE`).
- **Contrast:** own/other bubble text clears WCAG 2.2 body contrast (≥ 4.5:1) on both fills in
  both themes (e.g. white on `#2563EB` = 5.17:1 light; `#E3E2E6` on `#2B2930` = 11:1 dark).

> **Demo hooks (reference-only):** typing a message containing "fail" simulates a failed send;
> the cloud icon in the top bar toggles offline to exercise the queue + auto-flush path; a peer
> reply is simulated after each successful send to drive the typing indicator and new-message pill.

## Validators

Passes the five `ChatScreen.kt`-scoped rules audited by
[`quality-checks/validators/run_all.py`](../../../quality-checks/validators/run_all.py):
`token_lint`, `target_size_lint`, `dynamic_type_check`, `rtl_check`, `state_coverage` (plus the
repo-wide `contrast_check`) — **100/100**.

```bash
python3 quality-checks/validators/run_all.py "examples/chat/jetpack-compose"
```

## Compose BOM note

Pin dependency versions through the **Compose BOM** (verified against **`2025.x`**, which ships
`androidx.compose.material3` with the **Expressive** APIs — `MaterialExpressiveTheme`,
`MotionScheme`, the 10-step corner scale — targeting Android 16 / API 36). `Modifier.animateItem`
(the stable successor to `animateItemPlacement`) requires **Compose Foundation 1.7+**, included in
BOM 2025.x.

The delivery-status and connectivity glyphs (`Schedule`, `DoneAll`, `ErrorOutline`, `CloudQueue`,
`CloudOff`, `CloudDone`, `AttachFile`, and the auto-mirrored `ArrowBack` / `Send`) come from
**`material-icons-extended`** — add that dependency, or swap in your own icon set.

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.06.00")) // use the current 2025.x BOM

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended") // Send / DoneAll / CloudOff …
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.activity:activity-compose:1.9.0+") // enableEdgeToEdge, setContent
}
```

> Material You dynamic color (Android 12+) can be layered on `ChatTheme` by sourcing the
> `ColorScheme` from `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` with
> the brand palette in `ChatTokens.kt` as the fallback. The `ChatColors` bubble roles stay on
> `LocalChatColors` so they swap with the theme regardless of the color source.

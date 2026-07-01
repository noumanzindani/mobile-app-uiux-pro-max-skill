# Chat — React Native (TypeScript)

A real, compiling implementation of the [Chat spec](../spec.md) for React Native.
Every visual value resolves through semantic tokens; every screen condition is a
member of a discriminated union; each message carries a true delivery lifecycle;
and the screen passes all six `quality-checks/validators` at **100/100**.

```
react-native/
  chatTokens.ts   — semantic tokens (own/other bubble bg+text ≥4.5:1, status,
                    spacing/radius/size/typography/motion). The ONLY file allowed
                    to hold raw literals; each raw line is `// ux:ignore`.
  ChatScreen.tsx  — the ChatScreen component (inverted virtualized list, optimistic
                    send, offline queue, typing indicator, all 7 states, accessible).
  README.md       — this file.
```

## What it demonstrates

**Inverted, virtualized message list.** A `FlatList inverted` renders newest at the
bottom with `initialNumToRender` / `maxToRenderPerBatch` / `windowSize` /
`removeClippedSubviews` tuned so long histories stay smooth. Only `transform` /
`opacity` are animated during scroll (PERF-001).

**Own vs other bubbles, mirrored in RTL.** Alignment is *logical*: rows use
`justifyContent: 'flex-start' | 'flex-end'` and bubbles use
`borderTopStartRadius` / `borderTopEndRadius` + `writingDirection`, so the whole
layout flips automatically under `I18nManager.isRTL`. Directional glyphs (back
chevron, send arrow) mirror via `transform: scaleX`. There is no
`left`/`right`/`marginLeft` anywhere — only `start`/`end` logical properties.

**Optimistic send with a real lifecycle.**

```ts
type MessageStatus = 'sending' | 'sent' | 'delivered' | 'read' | 'failed' | 'queued';
```

An outgoing bubble is appended immediately (`sending`), then transitions
`sent → delivered → read`. Status is always conveyed as **icon + TEXT** (never
colour alone, A11Y-012) and each transition is announced to assistive tech.

| Case | Behaviour |
|---|---|
| **failed** | The bubble shows a ⚠ badge + *"Not delivered — tap to retry"*. The whole bubble is a retry button; **content is preserved** (CHAT-006). |
| **offline** | Sends are `queued` (never dropped) and **auto-flush on reconnect** (OFF-002). A non-blocking banner keeps the conversation readable from cache. |
| **read** | A discreet *"Delivered"* toast + a `polite` announcement (STATE-009). |

**Typing indicator.** Three looping dots (`opacity` + `translateY` only). Under
**reduce-motion** the loop is paused *and* the indicator is exposed as status text
(*"typing…"*) in the header and as an `accessibilityLabel` on the bubble
(A11Y-011, CHAT-002).

**All 7 states, as a discriminated union.** `ChatStatus` has members literally named
`idle · empty · loading · error · offline · success · permissionDenied`:

| State | Behaviour in this screen |
|---|---|
| **loading** | Skeleton bubbles matching the loaded layout; `accessibilityRole="progressbar"`. |
| **empty** | First-run *"Say hi 👋"* prompt — a designed empty, not a blank list. |
| **error** | History-load failure shows an inline **Try again** banner and keeps any cached messages; focus moves to it and it is announced (`assertive`). |
| **offline** | Non-blocking banner + queued sends (see above). |
| **idle / success** | Ready conversation; `success` is the transient delivered confirmation. |
| **permissionDenied** | Attach denial explains why, links to **Settings**, and offers a Files fallback — chat keeps working underneath (PERM-004). |

**Keyboard & safe-area.** The composer (attach · growing `TextInput` · send) rides
above the keyboard via `KeyboardAvoidingView` and clears the home indicator via
`useSafeAreaInsets().bottom`. The field grows with content up to
`size.composerMax`, then scrolls internally. Send/attach/retry targets are ≥48dp
(min size + `hitSlop`).

**Accessibility.** Each bubble is a single grouped element (`accessible`) read as
*"sender, message, time, status"*. Incoming messages announce via
`accessibilityLiveRegion` + `announceForAccessibility` (A11Y-019). Text uses
scalable token roles (`fontSize ≥ 12`, `allowFontScaling` left at its default
`true`, no fixed text heights), so it grows to 200% without clipping.

**Tokens only.** `ChatScreen.tsx` contains zero raw hex/spacing literals — colours,
spacing (4/8 grid), radius, type roles, target sizes and motion durations all come
from `chatTokens.ts`. Dark mode is automatic via `useColorScheme()` → `getColors()`,
and both bubble fills clear WCAG 4.5:1 for their text in **both** themes.

## Dependencies

Beyond `react` / `react-native`:

| Package | Why |
|---|---|
| [`react-native-safe-area-context`](https://github.com/th3rdwave/react-native-safe-area-context) | `useSafeAreaInsets()` + `SafeAreaView` — precise per-edge insets so the composer clears the home indicator (never hardcode `34`/`44`). |
| [`@react-native-community/netinfo`](https://github.com/react-native-netinfo/react-native-netinfo) | Connectivity detection that drives the `offline` banner, the send queue, and the auto-flush on reconnect. |

```bash
npm install react-native-safe-area-context @react-native-community/netinfo
# or: yarn add react-native-safe-area-context @react-native-community/netinfo
```

Wrap the app once in `<SafeAreaProvider>` (from `react-native-safe-area-context`)
so `useSafeAreaInsets()` resolves.

## Usage

```tsx
import ChatScreen from './examples/chat/react-native/ChatScreen';

<ChatScreen
  peerName="Alex Rivera"
  loadHistory={async () => api.fetchMessages(threadId)}    // reject => error state
  sendTransport={async (text) => api.send(threadId, text)} // reject => failed bubble
  requestAttachPermission={requestPhotoAccess}             // false/reject => permissionDenied
  onBack={() => navigation.goBack()}
  onCall={startCall}
  onOverflow={openThreadMenu}
/>;
```

`loadHistory`, `sendTransport`, and `requestAttachPermission` are injectable and
default to lightweight mocks, so the file compiles and runs standalone:

- **reject `sendTransport`** to exercise the `failed` → tap-to-retry path,
- toggle connectivity (airplane mode) to see queued sends **auto-flush** on reconnect,
- **resolve `requestAttachPermission` to `false`** (or throw) for the permission-denied card.

With `autoReply` (default `true`), a sent message triggers a simulated peer typing
indicator + incoming reply so the live region and inverted-scroll behaviours are
easy to see in the demo. Set `autoReply={false}` in tests.

## Validators

`python3 quality-checks/validators/run_all.py examples/chat/react-native/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint ·
state_coverage · dynamic_type_check · rtl_check` all PASS).

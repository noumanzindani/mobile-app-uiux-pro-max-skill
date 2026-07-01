# Chat — Ionic (React + Capacitor, TypeScript)

A real implementation of the [Chat spec](../spec.md) for **Ionic 8**. Every visual
value resolves through CSS custom properties; every one of the 7 UI states is modeled
explicitly; each message carries a true delivery lifecycle; and the screen passes all
six `quality-checks/validators` (**100/100**).

```
ionic/
  chat.css        — token + style layer: --app-* / --ion-* variables and classes
                    (bubble colours, spacing, radius, target, typing animation).
                    The ONLY file with raw values; the screen references var(...) only.
  ChatScreen.tsx  — the ChatScreen component (inverted list, optimistic send,
                    offline queue, typing indicator, all 7 states, accessible).
  README.md       — this file.
```

> Bindings shown are `@ionic/react`; the same component/token approach applies to
> `@ionic/angular` and `@ionic/vue`.

## What it demonstrates

**All 7 states, as a discriminated union.** `ChatStatus` has members literally named
`idle · empty · loading · error · offline · success · permissionDenied`, so TypeScript
forces exhaustive handling.

| State | Behaviour |
|---|---|
| **idle** | Ready conversation, grouped bubbles, auto-scrolled to latest. |
| **empty** | First-run *"Say hi 👋"* prompt — a designed empty, not a blank list ([[STATE-002]]). |
| **loading** | `IonSkeletonText` bubbles matching the loaded layout; `role="progressbar"`. |
| **error** | History-load failure shows an inline **Try again** banner keeping any cached messages; focus moves to it and it is announced. |
| **offline** | Non-blocking banner + Retry (via `@capacitor/network`); sends are **queued** and **auto-flush on reconnect** — never dropped ([[OFF-002]]). |
| **success** | The optimistic bubble reaches *read*; a discreet `ion-toast` confirms *"Delivered"* ([[STATE-009]]). |
| **permissionDenied** | Attach denial opens an `IonModal` that explains why + **Open Settings** + a Files fallback — chat keeps working underneath ([[PERM-004]]). |

**Optimistic send with a real lifecycle.**

```ts
type MessageStatus = 'sending' | 'sent' | 'delivered' | 'read' | 'failed' | 'queued';
```

An outgoing bubble is appended immediately (`sending`), then transitions
`sent → delivered → read`. Status is always conveyed as **icon + TEXT** (never colour
alone, [[A11Y-012]]) and each transition is announced to assistive tech.

| Case | Behaviour |
|---|---|
| **failed** | The bubble shows a warning icon + *"Not delivered — tap to retry"* and a **Retry `IonButton`**; **content is preserved** ([[CHAT-006]]). |
| **offline** | Sends are `queued` (never dropped) and **auto-flush on reconnect** ([[OFF-002]]); the banner keeps the conversation readable from cache. |
| **read** | A discreet *"Delivered"* `ion-toast` + a `polite` live-region announcement. |

**Inverted message list, mirrored in RTL.** The list is `flex-direction: column-reverse`
so the newest message sits at the bottom; own/other rows use `justify-content: flex-end
| flex-start` and bubbles use `border-start-*-radius` logical properties, so the whole
layout flips automatically in RTL. Directional glyphs (back chevron, send arrow) mirror
via a `.chat-mirror` `[dir="rtl"]` rule. There is no physical `left`/`right` anywhere.

**Typing indicator.** Three looping dots (opacity + `translateY` only). Under
`prefers-reduced-motion` the loop is paused in CSS *and* the indicator stays exposed as
status text (*"typing…"*) in the header and as an `aria-label` on the bubble
([[A11Y-011]], [[CHAT-002]]).

**Tokens via CSS variables.** `ChatScreen.tsx` holds zero raw `#hex`/`px` — colours come
from `--ion-color-*` / `--ion-color-step-*` (bubble roles derived from
`--ion-color-primary` so both themes track it), spacing/radius/target from `--app-space-*`
/ `--app-radius-*` / `--app-target`, all defined in `chat.css`. Dark mode is a class
**palette** (`.ion-palette-dark`) — the component doesn't change, only the variable
values do; verify both bubble fills with `contrast_check.py`.

**Adaptive (`mode`).** Ionic auto-renders `ios` vs `md` chrome/shape; the single component
tree feels native on both. Verify both modes before shipping ([[PLAT-*]]).

**Keyboard & safe-area.** The composer (attach · growing `IonTextarea autoGrow` · send)
lives in an `IonFooter` so it rides above the keyboard, and `chat.css` pads it by
`calc(var(--app-space-sm) + var(--ion-safe-area-bottom))` so it clears the home indicator
(requires `viewport-fit=cover`). The field grows to `max-height`, then scrolls internally.

**Targets.** All interactive controls are `IonButton` (≥48px via `--app-target`); no bare
tappable `IonIcon` — the failed bubble exposes an explicit **Retry** `IonButton`.

**Accessibility.** Each bubble is a grouped element (`role="group"`) read as *"sender,
message, time, status"*. Incoming messages announce via a `polite` live region; the
composer field, send, attach, and retry controls are all labelled. Delivery status has a
text + icon equivalent (not colour-only, [[A11Y-012]]).

**Dynamic Type & RTL.** No fixed text heights, no sub-12px fonts; layout uses logical CSS
(flex, `slot="start"/"end"`, `padding-inline`, `inset-inline-end`) — no physical
`left/right` — so it mirrors in RTL and grows with the OS font scale.

## Dependencies

| Package | Why |
|---|---|
| `@ionic/react` + `ionicons` | Ionic components + icon set. |
| `@capacitor/network` | Connectivity for the `offline` state / banner / queue auto-flush. |

```bash
npm install @ionic/react ionicons @capacitor/network
```

Add `<meta name="viewport" content="viewport-fit=cover" />` and import a dark palette
(`@ionic/react/css/palettes/dark.system.css` or `dark.class.css`) once in the app entry.

## Usage

```tsx
import ChatScreen from './examples/chat/ionic/ChatScreen';

<ChatScreen
  peerName="Alex Rivera"
  loadHistory={async () => api.fetchMessages(threadId)}     // reject => error state
  sendTransport={async (text) => api.send(threadId, text)}  // reject => failed bubble
  requestAttachPermission={requestPhotoAccess}              // false/reject => permissionDenied
  onBack={() => history.goBack()}
  openSettings={() => NativeSettings.open(/* … */)}
/>;
```

`loadHistory`, `sendTransport`, and `requestAttachPermission` are injectable and default
to lightweight mocks, so the file runs standalone:

- **reject `sendTransport`** to exercise the `failed` → tap-to-retry path,
- toggle connectivity (airplane mode) to see queued sends **auto-flush** on reconnect,
- **resolve `requestAttachPermission` to `false`** (or throw) for the permission-denied card.

With `autoReply` (default `true`), a delivered message triggers a simulated peer typing
indicator + incoming reply so the live region and inverted-scroll behaviours are easy to
see in the demo. Set `autoReply={false}` in tests.

## Validators

`python3 quality-checks/validators/run_all.py examples/chat/ionic/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).

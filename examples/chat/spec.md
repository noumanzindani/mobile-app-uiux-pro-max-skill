# Example Spec — Chat

> Purpose: Reference specification for a 1:1 / group chat screen with optimistic send, offline queue + retry, correct keyboard and safe-area handling, and full accessibility. This is a spec, not code — it defines intent, the 7-state map, layout/thumb-zone, accessibility, tokens, motion, and the validator-backed acceptance gate. Implementations live in `chat/<framework>/`.

## Contents
- [Intent / user goal](#intent--user-goal)
- [Platforms & frameworks](#platforms--frameworks)
- [Patterns & rules used](#patterns--rules-used)
- [Layout & thumb-zone](#layout--thumb-zone)
- [States map (all 7)](#states-map-all-7)
- [Message delivery states](#message-delivery-states)
- [Accessibility](#accessibility)
- [Token usage](#token-usage)
- [Motion](#motion)
- [Acceptance checklist](#acceptance-checklist)

---

## Intent / user goal

"Send a message and know it went through — instantly." The user reads the conversation, composes, sends, and relies on clear status (sending / sent / delivered / read / failed). Reliability under flaky connectivity is the defining requirement.

**Success = messages appear instantly, reflect true delivery status, survive connectivity loss, and never silently vanish.**

## Platforms & frameworks

- **Paradigm:** Adaptive. iOS HIG (input accessory bar above keyboard, `.sheet` for attachments) / Android M3 (input row, `imePadding`). Keyboard + safe-area handling is the hardest part and platform-specific.
- **Frameworks (v1, flagship = all four):** Flutter, React Native, SwiftUI, Jetpack Compose — each using its keyboard-avoidance + safe-area primitives and a **virtualized, inverted** message list.

## Patterns & rules used

- Patterns: [`feed-patterns.md`](../../patterns/feed-patterns.md) (optimistic + virtualization), [`empty-error-offline.md`](../../patterns/empty-error-offline.md).
- Rules: [[CHAT-001]] (optimistic send + status), [[CHAT-002]] (typing/read receipts), [[CHAT-003]] (keyboard + safe-area), [[CHAT-004]] (message grouping), [[CHAT-005]] (scroll-to-bottom / new-message), [[CHAT-006]] (failed send retry), [[CHAT-007]] (timestamps), [[CHAT-008]] (attachments), [[OFF-001]]/[[OFF-002]]/[[OFF-003]] (optimistic/queue/sync), [[LST-001]] (virtualize).

## Layout & thumb-zone

```
Top:     Nav bar — back, avatar + name, presence/typing, call/overflow
Middle:  Virtualized message list (inverted; newest at bottom)          [[LST-001]]
Bottom:  Composer row — attach · text field (grows) · send
         (rides above keyboard; above home-indicator when dismissed)    [[CHAT-003]]
```

| Zone | Contents |
|---|---|
| Bottom arc (easy reach) | **Composer**: text field, send button, attach — the most-used controls, always thumb-reachable ([[CHAT-003]]) |
| Middle | Message bubbles, date separators, "N new messages" pill |
| Top | Back, contact identity, presence/typing, call/overflow (low-frequency) |

- Composer stays pinned above the keyboard; when keyboard dismisses it sits above the home-indicator inset ([[CHAT-003]], [[SPC-016]], [[SPC-011]]).
- Send button ≥44pt/48dp; grows the field up to a max height then scrolls internally ([[A11Y-003]], [[FRM-003]]).
- Bubbles inset from screen edges; own/other messages align to opposite sides and mirror in RTL ([[L10N-001]]).

## States map (all 7)

| State | When | How it looks |
|---|---|---|
| **Ideal** | Conversation loaded | Grouped bubbles by sender + time; read receipts; composer ready; auto-scrolled to latest. |
| **Empty** | New conversation | Friendly first-message prompt ("Say hi 👋") — a first-use empty, not a blank list ([[STATE-002]]). |
| **Loading** | Opening / fetching history | Skeleton bubbles; **pull-up loads older messages** with a top spinner, preserving scroll anchor ([[STATE-005]], [[LST-004]]). |
| **Error** | History/send failed | History load: inline retry banner keeping any cached messages ([[STATE-007]]). Send failure: the bubble shows a **failed badge + tap-to-retry**, content preserved ([[CHAT-006]], [[FRM-009]]). |
| **Offline** | No connectivity | Non-blocking offline banner; conversation readable from cache; sends are **queued (sending…)** and auto-flush with backoff on reconnect — never dropped ([[STATE-008]], [[OFF-002]], [[OFF-004]]). |
| **Success** | Message delivered | Optimistic bubble transitions sending → sent → delivered → read; "delivered/read" announced discreetly ([[STATE-009]], [[CHAT-002]]). |
| **Permission-denied** | Attach/camera/mic denied | Attachment feature explains + Settings link + fallback (pick from files); chat itself keeps working ([[STATE-010]], [[PERM-004]], [[PERM-005]]). |

## Message delivery states

The optimistic-send lifecycle ([[CHAT-001]], [[OFF-001]], [[OFF-003]]):

```
compose → SENDING (optimistic bubble, ghosted, clock icon)
        → SENT (single check)
        → DELIVERED (double check)
        → READ (filled / colored — with non-color cue)     [[A11Y-012]]
   fail → FAILED (badge + "Tap to retry"), content kept     [[CHAT-006]]
offline → QUEUED (sending…), auto-retry on reconnect         [[OFF-002]]
```

Status is conveyed by **icon + text**, never color alone ([[A11Y-012]]); each status is announced to assistive tech ([[A11Y-019]]).

## Accessibility

- Each bubble is a grouped element read as "sender, message, time, status" so a screen reader gets the whole message coherently ([[A11Y-014]], [[CHAT-007]]).
- **New incoming messages announce** via a live region; typing indicator is exposed as status, not decorative motion ([[A11Y-019]], [[CHAT-002]]).
- Delivery status has a text/icon equivalent (not color-only) ([[A11Y-012]]).
- Composer field labeled; send button labeled + reflects enabled/disabled; attach button labeled ([[A11Y-004]], [[A11Y-006]]).
- Focus/keyboard order: list → composer; focus not obscured by the keyboard ([[A11Y-008]], [[A11Y-009]], [[A11Y-020]]).
- Contrast ≥4.5:1 for bubble text on both bubble colors, both themes — verify the sent-bubble tint too ([[A11Y-001]], [[DRK-004]]).
- Targets ≥44pt/48dp; Dynamic Type to 200% grows bubbles/composer without clipping ([[A11Y-003]], [[A11Y-010]]).
- RTL mirrors bubble alignment and directional icons ([[L10N-001]], [[L10N-004]]).

## Token usage

| Element | Token |
|---|---|
| Screen background | `color.surface` |
| Own bubble bg / text | `color.chat.self.bg` / `color.on.chat.self` (≥4.5:1) |
| Other bubble bg / text | `color.chat.other.bg` / `color.on.chat.other` |
| Delivery/status icon | `color.status.info` / `color.status.error` (failed) + icon |
| Composer field / send | `color.surface.container` / `color.action.primary` |
| Bubble text / timestamp | `type.body.md` / `type.label.sm` |
| Bubble radius | `radius.lg` (with tail per platform) ([[SHP-001]]) |
| List/composer padding | `space.4` horizontal, `space.2` between grouped bubbles ([[SPC-006]]) |
| Send target min | `size.target.min` |

Zero literals; both themes ([[COL-001]], [[DRK-001]]); `token_lint.py` clean.

## Motion

- Outgoing bubble: quick insert (slide/scale up from composer) ≤250ms; reduce-motion → appear instantly ([[MOT-001]], [[MOT-004]]).
- Status change (sending→sent→read): subtle icon cross-fade ≤150ms ([[MIC-001]]).
- Typing indicator: gentle looping dots; **paused/hidden under reduce-motion** and exposed as status text ([[A11Y-011]], [[CHAT-002]]).
- "New messages" pill: fade/slide in; tap smooth-scrolls to bottom ([[CHAT-005]]).
- Keyboard show/hide: composer + list move in sync with the keyboard, no jump ([[CHAT-003]]).
- Only transform/opacity while the list scrolls ([[PERF-001]]).

## Acceptance checklist

Validators (`run_all.py`):

- [ ] `token_lint.py` PASS — tokens only incl. bubble colors ([[COL-001]]).
- [ ] `contrast_check.py` PASS — bubble text ≥4.5:1 on both bubble fills, both themes ([[A11Y-001]]).
- [ ] `target_size_lint.py` PASS — send/attach/retry ≥44pt/48dp, ≥8dp apart ([[A11Y-003]]).
- [ ] `state_coverage.py` PASS — empty/loading/error/offline present (+ delivery states) ([[STATE-001]]).
- [ ] `dynamic_type_check.py` PASS — bubbles/composer grow, no clipping ([[A11Y-010]]).
- [ ] `rtl_check.py` PASS — bubble alignment + directional icons mirror ([[L10N-001]]).

Manual / prose:

- [ ] Send is optimistic; status sending→sent→delivered→read, icon+text not color-only ([[CHAT-001]], [[A11Y-012]]).
- [ ] Failed send keeps content + offers retry; nothing silently dropped ([[CHAT-006]]).
- [ ] Offline queues sends and auto-flushes with backoff on reconnect ([[OFF-002]]).
- [ ] Composer stays above the keyboard and above the home indicator ([[CHAT-003]], [[SPC-016]]).
- [ ] List virtualized/inverted; pull-up loads history preserving scroll anchor ([[LST-001]], [[LST-004]]).
- [ ] Incoming messages + status announced to assistive tech ([[A11Y-019]]).
- [ ] Attach-permission denial degrades gracefully with a fallback ([[PERM-004]]).
- [ ] Reduce-motion pauses typing dots and simplifies bubble insert ([[MOT-004]]).

# Social / Messaging — Domain Components

> Domain-specific components and their required states/behaviors. Each maps to core
> component rules (`[[LST-…]]`, `[[FRM-…]]`, `[[MIC-…]]`) and adds social/messaging
> constraints. Build these token-driven; no magic values.

## Table of contents

1. [Message bubble](#1-message-bubble)
2. [Typing & read receipts](#2-typing--read-receipts)
3. [Unread indicators](#3-unread-indicators)
4. [Media attachment](#4-media-attachment)
5. [Reaction / like control](#5-reaction--like-control)
6. [Composer](#6-composer)
7. [Rules](#rules)

---

## 1. Message bubble

The atomic unit of chat. One shared component; used for every message in every
thread.

- **Attribution in groups.** In group threads the bubble shows sender name and avatar
  (with a fallback for missing images, core `[[AVT-001]]`); 1:1 threads can omit it.
- **Accessible timestamp.** Even when the time is visually compact or shown on tap, the
  bubble's accessible label includes it, so a screen-reader user hears when a message
  was sent.
- **Outgoing status.** Own messages expose delivery/read status via icon **and** text,
  never color alone (`[[SOC-003]]`, core `[[A11Y-014]]`).
- **Failed treatment.** A failed message is clearly distinct (e.g. a red "Not
  delivered" label + retry icon) and offers **tap-to-retry** and delete
  (`[[SOC-007]]`) — it must not silently vanish.
- **Long-press actions** (copy, reply, react, report) each have a tap-accessible
  equivalent; never gesture-only for the report path (core `[[GES-001]]`, `[[SOC-013]]`).

## 2. Typing & read receipts

Socially loaded signals that must be optional and accessible.

- **Typing indicator** is throttled (it doesn't flicker on every keystroke) and has an
  accessible text equivalent ("Alex is typing"), announced politely, not conveyed by
  animation alone (`[[SOC-008]]`, `[[SOC-020]]`, core `[[A11Y-011]]`).
- **Read receipts** are user-controllable in Settings; disabling yours is reciprocal
  (you stop seeing others') or the trade-off is clearly disclosed (`[[SOC-008]]`, core
  `[[CHAT-002]]`).
- **Reduce-motion** swaps animated typing dots for a static label (core `[[MOT-010]]`).

## 3. Unread indicators

Unread state appears in three places — conversation list, in-thread divider, and feed
— and must never rely on color alone.

- **Conversation list:** an unread count or a dot with distinct shape/position/weight,
  plus bolder text — not just a colored dot (`[[SOC-009]]`, core `[[A11Y-014]]`).
- **In-thread divider:** a "New messages" divider marks where the user left off; it
  pairs with the scroll-to-latest affordance (`[[SOC-004]]`).
- **Badge accuracy:** opening a thread clears its badge, the conversation-list total
  updates, and the OS app-icon badge matches the in-app unread count (`[[SOC-009]]`,
  core `[[BDG-005]]`). Stale badges are a trust bug.

## 4. Media attachment

Images, video, files, and voice notes in feed and chat.

- **Placeholder → loaded/failed.** Every attachment shows a sized placeholder, an
  explicit loading state, and a failed state with retry — no broken-image glyphs
  (`[[SOC-010]]`, core `[[STATE-001]]`).
- **Alt text.** Images expose author-provided alt text (with a sensible auto/empty
  fallback) to assistive tech (`[[SOC-010]]`, `[[SOC-021]]`, core `[[MEDIA-002]]`).
- **No audio autoplay.** Media never autoplays with sound (`[[SOC-010]]`, core
  `[[MEDIA-004]]`). If feed video autoplays, it is muted, pausable, and disabled under
  reduce-motion / data-saver (`[[SOC-021]]`, core `[[MOT-010]]`).
- **Sensitive media** may be blurred behind an interstitial per `[[SOC-015]]`.

## 5. Reaction / like control

The signature delight moment of social apps — and an accessibility trap if done
carelessly.

- **Optimistic state change** first (`[[SOC-002]]`), then a micro-interaction: a subtle
  press-scale (core `[[MIC-002]]`) and a bouncy fill/burst on activation (core
  `[[MIC-004]]`), plus a light haptic.
- **Reduce-motion path:** swap the bounce/burst for a plain state change while keeping
  the haptic optional (`[[SOC-011]]`, core `[[MOT-010]]`).
- **Reachable target:** the control (and each reaction in a reaction picker) is a real
  ≥44pt/48dp tap target with a labeled role and selected state (core `[[A11Y-005]]`,
  `[[A11Y-007]]`).

## 6. Composer

The app's most-used control. It must never fight the user.

- **Attach + send affordances** are visible and labeled; send is a real ≥44pt/48dp
  target, not a tiny glyph (`[[SOC-012]]`, core `[[A11Y-005]]`).
- **Length/limit feedback.** Where a character or media limit exists, show a countdown
  as the user nears it and block over-limit send with an explainable message — never a
  silent truncation or a dead send button (`[[SOC-012]]`).
- **Multi-line growth** keeps send visible and the composer above the keyboard as the
  input grows (`[[SOC-004]]`, `[[SOC-012]]`, core `[[FRM-005]]`).
- **Draft safety:** in-progress text survives keyboard dismissal and (ideally) leaving
  the thread, per core `[[STATE-001]]`.

---

## Rules

### SOC-007 — Message bubble: status, timestamp, tap-to-retry on failure
- **Rule:** A message bubble MUST expose sender attribution in group contexts, a timestamp (at least via its accessible label when visually compact), delivery/read status for outgoing messages (icon + text, not color alone), and — on failure — a clearly distinct failed treatment offering tap-to-retry and delete. Long-press actions MUST each have a tap-accessible equivalent.
- **Why:** The bubble is the atomic unit of chat; missing timestamps, ambiguous status, or a failed message with no recovery path all break trust in message delivery and cause duplicate or lost messages.
- **Platforms:** all
- **Severity:** error
- **Check:** A group thread shows sender name/avatar; the bubble's accessible label includes the timestamp; outgoing bubbles show status via icon+text; a failed bubble offers retry and delete; report/react are reachable without gesture-only access.
- **See also:** [[SOC-003]], [[SOC-008]], [[SOC-013]], [[A11Y-014]], [[AVT-001]], [[CHAT-001]]

### SOC-008 — Typing & read receipts with a privacy setting
- **Rule:** If the app shows typing indicators or read receipts, it MUST provide a user setting to disable them; disabling read receipts MUST be reciprocal (you no longer see others') or the trade-off MUST be clearly disclosed. Typing and read state MUST have an accessible text equivalent and MUST NOT be conveyed by animation alone; animated indicators respect reduce-motion.
- **Why:** Receipts are socially loaded — forcing them on creates social pressure and a privacy harm; users expect control, and screen-reader and motion-sensitive users need non-visual, non-animated equivalents.
- **Platforms:** all
- **Severity:** warning
- **Check:** Settings expose typing and read-receipt toggles; disabling read receipts is reciprocal or disclosed; typing has an accessible label announced politely; animated dots have a reduce-motion fallback.
- **See also:** [[SOC-007]], [[SOC-020]], [[CHAT-002]], [[A11Y-011]], [[MOT-010]]

### SOC-009 — Unread indicators: badges/dividers, non-color-only, accurate
- **Rule:** Unread state (conversation-list badges, in-thread "new messages" dividers, feed "new posts") MUST be conveyed by more than color — a count, a dot with distinct shape/position/weight, or a labeled divider. Badge counts MUST stay accurate: opening a thread clears its badge, the list total updates, and the OS app-icon badge matches the in-app unread count.
- **Why:** Color-only unread dots fail color-blind users, and stale or wrong badge counts erode trust and create "phantom unread" anxiety and support load.
- **Platforms:** all
- **Severity:** warning
- **Check:** Unread uses count/shape/weight, not color alone; opening a thread clears its badge and updates the total; the app-icon badge matches the in-app count after read/receive events.
- **See also:** [[SOC-004]], [[SOC-007]], [[BDG-005]], [[A11Y-014]], [[A11Y-007]]

### SOC-010 — Media attachments: thumbnails, alt text, no autoplay audio
- **Rule:** Image, video, and file attachments MUST show a sized placeholder with explicit loading and failed (retry) states, MUST support alt text for images exposed to assistive tech, and MUST NOT autoplay audio. Any feed/video autoplay MUST be muted, pausable, and respect reduce-motion and data-saver settings.
- **Why:** Media that autoplays with sound is disruptive and inaccessible, missing alt text excludes blind users, and absent failed states leave broken thumbnails that read as bugs.
- **Platforms:** all
- **Severity:** warning
- **Check:** Attachments transition placeholder → loaded/failed; images expose alt text; no attachment plays audio without a tap; feed video autoplay is muted and stops under reduce-motion/data-saver.
- **See also:** [[SOC-012]], [[SOC-015]], [[SOC-021]], [[MEDIA-002]], [[MEDIA-004]], [[MOT-010]]

### SOC-011 — Like/reaction micro-interaction (bouncy, haptic, reduce-motion)
- **Rule:** Like/reaction controls SHOULD reinforce the optimistic state change with a tactile micro-interaction — a subtle press-scale, a bouncy fill/burst on activation, and a light haptic — but MUST honor reduce-motion by swapping the animation for a plain state change, and MUST keep the control (and each item in a reaction picker) a ≥44pt/48dp target with a labeled role and selected state.
- **Why:** Reaction delight is a signature of social apps and confirms the optimistic action, but motion-sensitive users need an escape hatch and the control must remain reachable and legible to assistive tech.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Like shows press-scale + bounce + haptic; enabling reduce-motion disables the animation while keeping the state change; hit target ≥44pt/48dp with an accessible selected state.
- **See also:** [[SOC-002]], [[MIC-002]], [[MIC-004]], [[MOT-010]], [[A11Y-005]]

### SOC-012 — Composer: attach, send, character/limit affordances
- **Rule:** The message/post composer MUST provide visible, labeled attach and send affordances (send being a real ≥44pt/48dp target), and where a length/media limit exists MUST show a countdown as the user nears it and block over-limit send with an explainable message — never a silent truncation or a dead button. Multi-line growth MUST keep the send control visible and the composer above the keyboard.
- **Why:** A composer with a hidden or tiny send button, a silent character cap, or input that overflows behind the keyboard frustrates the app's single most frequent action.
- **Platforms:** all
- **Severity:** warning
- **Check:** Composer shows attach + send; a limit indicator warns near the cap and blocks over-limit with a message; the send target is ≥44pt/48dp; multi-line growth keeps send visible above the keyboard.
- **See also:** [[SOC-004]], [[SOC-010]], [[FRM-005]], [[A11Y-005]], [[A11Y-007]]

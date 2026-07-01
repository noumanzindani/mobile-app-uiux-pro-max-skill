# Social / Messaging — Screen Patterns

> Domain screen recipes: how core rules combine into correct feed and chat flows.
> Rules here are feed, optimistic-action, and messaging patterns. Cross-references
> use `[[ID]]`; core rules are referenced, never restated.

## Table of contents

1. [The feed (infinite scroll + refresh)](#1-the-feed-infinite-scroll--refresh)
2. [Optimistic actions & visible rollback](#2-optimistic-actions--visible-rollback)
3. [Chat send lifecycle](#3-chat-send-lifecycle)
4. [Chat keyboard, safe-area & scroll](#4-chat-keyboard-safe-area--scroll)
5. [Notification priming](#5-notification-priming)
6. [Feed position preservation](#6-feed-position-preservation)
7. [Rules](#rules)

---

## 1. The feed (infinite scroll + refresh)

The feed is the beating heart of a social app; it must feel fast, endless, and
recoverable — never broken.

- **Virtualize the list.** Recycle rows so a 10,000-item timeline scrolls at 60fps
  without leaking memory (core `[[LST-001]]`). Never render the whole list.
- **Skeletons, not spinners.** On first load and while paginating, show content-
  shaped skeletons so the surface reads as "loading a feed," not "frozen"
  (core `[[LST-002]]`). A lone center spinner on a full-screen feed is a smell.
- **Pull-to-refresh at the top; prefetch at the bottom.** Refresh is the expected
  top gesture (core `[[LST-003]]`); pagination should prefetch the next page
  *before* the user hits the end so scrolling never stalls (`[[SOC-001]]`).
- **Every terminal state is designed.** Empty ("Nothing here yet — follow people to
  fill your feed"), error ("Couldn't load — Retry"), and a real end-of-feed marker
  ("You're all caught up") are distinct states (core `[[STATE-001]]`), never a blank
  screen or an eternal loader.
- **Refresh preserves the reader.** New posts from a refresh insert behind a "new
  posts" pill rather than jumping the viewport (`[[SOC-006]]`).

## 2. Optimistic actions & visible rollback

Social interactions must feel instantaneous, but "instant" cannot mean "dishonest."

- **Update the UI first, reconcile second.** A like, reaction, comment, follow, or
  post applies to the UI immediately, then confirms against the server
  (`[[SOC-002]]`, core `[[OFF-002]]`). The heart fills the moment the finger lifts —
  reinforced by the reaction micro-interaction (`[[SOC-011]]`).
- **Roll back visibly on failure.** If the server rejects (rate limit, deleted post,
  network loss), return the control to its prior value and show a non-blocking,
  dismissible error with **Retry** — a snackbar with an action fits well
  (core `[[BDG-001]]`). Never silently keep a like the server refused, and never
  silently discard a comment the user believes was posted.
- **Queue while offline.** Actions taken offline queue and replay on reconnect,
  surfacing an offline state rather than a false success (core `[[STATE-004]]`,
  `[[OFF-002]]`).
- **Keep counts honest.** A like-count increment that later fails must decrement
  back, and the change should be announced to assistive tech (`[[SOC-020]]`).

## 3. Chat send lifecycle

Messaging's core promise is: *my message left the device and reached the person.*
The UI must make that promise legible at every step.

- **Show the message immediately in "sending."** The bubble appears in the thread the
  instant the user taps send, in a pending state (`[[SOC-003]]`, core `[[CHAT-001]]`).
- **Progress through explicit statuses.** sending → sent → delivered → read (if
  receipts are on) → **failed**. Status is conveyed by icon **and** text/label, never
  color alone (`[[SOC-007]]`, core `[[A11Y-014]]`).
- **Failure stays put and is recoverable.** A failed message remains in place, is
  visually distinct, and offers **tap-to-retry** plus delete — it must never vanish
  or silently reorder (`[[SOC-003]]`, `[[SOC-007]]`).
- **Reconcile ordering carefully.** When the server assigns the real timestamp, the
  message must not jump disorientingly; preserve stable ordering.

## 4. Chat keyboard, safe-area & scroll

The single most-failed screen in messaging apps. Get the keyboard right or the app
is unusable.

- **Composer floats above the keyboard.** When the keyboard opens, the input and the
  latest message stay visible; the list resizes/insets rather than hiding behind the
  keyboard (`[[SOC-004]]`, core `[[CHAT-003]]`, `[[FRM-005]]`).
- **Respect safe-area insets.** The composer sits above the home indicator; content
  avoids the notch/cutout and status bar. Test on a device with a home indicator and
  a punch-hole camera.
- **Scroll-to-latest, but don't hijack.** On open and on send, scroll to the newest
  message. If the user has scrolled up to read history, **do not** snap them down on
  a new incoming message — show a "jump to latest ↓" affordance (often with an unread
  count) instead (`[[SOC-004]]`, `[[SOC-009]]`).

## 5. Notification priming

Push permission on iOS is one-shot: a denied prompt can't be re-asked in-app. Treat
the OS prompt as a scarce resource.

- **Prime before you prompt.** Show an in-context screen that names the concrete
  value ("Get notified when a friend replies") with **Allow** / **Not now**, and only
  fire the OS dialog after the user opts in (`[[SOC-005]]`, core `[[NOTIF-001]]`,
  `[[PERM-001]]`). Declining the priming screen must **not** spend the OS prompt.
- **Ask at a moment of demonstrated value.** After the first message sent or first
  follow — not on a cold first launch.
- **Handle denial gracefully.** If already denied, don't nag; offer a path to Settings
  when the user later tries to enable notifications (core `[[PERM-003]]`).
- **Every notification deep-links to context.** Tapping a "new message" push opens
  that thread, not the home screen (core `[[NOTIF-003]]`); copy stays honest
  (`[[SOC-019]]`).

## 6. Feed position preservation

Losing the user's place is a top complaint and a silent retention killer.

- **Back-navigation lands where they left off.** Opening a post and returning restores
  scroll position and already-loaded items — don't rebuild the feed from scratch
  (`[[SOC-006]]`, core `[[LST-001]]`).
- **Never override system back.** Back behaves predictably; don't hijack it to exit
  the app or dump the user at the top (core `[[NAV-003]]`).
- **Refresh inserts without jumping.** New items load behind a pill; tapping it scrolls
  to the top intentionally (`[[SOC-001]]`).
- **Survive process death where feasible.** On restore, return the user near their
  prior position rather than to a cold top-of-feed (core `[[STATE-001]]`).

---

## Rules

### SOC-001 — Feed: virtualized infinite scroll + pull-to-refresh + skeletons
- **Rule:** The primary feed MUST virtualize/recycle its list, show content-shaped skeletons on first load and while paginating, support pull-to-refresh at the top, and prefetch the next page before the user reaches the end. It MUST render distinct loading, empty, error (with retry), and end-of-feed states — never a blank screen or an unbounded spinner with no content.
- **Why:** The feed is the app's core surface; unvirtualized lists jank and leak memory, missing skeletons read as frozen, and a feed with no visible end or error state traps the user in an ambiguous loading limbo.
- **Platforms:** all
- **Severity:** warning
- **Check:** Feed uses a virtualized/recycling list; skeletons render on load and during pagination; pull-to-refresh fires at the top; empty/error/end-of-feed states are each present and distinct.
- **See also:** [[SOC-006]], [[LST-001]], [[LST-002]], [[LST-003]], [[STATE-001]]

### SOC-002 — Optimistic like/post/comment with visible rollback
- **Rule:** Likes, reactions, follows, comments, and posts MUST update the UI optimistically and reconcile against the server: on success keep the state; on failure roll the UI back to its prior value and surface a non-blocking, dismissible error with a **Retry** affordance. The rollback MUST be visible — the app MUST NOT silently keep an action the server rejected or silently discard one the user believes succeeded. Offline actions queue and replay on reconnect.
- **Why:** Instant feedback is expected in social apps, but an action that appears to succeed and silently fails corrupts the user's mental model and can mask moderation, rate-limit, or network problems.
- **Platforms:** all
- **Severity:** error
- **Check:** Trigger an action offline and with a forced server error; the UI updates instantly, then rolls back with a retry affordance on failure; queued actions replay on reconnect; counts revert correctly.
- **See also:** [[SOC-003]], [[SOC-011]], [[SOC-020]], [[OFF-002]], [[STATE-004]], [[BDG-001]]

### SOC-003 — Chat: optimistic send with status ticks (sending → sent → delivered → read → failed)
- **Rule:** Outgoing messages MUST appear in the thread immediately in a "sending" state and progress through an explicit status lifecycle: sending → sent → delivered → read (when receipts are enabled) → failed. Status MUST be conveyed by icon **and** text/label, not color alone. A failed message MUST remain in place, be visually distinct, and offer tap-to-retry (and delete); it MUST NOT disappear or silently reorder.
- **Why:** Messaging users need to trust that a message left the device and arrived; a message that vanishes or gives no delivery signal breaks the fundamental promise of chat and generates confusion and duplicate sends.
- **Platforms:** all
- **Severity:** error
- **Check:** Send a message with the network off; the bubble shows "sending" then "failed" with retry; statuses read via icon+text (grayscale-safe); message ordering stays stable through reconciliation.
- **See also:** [[SOC-007]], [[SOC-004]], [[CHAT-001]], [[OFF-002]], [[A11Y-014]]

### SOC-004 — Chat keyboard avoidance + safe-area + scroll-to-latest
- **Rule:** The chat screen MUST keep the composer and the latest message visible when the keyboard is open, respect safe-area insets (notch, cutout, home indicator, status bar), and auto-scroll to the newest message on open and on send — while NOT force-scrolling a user who has scrolled up to read history. Provide a "jump to latest" affordance for new incoming messages instead of snapping the viewport.
- **Why:** A composer hidden behind the keyboard or under the home indicator makes chat unusable; auto-scrolling away from history the user is actively reading is equally disruptive and a frequent regression.
- **Platforms:** all
- **Severity:** error
- **Check:** Open the keyboard on a device with a notch and home indicator; the composer stays above both the keyboard and safe area; sending scrolls the new message into view; scrolling up shows a jump-to-latest control and no forced snap on incoming messages.
- **See also:** [[SOC-003]], [[SOC-012]], [[CHAT-003]], [[FRM-005]]

### SOC-005 — Prime notifications before the OS permission prompt
- **Rule:** Before triggering the OS push-notification permission dialog, the app MUST show an in-context priming screen that names the specific value and lets the user decline **without** spending the one-shot OS prompt. The OS prompt fires only at a moment of demonstrated value, never cold on first launch. If permission was already denied, the app MUST NOT nag and MUST offer a Settings path when the user later opts in.
- **Why:** The iOS prompt is one-shot and cannot be re-asked in-app; a cold prompt gets denied and permanently cuts off re-engagement for users who would have said yes in context. Android 13+ also runtime-prompts and benefits from the same priming.
- **Platforms:** all (iOS one-shot; Android 13+ runtime prompt)
- **Severity:** warning
- **Check:** First launch does not immediately fire the OS prompt; a priming screen with allow / not-now precedes it; declining priming does not consume the OS prompt; a denied state routes to Settings rather than re-prompting.
- **See also:** [[SOC-019]], [[NOTIF-001]], [[NOTIF-003]], [[PERM-001]], [[PERM-003]]

### SOC-006 — Preserve feed position on refresh and return
- **Rule:** Returning to the feed from a detail screen, or refreshing it, MUST preserve the user's scroll position and retain already-loaded content. New items from a pull-to-refresh MUST be inserted without jumping the viewport (e.g. a "new posts" pill), and back-navigation MUST land the user where they left off. Where feasible, restore near the prior position after process death.
- **Why:** Losing scroll position on every navigation forces users to re-scroll content they've already seen — a top frustration that shortens sessions and wastes data.
- **Platforms:** all
- **Severity:** warning
- **Check:** Scroll deep into the feed, open a post, navigate back — position is retained; pull-to-refresh inserts via a pill without jumping; back is not overridden; process-death restore returns near the prior position where feasible.
- **See also:** [[SOC-001]], [[LST-001]], [[NAV-003]], [[STATE-001]]

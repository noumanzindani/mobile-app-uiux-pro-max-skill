# Chat & Messaging (CHAT)

> Purpose: Build responsive, trustworthy messaging — optimistic send with delivery status, typing indicators, robust keyboard and safe-area handling, an offline queue, and safety controls.

## Contents
- [CHAT-001 — Optimistic send with a pending state](#chat-001--optimistic-send-with-a-pending-state)
- [CHAT-002 — Per-message delivery status with non-color cues](#chat-002--per-message-delivery-status-with-non-color-cues)
- [CHAT-003 — Debounced typing indicators with timeout](#chat-003--debounced-typing-indicators-with-timeout)
- [CHAT-004 — Keyboard avoidance keeps the composer visible](#chat-004--keyboard-avoidance-keeps-the-composer-visible)
- [CHAT-005 — Handle safe-area insets for the composer](#chat-005--handle-safe-area-insets-for-the-composer)
- [CHAT-006 — Scroll-to-bottom affordance and auto-scroll on own send](#chat-006--scroll-to-bottom-affordance-and-auto-scroll-on-own-send)
- [CHAT-007 — Queue messages offline and retry with backoff](#chat-007--queue-messages-offline-and-retry-with-backoff)
- [CHAT-008 — Failed messages offer retry and delete](#chat-008--failed-messages-offer-retry-and-delete)
- [CHAT-009 — Report, block, and mute are reachable](#chat-009--report-block-and-mute-are-reachable)
- [CHAT-010 — Virtualize the message list and paginate history](#chat-010--virtualize-the-message-list-and-paginate-history)
- [CHAT-011 — Group messages and show date separators](#chat-011--group-messages-and-show-date-separators)
- [CHAT-012 — Multiline composer grows then scrolls](#chat-012--multiline-composer-grows-then-scrolls)
- [CHAT-013 — Messages are fully accessible to screen readers](#chat-013--messages-are-fully-accessible-to-screen-readers)
- [CHAT-014 — Media and link previews load lazily and never autoplay audio](#chat-014--media-and-link-previews-load-lazily-and-never-autoplay-audio)
- [CHAT-015 — Unread divider and accurate mark-read semantics](#chat-015--unread-divider-and-accurate-mark-read-semantics)
- [CHAT-016 — Provide all 7 states for the chat surface](#chat-016--provide-all-7-states-for-the-chat-surface)

---

### CHAT-001 — Optimistic send with a pending state
- **Rule:** A sent message MUST appear in the thread immediately in a 'sending' state before the server confirms; the composer clears on send, not on ack.
- **Why:** Instant echo makes messaging feel real-time; waiting for a round-trip before showing the message feels broken.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — send on a throttled network and confirm the message shows immediately as pending.
- **Exceptions:** None.
- **See also:** [[CHAT-002]], [[CHAT-008]], [[OFF-002]]

### CHAT-002 — Per-message delivery status with non-color cues
- **Rule:** Each outgoing message MUST show its state — sending, sent, delivered, read (and failed) — using distinct icons/shapes plus accessible labels, never color alone.
- **Why:** Status closes the communication loop; colorblind and screen-reader users need shape/label, not just a color change (WCAG §1.4.1).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — walk a message through each state; VoiceOver/TalkBack announces status.
- **Exceptions:** Read receipts may be disabled by user/privacy setting; then omit only the read state.
- **See also:** [[CHAT-001]], [[CHAT-013]], [[A11Y-018]]

### CHAT-003 — Debounced typing indicators with timeout
- **Rule:** Typing indicators MUST debounce (emit no more than every ~1–3s) and auto-clear after a few seconds of inactivity or on send, so they never stick permanently.
- **Why:** Uncontrolled typing events are chatty and, when they get stuck 'on', mislead the other party.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — type intermittently and confirm the indicator throttles and clears.
- **Exceptions:** Contexts where typing state is intentionally disabled for privacy.
- **See also:** [[CHAT-013]], [[PERF-009]]

### CHAT-004 — Keyboard avoidance keeps the composer visible
- **Rule:** When the keyboard opens, the message composer and the latest messages MUST remain visible above it; the input is never obscured by the keyboard or IME.
- **Why:** A composer hidden behind the keyboard makes the app unusable; WCAG §2.4.11 also forbids focused inputs being obscured.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — open the keyboard and verify the composer and recent messages stay visible.
- **Exceptions:** None.
- **See also:** [[CHAT-005]], [[FRM-015]], [[A11Y-022]]

### CHAT-005 — Handle safe-area insets for the composer
- **Rule:** The composer MUST inset from the home indicator / gesture bar (bottom safe area) and from notches/cutouts, read dynamically, so text and the send button are never clipped.
- **Why:** Hardcoded bottom padding clips the input on gesture-nav devices and breaks across form factors.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — on a gesture-nav device confirm the composer clears the home indicator.
- **Exceptions:** None.
- **See also:** [[CHAT-004]], [[SPC-016]]

### CHAT-006 — Scroll-to-bottom affordance and auto-scroll on own send
- **Rule:** Auto-scroll to the newest message when the user sends, and show a scroll-to-bottom / new-message button when they have scrolled up; do NOT yank the view down while they read history.
- **Why:** Users expect their own messages to bring them to the bottom, but forcibly scrolling during reading is disorienting.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll up, receive a message (button appears), then send (jumps to bottom).
- **Exceptions:** None.
- **See also:** [[CHAT-010]], [[CHAT-015]]

### CHAT-007 — Queue messages offline and retry with backoff
- **Rule:** Messages composed offline MUST persist locally, show a queued state, and auto-send with exponential backoff when connectivity returns; they survive app restart.
- **Why:** Mobile networks drop constantly; losing a typed message on a dead connection is unacceptable.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — send in airplane mode, kill the app, reconnect, confirm delivery.
- **Exceptions:** None.
- **See also:** [[CHAT-008]], [[OFF-001]], [[OFF-004]]

### CHAT-008 — Failed messages offer retry and delete
- **Rule:** A message that fails to send MUST show a clear failed state with tap-to-retry and a remove/delete option, without blocking composition of new messages.
- **Why:** Silent failures make users think a message was sent when it was not; explicit retry restores trust.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — force a send failure and confirm retry + delete affordances.
- **Exceptions:** None.
- **See also:** [[CHAT-002]], [[CHAT-007]]

### CHAT-009 — Report, block, and mute are reachable
- **Rule:** Every conversation and message context MUST expose report, block, and mute controls within one or two taps; block takes effect immediately and confirms.
- **Why:** Safety tooling is a baseline UGC requirement and is mandated by App Store 1.2 / Play UGC policies for social apps.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — locate report/block/mute from a conversation and a single message.
- **Exceptions:** Closed 1:1 systems (e.g. internal enterprise chat) may scope which controls apply.
- **See also:** [[CHAT-016]], [[PROF-005]]

### CHAT-010 — Virtualize the message list and paginate history
- **Rule:** The message list MUST be virtualized (lazy/windowed) and load older history in pages on scroll-up, preserving scroll position when older messages prepend.
- **Why:** Rendering thousands of bubbles at once janks and OOMs; jumpy scroll on prepend loses the user's place.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll a long thread; verify smooth paging and stable position.
- **Exceptions:** Very short, bounded threads may render fully.
- **See also:** [[CHAT-006]], [[LST-001]], [[PERF-004]]

### CHAT-011 — Group messages and show date separators
- **Rule:** Consecutive messages from the same sender within a short window MUST be visually grouped, with date/day separators between clusters and accessible timestamps available on demand.
- **Why:** Grouping and date anchors make long threads scannable and reduce visual noise.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify grouping and day separators in a multi-day thread.
- **Exceptions:** None.
- **See also:** [[CHAT-013]], [[SPC-006]]

### CHAT-012 — Multiline composer grows then scrolls
- **Rule:** The input MUST grow with content up to a max height (≈4–6 lines) then scroll internally; send stays reachable, and Enter behavior (send vs newline) is predictable per platform.
- **Why:** A single-line input hides long messages; unbounded growth eats the whole screen.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — type several lines and confirm capped growth with internal scroll.
- **Exceptions:** None.
- **See also:** [[CHAT-004]], [[FRM-009]]

### CHAT-013 — Messages are fully accessible to screen readers
- **Rule:** Each message MUST expose sender, direction (sent/received), content, and status as a coherent accessible label; incoming messages should announce via a live region when the thread is focused.
- **Why:** Without semantic grouping a screen reader reads disconnected fragments and misses who said what.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — navigate the thread with VoiceOver/TalkBack.
- **Exceptions:** None.
- **See also:** [[CHAT-002]], [[A11Y-018]], [[A11Y-024]]

### CHAT-014 — Media and link previews load lazily and never autoplay audio
- **Rule:** Inline images/video/link previews MUST load lazily with a placeholder; video does not autoplay with sound (muted-only if at all), and voice notes require an explicit play tap.
- **Why:** Auto-playing audio in a chat is intrusive and a §1.4.2 concern; lazy media keeps scroll smooth.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll media-heavy threads; confirm no audio autoplay and smooth loading.
- **Exceptions:** None.
- **See also:** [[MEDIA-002]], [[CHAT-010]]

### CHAT-015 — Unread divider and accurate mark-read semantics
- **Rule:** Show a persistent 'unread' divider at the first unread message and reflect unread counts; mark messages read only when actually viewed, and update badges consistently.
- **Why:** A reliable unread marker lets users resume where they left off; inaccurate counts erode trust in notifications.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — receive messages while away, reopen, and verify divider + count behavior.
- **Exceptions:** Systems where read tracking is disabled by privacy setting.
- **See also:** [[CHAT-006]], [[NOTIF-007]]

### CHAT-016 — Provide all 7 states for the chat surface
- **Rule:** Chat screens MUST design ideal, empty (no messages yet — invite to start), loading (fetching history), error (send/load failure), offline (queued/degraded), success (message delivered), and permission-denied (mic/photos/notifications declined).
- **Why:** Messaging spans network, permissions, and empty conversations; each unhandled state degrades a core flow.
- **Platforms:** all
- **Severity:** error
- **Check:** state_coverage.py on the chat screen set.
- **Exceptions:** Permission-denied is N/A for text-only chat requesting no OS permission.
- **See also:** [[STATE-001]], [[CHAT-007]], [[PERM-004]]

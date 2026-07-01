# Social / Messaging — Domain Accessibility

> Social/messaging accessibility on top of core `[[A11Y-…]]` rules. The domain's
> a11y risks concentrate around **real-time content that changes under the user**,
> **media without text alternatives**, and **autoplaying motion**. Cross-references
> use `[[ID]]`; core rules are referenced, never restated.

## Focus areas

### Live, changing content

Social and chat UIs mutate constantly — messages arrive, counts tick, someone starts
typing — and a screen-reader user perceives none of it unless you announce it.

- **Announce what matters, politely.** A new incoming message, "X is typing," a
  like/reaction count change on the focused item, or "new posts available" should be
  announced via an appropriately-polite live region (`[[SOC-020]]`, core `[[A11Y-011]]`).
- **Batch and throttle.** A busy group chat or a fast-liking post must not fire an
  announcement per event — batch rapid updates so assistive tech stays usable
  (`[[SOC-020]]`). Politeness (`polite`, not `assertive`) keeps announcements from
  stomping the user's current reading.
- **Don't announce what the user did themselves** redundantly — confirm their own send
  through message status (`[[SOC-003]]`), not a competing live-region blast.

### Media alternatives

- **Alt text on images.** Every image supports author-provided alt text exposed to
  assistive tech, with a sensible fallback (`[[SOC-021]]`, core `[[MEDIA-002]]`); the
  composer should invite users to add it.
- **Captions/transcripts on video & audio.** Video and voice notes offer captions or
  transcripts so deaf/hard-of-hearing users aren't excluded (`[[SOC-021]]`, core
  `[[MEDIA-002]]`).
- **No autoplay audio, ever** (core `[[MEDIA-004]]`); see below for video.

### Motion & autoplay

- **Reduce-motion is a hard requirement.** Autoplaying feed video MUST be muted,
  pausable, and disabled (or reduced to a static frame) under the OS reduce-motion or
  data-saver setting (`[[SOC-021]]`, core `[[MOT-010]]`). Reaction bursts and typing
  animations also honor reduce-motion (`[[SOC-011]]`, `[[SOC-008]]`).
- **Vestibular safety.** Endless auto-advancing motion (stories, autoplay reels) can
  trigger vestibular disorders — always provide pause and a static path.

### Labels, roles, targets & contrast

- **Every interactive glyph has a label + role + state.** Like, react, reply, more,
  send — an emoji or icon alone is not an accessible name (core `[[A11Y-007]]`); the
  liked state is exposed as selected (`[[SOC-011]]`).
- **Status and unread are not color-only.** Message status and unread indicators pair
  color with text/icon/shape and pass a grayscale review (`[[SOC-003]]`, `[[SOC-009]]`,
  core `[[A11Y-014]]`).
- **Targets and contrast.** Reaction/send/overflow controls meet ≥44pt/48dp
  (core `[[A11Y-005]]`) and text/icon contrast meets 4.5:1 / 3:1 in light and dark
  (core `[[A11Y-002]]`).

---

## Rules

### SOC-020 — Announce new-content / count updates via a live region
- **Rule:** Dynamic updates that matter to the user — a new incoming message, "X is typing," a like/reaction count change on the focused item, or "new posts available" — MUST be announced to assistive tech via an appropriately-polite live region. Rapid updates MUST be throttled/batched to avoid flooding, and announcements MUST use polite (not assertive) delivery unless genuinely urgent.
- **Why:** Screen-reader users otherwise never learn that a message arrived or a count changed; but unthrottled or assertive announcements make the app unusable, so politeness and batching are as important as the announcement itself.
- **Platforms:** all (live-region APIs are platform-specific)
- **Severity:** warning
- **Check:** With VoiceOver/TalkBack on, a new message, typing indicator, and "new posts" announce via a live region; rapid count/message updates are batched rather than spamming; delivery is polite.
- **See also:** [[SOC-003]], [[SOC-008]], [[SOC-009]], [[A11Y-011]], [[A11Y-007]]

### SOC-021 — Media alt text + captions; reduce-motion for autoplaying feed video
- **Rule:** Images MUST support alt text (author-provided with a sensible fallback) exposed to assistive tech; video and audio MUST offer captions or transcripts; and autoplaying feed video MUST be muted, pausable, and disabled (or reduced to a static frame) under the OS reduce-motion or data-saver setting. No media may autoplay audio.
- **Why:** Alt text and captions are baseline access for blind and deaf/hard-of-hearing users; autoplaying motion harms vestibular-sensitive users and burns data — reduce-motion is a hard requirement, not a nicety.
- **Platforms:** all
- **Severity:** error
- **Check:** Images expose alt text; video/audio has captions or a transcript; feed autoplay is muted, pausable, and stops (or becomes a static frame) under reduce-motion/data-saver; no audio autoplay.
- **See also:** [[SOC-010]], [[SOC-011]], [[MEDIA-002]], [[MEDIA-004]], [[MOT-010]], [[A11Y-007]]

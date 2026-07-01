# Social / Messaging — Industry Pack

> **Tier-3 industry pack.** Read this when the app's core job is people talking to
> people or broadcasting to an audience: chat/DM apps, group messaging, social
> feeds, comment threads, communities/forums, creator platforms, and dating.
> It layers **domain-specific** rules on top of the core corpus (`rules/`); it never
> restates core rules — it references them by ID (`[[CHAT-001]]`).

## When to use this pack

Activate when the screen or flow involves any of:

- **Real-time messaging** — 1:1 DMs, group chat, threads, message requests.
- **Social feeds** — timelines, stories, discovery, infinite scroll.
- **User-generated content** — posts, comments, reactions, media uploads.
- **Social graph actions** — follow/unfollow, friend requests, block/mute.
- **Engagement surfaces** — likes/reactions, notifications, unread badges.
- **Safety-critical interactions** — reporting, blocking, moderation, minor safety.

If the app only *has* a chat feature bolted onto another domain (e.g. a support
inbox inside a banking app), pull the `[[CHAT-*]]` family from core and use that
domain's pack for everything else. Reach for this pack when the product's core job
**is** the conversation, the feed, or the community.

## The 5 most load-bearing patterns

These five carry the most weight in social/messaging UX. Get them right first.

1. **Optimistic everything, with honest rollback** — likes, reactions, comments,
   posts, and chat sends render instantly and reconcile against the server; a
   failure rolls the UI back visibly and offers retry, never silently drops or
   silently keeps a failed action. → `[[SOC-002]]`, `[[SOC-003]]`, `[[SOC-007]]`,
   core `[[OFF-002]]`, `[[CHAT-001]]`.
2. **Chat that survives the keyboard** — the composer and newest message stay
   visible with the keyboard open, safe-area insets are respected, and scroll-to-
   latest never yanks a user out of history they're reading. → `[[SOC-004]]`,
   `[[SOC-012]]`, core `[[CHAT-003]]`, `[[FRM-005]]`.
3. **A feed that respects the reader** — virtualized infinite scroll with skeletons,
   pull-to-refresh, distinct end/empty/error states, and scroll-position
   preservation so nobody loses their place. → `[[SOC-001]]`, `[[SOC-006]]`,
   core `[[LST-001]]`, `[[LST-002]]`, `[[LST-003]]`.
4. **Safety in two taps** — report, block, and mute reachable from any piece of
   content, taking effect immediately, with confirmation and undo. → `[[SOC-013]]`,
   `[[SOC-014]]`, `[[SOC-017]]`, core `[[DLG-005]]`, `[[BDG-001]]`.
5. **Permission and notifications earned, not grabbed** — prime in-context before
   the one-shot OS prompt, keep notification copy honest and value-first, and
   deep-link every push into its exact context. → `[[SOC-005]]`, `[[SOC-019]]`,
   core `[[NOTIF-001]]`, `[[NOTIF-003]]`, `[[PERM-001]]`.

## Domain rules in this pack (SOC-\*\*\*)

| ID | Title | File | Severity |
|---|---|---|---|
| [[SOC-001]] | Feed: infinite scroll + pull-to-refresh + skeletons | patterns.md | warning |
| [[SOC-002]] | Optimistic like/post/comment with visible rollback | patterns.md | error |
| [[SOC-003]] | Chat: optimistic send with status ticks | patterns.md | error |
| [[SOC-004]] | Chat keyboard avoidance + safe-area + scroll-to-latest | patterns.md | error |
| [[SOC-005]] | Notification priming before the OS permission prompt | patterns.md | warning |
| [[SOC-006]] | Feed position preservation on refresh/return | patterns.md | warning |
| [[SOC-007]] | Message bubble: status, timestamp, tap-to-retry | components.md | error |
| [[SOC-008]] | Typing & read receipts (with a privacy setting) | components.md | warning |
| [[SOC-009]] | Unread indicators: badges/dividers, non-color-only | components.md | warning |
| [[SOC-010]] | Media attachments: thumbnails, alt text, no autoplay audio | components.md | warning |
| [[SOC-011]] | Like/reaction micro-interaction (bouncy, haptic, reduce-motion) | components.md | suggestion |
| [[SOC-012]] | Composer: attach, send, character/limit affordances | components.md | warning |
| [[SOC-013]] | Report/block/mute reachable in ≤2 taps | trust-and-safety.md | error |
| [[SOC-014]] | Block/mute: confirmation, immediate effect, undo | trust-and-safety.md | error |
| [[SOC-015]] | Content moderation affordances (blur/hide, "show anyway") | trust-and-safety.md | warning |
| [[SOC-016]] | Safety-by-default for minors / DMs from strangers | trust-and-safety.md | warning |
| [[SOC-017]] | Report flow: reason selection, confirmation, no reporter blame | trust-and-safety.md | warning |
| [[SOC-018]] | Empathetic, non-judgmental safety & moderation copy | copy-and-tone.md | warning |
| [[SOC-019]] | Notification & priming copy (value-first, honest) | copy-and-tone.md | warning |
| [[SOC-020]] | New-content / like-count updates announced via live region | accessibility.md | warning |
| [[SOC-021]] | Media alt text + captions; reduce-motion for autoplaying video | accessibility.md | error |
| [[SOC-022]] | No engagement dark patterns / infinite scroll without controls | pitfalls.md | warning |

## Table of contents

- [`patterns.md`](./patterns.md) — feed & infinite scroll, optimistic actions, chat send lifecycle, keyboard handling, notification priming, position preservation.
- [`components.md`](./components.md) — message bubble, typing/read receipts, unread indicators, media attachments, reaction micro-interaction, composer.
- [`trust-and-safety.md`](./trust-and-safety.md) — report/block/mute, moderation affordances, minor safety, report flow.
- [`copy-and-tone.md`](./copy-and-tone.md) — voice, safety/moderation microcopy, notification & priming copy, do/don't tables.
- [`accessibility.md`](./accessibility.md) — live-region announcements, media alt text & captions, reduce-motion for autoplay.
- [`pitfalls.md`](./pitfalls.md) — the common social/messaging UX mistakes and how to avoid them.

## Core rules this pack leans on

`[[CHAT-001]]` (optimistic send + status), `[[CHAT-002]]` (typing/read receipts),
`[[CHAT-003]]` (keyboard + safe-area), `[[OFF-002]]` (optimistic UI + queue +
visible rollback), `[[LST-001]]`/`[[LST-002]]`/`[[LST-003]]` (virtualize / skeleton
/ pull-to-refresh), `[[NOTIF-001]]`/`[[NOTIF-003]]` (prime before request /
deep-link), `[[PERM-001]]`/`[[PERM-003]]` (just-in-time / handle denied),
`[[BDG-001]]`/`[[BDG-005]]` (snackbar + Undo / badge accuracy), `[[MEDIA-002]]`/
`[[MEDIA-004]]` (captions / no autoplay audio), `[[MIC-002]]`/`[[MIC-004]]`/
`[[MOT-010]]` (press scale / like bounce / reduce-motion), `[[A11Y-011]]`
(live-region announce), `[[A11Y-014]]` (no color-only meaning), `[[DLG-005]]`
(explicit destructive confirm).

# Social / Messaging — Copy & Tone

> Voice, microcopy, and notification wording for social and messaging apps. Social
> copy is casual and warm most of the time — but at safety, moderation, and
> permission moments it must become **calm, plain, honest, and non-judgmental**.
> Cross-references use `[[ID]]`; core rules are referenced, never restated.

## Voice principles

- **Human and warm by default.** Everyday copy (empty states, composer hints, reaction
  tooltips) can be friendly and light — this is a social product, not a bank.
- **Calm and plain at safety moments.** Reporting, blocking, content warnings, and
  enforcement notices drop the playfulness: describe what happened and the options in
  plain language (`[[SOC-018]]`).
- **Never blame or shame the user.** Not the person filing a report, not the person on
  the receiving end of moderation. State facts and next steps, not judgments
  (`[[SOC-018]]`).
- **Honest about attention.** Notification and priming copy leads with real value and
  never manipulates — no fake "someone," no guilt, no manufactured urgency
  (`[[SOC-019]]`, see also `[[SOC-022]]`).

## Safety & moderation microcopy

| Situation | Do | Don't |
|---|---|---|
| Report submitted | "Thanks — we've received your report and will review it." | "Report sent." (no acknowledgment of what's next) |
| Choosing a report reason | "Why are you reporting this? (Harassment · Spam · Self-harm · …)" | "Report this content?" (no categories) |
| Block confirmation | "Block @sam? They won't be able to message or find you." | "Are you sure?" (no consequence stated) |
| After blocking | "You blocked @sam. Undo" | silent, no undo |
| Sensitive content interstitial | "This photo may show sensitive content. Show anyway?" | auto-reveal, or "Warning!!!" |
| Enforcement notice | "We removed this post because it broke our rules on harassment. You can appeal." | "You violated our policies." (blame, no appeal) |
| Mute | "Muted @sam. You won't see their posts. They won't be notified." | "Done." |

## Notification & priming microcopy

| Situation | Do | Don't |
|---|---|---|
| Priming screen | "Turn on notifications to know when a friend replies." + Allow / Not now | fire the OS prompt cold on launch |
| Priming decline button | "Not now" | "No, I don't want to talk to my friends" (guilt) |
| Message push | "Jordan sent you a message" → opens the thread | "You have a new notification" (vague, no deep-link) |
| Re-engagement push | "You have 3 unread messages" (true count) | "Someone is waiting for you 👀" (fake/bait) |
| Permission denied later | "Notifications are off. Turn them on in Settings." | re-prompt repeatedly |

- **Never fake social proof.** Don't send "Someone liked your post" when nobody did, or
  inflate counts to bait a tap (`[[SOC-019]]`, `[[SOC-022]]`).
- **Deep-link every push** to its exact context so the copy's promise is kept (core
  `[[NOTIF-003]]`).

## Everyday microcopy

- **Empty states invite action:** "No messages yet — say hi 👋" beats a blank pane
  (core `[[STATE-001]]`).
- **Failure copy is recoverable:** "Couldn't send. Tap to retry." not "Error"
  (`[[SOC-003]]`, `[[SOC-007]]`).
- **Character limits are shown, not sprung:** "23 left" as the user nears the cap, not a
  silent block (`[[SOC-012]]`).
- **Accessible labels are literal:** the like button reads "Like, button" / "Liked,
  button, selected," not just an emoji (`[[SOC-011]]`, core `[[A11Y-007]]`).

---

## Rules

### SOC-018 — Empathetic, non-judgmental safety & moderation copy
- **Rule:** Safety, moderation, and enforcement copy — reporting, blocking, content warnings, restrictions, takedowns — MUST be calm, plain, and non-judgmental: describe what happened and the available options, never blame or shame the user, and avoid alarmist or euphemistic wording. Enforcement notices MUST state the reason and, where one exists, the appeal path.
- **Why:** Safety moments are high-stress; blaming or vague copy discourages legitimate reporting and escalates conflict, while clear, empathetic copy increases trust and correct use of safety tools.
- **Platforms:** all
- **Severity:** warning
- **Check:** Report/block/warning strings are non-blaming, plain, and give a next step; enforcement notices state a reason and appeal path where applicable; no alarmist or shaming wording.
- **See also:** [[SOC-015]], [[SOC-017]], [[SOC-019]], [[A11Y-011]]

### SOC-019 — Notification & priming copy: value-first and honest
- **Rule:** Notification priming and permission copy MUST lead with concrete user value, be honest about what will be sent, and MUST NOT use guilt, fake urgency, or misleading button labels. Notification content itself MUST be truthful — no fake "someone" bait, no inflated counts — and MUST deep-link to the exact context it references.
- **Why:** Deceptive or spammy notification copy trains users to disable notifications and violates store policy; honest, value-first framing earns opt-in and long-term retention.
- **Platforms:** all
- **Severity:** warning
- **Check:** Priming copy states specific value and what's sent; decline buttons are neutral (no guilt); notification text is truthful with accurate counts and deep-links to context per [[NOTIF-003]].
- **See also:** [[SOC-005]], [[SOC-022]], [[NOTIF-001]], [[NOTIF-003]], [[PERM-001]]

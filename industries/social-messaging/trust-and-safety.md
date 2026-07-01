# Social / Messaging — Trust & Safety UX

> Reporting, blocking, muting, content moderation, and safe-by-default behavior for
> minors and unsolicited contact. In social apps these are not optional extras —
> they are load-bearing product surfaces and a hard requirement of both app stores.
> Cross-references use `[[ID]]`; core rules are referenced, never restated.

## Table of contents

1. [Reachability of safety controls](#1-reachability-of-safety-controls)
2. [Block & mute](#2-block--mute)
3. [Content moderation affordances](#3-content-moderation-affordances)
4. [Safety by default (minors & strangers)](#4-safety-by-default-minors--strangers)
5. [The report flow](#5-the-report-flow)
6. [Rules](#rules)

---

## 1. Reachability of safety controls

Every piece of user-generated content is a potential vector for harm; the response
must always be within reach.

- **Two taps, maximum.** From any post, comment, message, profile, or media item, a
  user reaches **report**, **block**, and **mute** within two taps — typically an
  overflow (⋯) menu → action (`[[SOC-013]]`).
- **Visible, not gesture-only.** Safety actions have a discoverable affordance; they
  are never hidden behind a long-press with no visible entry point (core `[[GES-001]]`).
- **Consistent placement.** The same ⋯ menu appears in the same place across content
  types, so the safety path is learnable and reflexive under stress.

Store policy (Apple 1.2, Google UGC) treats missing or buried reporting/blocking on a
UGC app as a rejection/removal reason — this is a `[[SOC-013]]` **error**, not a nicety.

## 2. Block & mute

Block and mute serve different needs and must behave differently, but both must be
immediate and reversible.

- **Immediate effect.** Blocking hides the blocked party's content and interactions
  right away, without an app restart; muting silences them for the actor while
  remaining invisible to the muted party (`[[SOC-014]]`).
- **Confirm the consequential ones.** A block that severs an existing connection or
  deletes a conversation confirms per platform norms (core `[[DLG-005]]`); a mute can
  be lighter-weight.
- **Undo and manage.** A snackbar with **Undo** covers accidental taps (core
  `[[BDG-001]]`), and a Settings screen lists blocked and muted accounts so users are
  never trapped by a past decision (`[[SOC-014]]`).

## 3. Content moderation affordances

Users must be protected from unexpected sensitive content and given consent over what
they see.

- **Blur by default, reveal by choice.** Flagged or potentially sensitive media/text is
  blurred or hidden behind an interstitial that states *why*, with an explicit,
  per-item "Show anyway" (`[[SOC-015]]`). The reveal is a deliberate tap — never
  triggered by hover or scroll.
- **Respect the always-blur setting.** If a user opts into "always hide sensitive
  content," honor it everywhere; don't re-expose after one reveal.
- **Empathetic labels.** Interstitial copy is plain and non-sensational
  (`[[SOC-018]]`).

## 4. Safety by default (minors & strangers)

The safest configuration must be the default, because most users never open settings.

- **Minor-safe defaults.** Accounts identified as minors (and, by default, new
  accounts) ship with stranger DMs restricted or filtered, discoverability limited, and
  sensitive-content filtering on (`[[SOC-016]]`). This aligns with age-appropriate
  design expectations and reduces grooming/harassment exposure.
- **Stranger DMs arrive as requests.** A message from a non-connection lands in a
  request/inbox state with inline block/report before the full thread opens
  (`[[SOC-016]]`, `[[SOC-013]]`), so the recipient consents before engaging.
- **Least-permission by default.** Contact-sync, precise location, and discoverability
  are opt-in with value-first priming (core `[[PERM-001]]`), never on by default.

## 5. The report flow

A report the user can't complete — or feels blamed for filing — is a report you never
receive.

- **Pick a reason.** Offer clear categories (harassment, spam, self-harm, impersonation,
  etc.) so moderation can triage (`[[SOC-017]]`).
- **Confirm and acknowledge.** A confirm step, then a "Thanks — we've received your
  report and will review it" acknowledgment that sets honest expectations
  (`[[SOC-017]]`).
- **Never blame the reporter.** Copy is supportive, not discouraging (`[[SOC-018]]`).
- **Offer block/mute inline.** Let the reporter also block or mute in the same flow so
  they get immediate relief while review is pending (`[[SOC-017]]`, `[[SOC-014]]`).

---

## Rules

### SOC-013 — Report / block / mute reachable in ≤2 taps from any content
- **Rule:** From any piece of user-generated content — post, comment, message, profile, or media — a user MUST be able to reach report, block, and mute controls within two taps via a discoverable, visible affordance (e.g. an overflow menu). These controls MUST NOT be gesture-only or hidden with no visible entry point.
- **Why:** App-store policy (Apple 1.2, Google UGC) and basic user safety require accessible reporting/blocking of UGC; burying safety tools increases harm exposure and is a common cause of app rejection or removal.
- **Platforms:** all
- **Severity:** error
- **Check:** From a post, comment, message, and profile, report + block + mute are each reachable in ≤2 taps through a visible affordance (not gesture-only); placement is consistent across content types.
- **See also:** [[SOC-014]], [[SOC-017]], [[GES-001]], [[PROF-002]]

### SOC-014 — Block / mute: confirmation, immediate effect, undo
- **Rule:** Blocking or muting MUST take effect immediately (content and interactions hidden without an app restart), MUST confirm consequential/destructive blocks per platform norms, and MUST provide a path to undo (e.g. snackbar Undo) and to manage blocked/muted lists in Settings. Mute is silent to the other party; block behavior is disclosed to the actor.
- **Why:** A block that doesn't immediately hide the abuser, or that can't be reversed or reviewed, fails the user's safety need, traps them in a past decision, and increases support burden.
- **Platforms:** all
- **Severity:** error
- **Check:** Blocking/muting hides content instantly; a blocked/muted-list management screen exists with undo; a consequential block shows an explicit confirm per [[DLG-005]]; an accidental block is recoverable via Undo.
- **See also:** [[SOC-013]], [[SOC-017]], [[DLG-005]], [[BDG-001]]

### SOC-015 — Content moderation affordances (blur/hide, "show anyway")
- **Rule:** Potentially sensitive or flagged media/text MUST be hidden or blurred behind an interstitial by default, labeled with why, with an explicit per-item "Show anyway" opt-in. The reveal MUST require a deliberate tap (not hover- or scroll-triggered), and an "always hide sensitive content" setting MUST be honored everywhere.
- **Why:** Unexpected graphic or sensitive content harms users and violates platform policy; a blur plus explicit reveal gives consent and protects users who don't want to see it.
- **Platforms:** all
- **Severity:** warning
- **Check:** Flagged content renders blurred with a reason label; reveal requires an explicit tap; the sensitive-content setting is respected across surfaces and after a prior reveal.
- **See also:** [[SOC-010]], [[SOC-016]], [[SOC-018]], [[SOC-021]], [[DLG-005]]

### SOC-016 — Safety-by-default for minors and DMs from strangers
- **Rule:** Accounts identified as minors — and, by default, new accounts — MUST ship safer defaults: DMs from non-connections restricted or filtered, discoverability limited, and sensitive-content filtering on. A DM from a non-connection MUST arrive as a request/inbox state with inline block/report before full thread access. Contact-sync, precise location, and discoverability MUST be opt-in with value-first priming, not on by default.
- **Why:** Unsolicited DMs to minors are a major safety and regulatory (age-appropriate design) risk; safe defaults reduce grooming and harassment exposure without relying on users to discover settings.
- **Platforms:** all
- **Severity:** warning
- **Check:** New/minor accounts default to restricted stranger DMs + content filtering + limited discoverability; stranger DMs arrive as requests with inline block/report; sensitive permissions are opt-in.
- **See also:** [[SOC-013]], [[SOC-015]], [[SOC-017]], [[PERM-001]]

### SOC-017 — Report flow: reason selection, confirmation, no reporter blame
- **Rule:** The report flow MUST let the user select a reason category, confirm submission, and receive an acknowledgment that the report was received and what happens next — without blaming or discouraging the reporter — and MUST offer to block/mute the reported party inline within the same flow.
- **Why:** A vague, unacknowledged, or guilt-inducing report flow suppresses legitimate reports; clear categories and honest acknowledgment build trust in moderation and give the reporter immediate relief.
- **Platforms:** all
- **Severity:** warning
- **Check:** Report offers reason categories, a confirm step, and a "received" acknowledgment; copy is non-blaming; block/mute is offered inline in the same flow.
- **See also:** [[SOC-013]], [[SOC-014]], [[SOC-018]], [[DLG-005]]

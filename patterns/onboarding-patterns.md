# Onboarding Patterns

> Purpose: Get a first-time user to value fast, then ask for permissions and account creation only when the value is visible — value-first, skippable, progressive. Bad onboarding is a wall of slides + a permission-request barrage on launch; good onboarding earns each ask.

## Contents
- [When to use](#when-to-use)
- [Principles](#principles)
- [Flow shape](#flow-shape)
- [Value-first screens](#value-first-screens)
- [Progressive permission priming](#progressive-permission-priming)
- [Account creation timing](#account-creation-timing)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states](#the-7-states)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

First-run experience for a new install, a major-version re-onboarding, or introducing a new feature area. Pairs with [form-flows.md](form-flows.md) (any sign-up form) and the permission rules ([[PERM-002]]).

## Principles

1. **Value before ask** — show what the app does / do something useful before requesting permissions or an account ([[ONB-001]]).
2. **Skippable** — every onboarding step can be skipped or deferred; never trap the user before they've seen value ([[ONB-002]]).
3. **Progressive** — request one permission at a time, at the moment it's needed, with context ([[ONB-003]], [[PERM-001]]).
4. **Short** — 3–4 screens maximum for intro; respect the user's time ([[ONB-005]]).
5. **Honest** — no dark patterns, no pre-checked marketing consent, no disguised "Skip."

## Flow shape

```
Launch
 └─ (Optional) 1–3 value screens: what/why, benefit-led, skippable   [[ONB-001]] [[ONB-005]]
     └─ Let the user DO something (browse, sample, guest mode)        [[AUTH-010]]
         └─ At the moment a feature needs it:
             ├─ PRIME the permission (explain value) → then request   [[PERM-002]] [[PERM-001]]
             └─ Prompt account creation when it unlocks real value    (save, sync, checkout)
```

Prefer **letting the user in first** (guest / explore mode) over a hard login wall, unless the app category legitimately requires an account up front ([[AUTH-010]]).

## Value-first screens

- Each intro screen leads with a **benefit**, not a feature list; one idea per screen ([[ONB-001]]).
- Show **progress** (dots / step N of M) so length is knowable ([[ONB-004]], [[FRM-012]]).
- Persistent, obvious **Skip**; a clear primary **Continue / Get started** ([[ONB-002]], [[BTN-001]]).
- Real, localized copy — no lorem ipsum, no untranslatable string concatenation ([[L10N-002]], [[L10N-003]]).
- Don't gate value behind sign-in on these screens.

## Progressive permission priming

Never fire the OS permission dialog cold. **Prime, then request** ([[PERM-002]], [[PERM-001]]):

1. **Context screen (your UI):** explain *why* this permission helps the user, with an honest benefit and a "Not now" option. This costs nothing and doesn't burn the one-shot OS prompt.
2. **OS request:** only after the user opts in on your priming screen, trigger the system dialog — at the point of use (tapping "Add photo" → photos; "Find nearby" → location) ([[PERM-001]]).
3. **Handle denial gracefully:** if denied, the feature degrades, not the app; offer a Settings deep-link to re-enable and a manual fallback ([[PERM-003]], [[PERM-004]], [[STATE-010]]).
4. **Never block the whole app** on an optional permission ([[PERM-005]]).
5. **Notifications specifically:** prime with the value ("Get notified when your order ships") before the system prompt; set up channels/categories so users can tune later ([[NOTIF-001]], [[NOTIF-002]]).

Order permissions by when they're needed; don't stack multiple system prompts back-to-back on launch.

## Account creation timing

- Delay the ask until the user has felt value or hits a gate that genuinely needs identity (save, sync across devices, purchase) ([[AUTH-010]]).
- Offer low-friction methods (passkeys, platform SSO, email link) and paste-friendly, autofill-ready fields ([[AUTH-001]], [[AUTH-005]], [[A11Y-015]]).
- Make the value of creating an account explicit at the moment of asking.
- Preserve any work the guest did and migrate it into the new account on sign-up.

## Thumb-zone layout

| Zone | Onboarding role |
|---|---|
| Bottom arc | Primary CTA (Continue / Get started / Allow-priming Yes) as a full-width, thumb-reachable button ([[BTN-007]]) |
| Middle | Illustration / value copy / permission rationale |
| Top | Skip (still reachable but subordinate), progress dots |

Keep Skip discoverable but visually secondary; never disguise it or make it a tiny mis-tap target ([[BTN-006]], [[A11Y-003]]).

## The 7 states

Onboarding is lighter on data states but must still handle them:

| State | Onboarding behavior |
|---|---|
| Ideal | Screens advance; priming → grant flows work |
| Empty | N/A for slides; for a "set up your first X" step, show a helpful empty with a CTA ([[STATE-002]]) |
| Loading | Any setup call (create account, fetch starter content) shows progress; disable double-submit ([[BTN-003]], [[STATE-005]]) |
| Error | Sign-up / setup failure → clear, retryable error preserving entered data ([[STATE-007]], [[FRM-009]]) |
| Offline | Let the user proceed through value screens offline; queue account creation or explain it needs connection ([[STATE-008]], [[OFF-001]]) |
| Success | Confirm setup and drop the user into the actual app (their goal), not another upsell ([[STATE-009]]) |
| Permission-denied | The core outcome of priming — handled with degrade + Settings link ([[STATE-010]], [[PERM-003]]) |

## Accessibility

- Slides are reachable and readable by screen readers in order; the progress indicator announces position ([[A11Y-008]], [[A11Y-017]]).
- Skip and Continue are labeled buttons with adequate targets; focus lands logically on each new screen ([[A11Y-004]], [[A11Y-003]]).
- Priming copy is real text (not baked into an image) so it scales with Dynamic Type and is translatable ([[A11Y-010]], [[TYP-004]], [[L10N-003]]).
- Auto-advancing carousels are discouraged; if used, they pause on interaction and respect reduce-motion ([[A11Y-011]], [[MOT-004]]).
- Don't rely on swipe-only to advance — provide visible Next/Back ([[A11Y-016]], [[GES-005]]).

## Motion

- Slide transitions: horizontal shared-axis, small tier ≤300ms; reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Illustration entrances: subtle, non-blocking; never gate the CTA behind a long animation ([[MOT-005]]).
- Success moment: a brief, delightful confirmation is fine before handing off to the app ([[MIC-002]]).
- Progress dots animate the active state ≤200ms ([[MIC-001]]).

## Applied rules

| Intent | Rule |
|---|---|
| Value-first | [[ONB-001]] |
| Skippable | [[ONB-002]] |
| Progressive priming | [[ONB-003]] |
| Progress indicator | [[ONB-004]] |
| Keep it short (≤3–4) | [[ONB-005]] |
| Just-in-time permission | [[PERM-001]] |
| Value-first priming | [[PERM-002]] |
| Denied → Settings + fallback | [[PERM-003]], [[PERM-004]] |
| Don't block app on optional perm | [[PERM-005]] |
| Notification priming + channels | [[NOTIF-001]], [[NOTIF-002]] |
| Guest / continue-without-account | [[AUTH-010]] |
| Accessible auth on sign-up | [[AUTH-001]], [[A11Y-015]] |
| Real, localizable copy | [[L10N-002]], [[L10N-003]] |

## Anti-patterns

- ❌ Requesting notifications/location/contacts on first launch, cold, before any value ([[PERM-002]]).
- ❌ Stacking several OS permission dialogs back-to-back at start.
- ❌ A 7-slide intro carousel with no Skip ([[ONB-002]], [[ONB-005]]).
- ❌ Hard login wall before the user sees anything (unless the category requires it) ([[AUTH-010]]).
- ❌ Priming copy baked into an image (unreadable, untranslatable, doesn't scale) ([[A11Y-010]], [[L10N-003]]).
- ❌ Blocking the whole app because an *optional* permission was denied ([[PERM-005]]).
- ❌ Ending onboarding on an upsell instead of the user's actual goal.

## Acceptance checklist

- [ ] Shows value before any permission/account ask; ≤3–4 intro screens ([[ONB-001]], [[ONB-005]]).
- [ ] Every step skippable/deferrable; Skip is visible but subordinate ([[ONB-002]]).
- [ ] Progress indicator present and announced ([[ONB-004]], [[A11Y-017]]).
- [ ] Permissions primed in-app (with "Not now"), requested just-in-time, one at a time ([[PERM-001]], [[PERM-002]]).
- [ ] Denial degrades the feature only; Settings deep-link + manual fallback provided ([[PERM-003]], [[PERM-005]]).
- [ ] Notification prompt primed with value; channels configured ([[NOTIF-001]], [[NOTIF-002]]).
- [ ] Guest/explore path or justified account requirement; guest work migrates on sign-up ([[AUTH-010]]).
- [ ] Copy is real text, translatable, scales to 200%; Next/Back not swipe-only ([[L10N-003]], [[A11Y-010]], [[A11Y-016]]).
- [ ] Ends by dropping the user into their goal, with setup states (loading/error/offline) handled ([[STATE-001]]).
- [ ] Reduce-motion fallback for slide transitions ([[MOT-004]]).

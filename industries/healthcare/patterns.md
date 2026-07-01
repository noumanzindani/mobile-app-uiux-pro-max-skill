# Healthcare — Screen Patterns

> Domain screen recipes for health apps. These flows must be calm, legible, and
> error-tolerant because users may be older, impaired, anxious, or in crisis, and
> mistakes can cause physical harm. Cross-references use `[[ID]]`.

## Table of contents

1. [Health dashboard](#1-health-dashboard)
2. [Medication & dosage flow (error-intolerant)](#2-medication--dosage-flow-error-intolerant)
3. [Appointments & reminders](#3-appointments--reminders)
4. [Records & offline reliability](#4-records--offline-reliability)
5. [Calm motion & pacing](#5-calm-motion--pacing)
6. [Rules](#rules)

---

## 1. Health dashboard

- **Legible first.** Large default type, high contrast, generous spacing; everything
  scales to the largest font setting without clipping (`[[MED-001]]`).
- **Prioritize the actionable.** Today's medications, next appointment, and any
  action needed (a due dose, an unread result) surface first — not a wall of charts.
- **Vitals read without color.** Any in-range/out-of-range status uses text + icon +
  position, not red/green alone (`[[MED-006]]`, `[[MED-014]]`).
- **Emergency info is always reachable** — allergies, conditions, emergency contacts
  accessible in one tap, even offline (`[[MED-008]]`, `[[MED-005]]`).
- **Calm visuals.** Subdued palette; no alarming pulsing/flashing; reassuring, not
  gamified-anxious (`[[MED-002]]`).

## 2. Medication & dosage flow (error-intolerant)

This is the highest-stakes flow in the pack. A wrong dose can harm.

1. **Select medication** — show name (generic + brand), strength, and a photo/shape
   cue where available to prevent look-alike/sound-alike errors.
2. **Enter dose** — units are explicit and impossible to confuse (mg vs mL vs
   tablets); the field shows the unit inline and validates against sane ranges
   (`[[MED-011]]`, core `[[FRM-007]]`).
3. **Review** — a dedicated confirm screen restates **drug, dose, unit, route, and
   time** in plain language before saving/logging (`[[MED-003]]`, core `[[DLG-005]]`).
4. **Confirm & log** — record adherence with a clear success state; allow easy undo
   of a mistaken log (`[[MED-012]]`).

Interaction-warning surfaces (allergy/contraindication) must be prominent, plain, and
not dismissible-by-accident.

## 3. Appointments & reminders

- **Reminders are reliable and actionable** — prime notification permission with
  value first (core `[[PERM-001]]`), deep-link the reminder straight to the relevant
  action (take dose, join visit, confirm appointment) per core `[[NOTIF-004]]`.
- **Appointments** show date/time in the user's locale + timezone unambiguously,
  with add-to-calendar, reschedule, and join (for telehealth) paths.
- **Reminder tone is calm, not nagging** — supportive language, snooze without guilt
  (`[[MED-013]]`, `[[MED-007]]`).

## 4. Records & offline reliability

- **Critical records available offline** — current medications, allergies,
  conditions, and emergency info must be viewable without connectivity; you cannot
  assume signal in a clinic basement or an emergency (`[[MED-005]]`, core `[[OFF-002]]`).
- **Freshness is explicit** — show "as of <time>/last synced" so a user never acts on
  silently stale clinical data; writes queue and sync with visible status.
- **States are honest** — loading (skeleton), empty ("No results on file"), error
  (retry), and offline (last-synced) are all designed (core `[[STATE-001]]`).

## 5. Calm motion & pacing

- Motion is **subtle and slow-ish**; avoid bouncy, urgent, or attention-grabbing
  animation. No flashing/strobing (also a seizure risk).
- **Respect reduce-motion** everywhere; provide a static equivalent (`[[MED-016]]`,
  core `[[MOT-011]]`).
- Loading and transitions should reassure, not alarm — a calm skeleton over a
  spinning red alert (`[[MED-002]]`).

---

## Rules

### MED-002 — Keep motion and visuals calm and low-arousal
- **Rule:** Health-app motion MUST be subtle and unhurried (gentle fades/slides, no bouncy or urgent springs), MUST avoid alarming animation, flashing, or strobing, and MUST use a subdued, non-anxiety-inducing palette. Reserve high-salience treatment strictly for genuine, actionable clinical alerts.
- **Why:** Users are often anxious, in pain, cognitively impaired, or elderly; aggressive motion and alarm-red UI increase stress and can trigger vestibular or photosensitive reactions. Calm design improves comprehension and trust.
- **Platforms:** all
- **Severity:** warning
- **Check:** No flashing/strobe; motion durations/easing are gentle; alarm styling limited to real alerts; reduce-motion honored ([[MED-016]]).
- **See also:** [[MED-013]], [[MED-016]], [[MOT-011]]

### MED-003 — Make medication/dosage and other harm-capable flows error-intolerant
- **Rule:** Any action that could cause physical harm if wrong (recording/administering medication, dosage, allergy entry, care instructions) MUST route through a review-and-confirm step that restates the key facts (drug, dose, unit, route, time) in plain language before commit, MUST NOT rely on a single tap, and MUST make undo of a mis-log easy.
- **Why:** Medication errors are a leading cause of avoidable harm; a confirm+review guardrail with unambiguous units and easy undo prevents wrong-drug/wrong-dose mistakes.
- **Platforms:** all
- **Severity:** error
- **Check:** Harm-capable flows include a review screen restating drug/dose/unit/route/time; commit is not single-tap; an undo path exists.
- **See also:** [[MED-011]], [[MED-012]], [[DLG-005]], [[FRM-007]]

### MED-005 — Keep critical records available offline
- **Rule:** Current medications, allergies, active conditions, and emergency info MUST be viewable offline, with an explicit "last synced / as of <time>" freshness stamp. Writes queue and sync with visible status; the app must never present stale clinical data as live.
- **Why:** Care and emergencies happen without connectivity (clinic basements, rural areas, dead batteries at the ER). Silent staleness of clinical data can cause harm.
- **Platforms:** all
- **Severity:** error
- **Check:** Meds/allergies/conditions/emergency info render offline; a freshness timestamp is shown; queued writes surface sync status.
- **See also:** [[MED-008]], [[OFF-002]], [[STATE-001]]

### MED-007 — Use reliable, calm appointment & reminder patterns
- **Rule:** Appointment and medication reminders MUST prime notification permission with a value-first rationale, deep-link directly to the relevant action, present date/time unambiguously in the user's locale/timezone, and use supportive (not nagging or guilt-inducing) language with easy snooze/reschedule.
- **Why:** Adherence and attendance depend on trustworthy, actionable reminders; poor timing, ambiguous times, or nagging tone reduce engagement and increase anxiety.
- **Platforms:** all (notification APIs platform-specific)
- **Severity:** warning
- **Check:** Permission is primed before request; reminders deep-link to context; times show timezone; copy is supportive; snooze/reschedule present.
- **See also:** [[MED-002]], [[MED-012]], [[MED-013]], [[PERM-001]], [[NOTIF-004]]

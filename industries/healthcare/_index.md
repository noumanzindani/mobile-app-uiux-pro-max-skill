# Healthcare — Industry Pack

> **Tier-3 industry pack.** Read this when the app handles health data, care, or
> medical decisions: patient portals, telehealth, medication/adherence, symptom
> checkers, chronic-condition management, wearables/vitals, clinician tools, or
> health records. It layers **domain-specific** rules on top of the core corpus
> (`rules/`) and references core rules by ID (`[[A11Y-007]]`), never restating them.

## When to use this pack

Activate when the screen or flow involves any of:

- **Clinical data** — vitals, lab results, diagnoses, conditions, allergies, records.
- **Medication** — dosing, schedules, reminders, refills, adherence logging.
- **Care coordination** — appointments, reminders, messages with providers, referrals.
- **Symptoms & intake** — symptom entry, triage, questionnaires, consent forms.
- **Emergency context** — emergency info, allergies, critical alerts, quick access.
- **Sensitive identity** — PHI, consent, data-sharing, caregiver/proxy access.

Audience skews **older and more impaired** than average consumer apps, and errors
can cause physical harm — the bar for legibility, calm, and error-tolerance is higher
than anywhere else in this skill.

## The 5 most load-bearing patterns

1. **Legibility for everyone, at any text size** — large default type, generous
   spacing, and full support for the largest Dynamic Type / font-scale settings
   without truncation, because many users are older or low-vision. → `[[MED-001]]`,
   core `[[TYP-006]]`, `[[A11Y-007]]`.
2. **Error-intolerant clinical flows** — medication, dosage, and other harm-capable
   actions require confirm + review with unambiguous units, and never rely on a
   single tap. → `[[MED-003]]`, `[[MED-011]]`, core `[[DLG-005]]`.
3. **Calm, low-arousal experience** — subdued motion, no alarming animation or
   color, and reassuring pacing, because users may be anxious, in pain, or in crisis.
   → `[[MED-002]]`, `[[MED-013]]`, core `[[MOT-011]]`.
4. **Consent-first privacy (HIPAA-adjacent)** — clear, plain-language data-use
   disclosure and explicit consent gates before collecting or sharing health data.
   → `[[MED-004]]`, `[[MED-010]]`, `[[MED-015]]`.
5. **Reliable offline access & color-independent status** — key records (meds,
   allergies, emergency info) available offline; vitals/status never encoded by
   color alone. → `[[MED-005]]`, `[[MED-006]]`, `[[MED-008]]`, core `[[CHT-002]]`, `[[OFF-002]]`.

## Domain rules in this pack (MED-\*\*\*)

| ID | Title | File | Severity |
|---|---|---|---|
| [[MED-001]] | Legible at the largest Dynamic Type / font scale | accessibility.md | error |
| [[MED-002]] | Calm, low-arousal motion & visuals | patterns.md | warning |
| [[MED-003]] | Error-intolerant medication/dosage flows (confirm + review) | patterns.md | error |
| [[MED-004]] | Consent gates before collecting/sharing health data | trust-and-safety.md | error |
| [[MED-005]] | Critical records available offline | patterns.md | error |
| [[MED-006]] | Color-independent vitals & clinical status | accessibility.md | error |
| [[MED-007]] | Appointment & reminder patterns | patterns.md | warning |
| [[MED-008]] | Emergency-info quick access | components.md | error |
| [[MED-009]] | Accessible, forgiving symptom/intake forms | accessibility.md | warning |
| [[MED-010]] | Plain-language data-use disclosure | trust-and-safety.md | error |
| [[MED-011]] | Unambiguous dosage, units & frequency | components.md | error |
| [[MED-012]] | Medication reminders + adherence confirmation | components.md | warning |
| [[MED-013]] | Plain-language, non-alarming clinical copy | copy-and-tone.md | warning |
| [[MED-014]] | Vitals card (value + range + trend, non-color) | components.md | warning |
| [[MED-015]] | PHI screen privacy (masking, session, background) | trust-and-safety.md | warning |
| [[MED-016]] | Reduce-motion respected for all health animation | accessibility.md | error |

## Table of contents

- [`patterns.md`](./patterns.md) — health dashboard, medication flow, appointments/reminders, records + offline, calm motion.
- [`components.md`](./components.md) — vitals card, medication row, dosage input, emergency card, reminder/adherence, consent gate.
- [`trust-and-safety.md`](./trust-and-safety.md) — consent UX, data-use disclosure, PHI protection, HIPAA-adjacent norms.
- [`copy-and-tone.md`](./copy-and-tone.md) — plain-language, non-alarming voice, medical microcopy, error norms.
- [`accessibility.md`](./accessibility.md) — Dynamic Type, color-independent status, reduce-motion, forgiving forms.
- [`pitfalls.md`](./pitfalls.md) — common healthcare UX mistakes and fixes.

## Core rules this pack leans on

`[[A11Y-007]]` (contrast/target size), `[[TYP-006]]` (Dynamic Type scaling),
`[[MOT-011]]` (reduce-motion path), `[[CHT-002]]` (no color-only encoding),
`[[OFF-002]]` (offline queue + last-synced), `[[DLG-005]]` (explicit confirm),
`[[FRM-007]]` (inline validation), `[[PERM-001]]` (just-in-time permission priming),
`[[NOTIF-004]]` (deep-link to context), `[[STATE-001]]` (enumerate the 7 states).

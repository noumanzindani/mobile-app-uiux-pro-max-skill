# Healthcare — Copy & Tone

> Voice, microcopy, and error norms for health apps. Health copy must be **plain,
> calm, accurate, and non-alarming** — written for anxious people, older adults, and
> a wide range of health literacy, at a moment that may be frightening.

## Voice principles

- **Plain language, low reading level.** Aim for ~6th–8th grade readability. Prefer
  "high blood pressure" to "hypertension" on first use; define terms you must use.
  Short sentences. (`[[MED-013]]`)
- **Calm and reassuring, never alarming.** Avoid alarmist wording, ALL-CAPS, and
  scare tactics. Communicate seriousness with clarity, not fear (`[[MED-002]]`).
- **Accurate and honest about limits.** Never imply diagnosis or certainty the app
  can't provide. A symptom checker says clearly it is **not medical advice** and
  routes red-flag symptoms to emergency care.
- **Non-judgmental.** Missed a dose, gained weight, skipped a workout — copy is
  supportive, never shaming (`[[MED-012]]`).
- **Person-first, respectful.** "A person with diabetes," not "a diabetic." Inclusive,
  non-stigmatizing language across conditions, bodies, and identities.

## Microcopy norms

| Situation | Do | Don't |
|---|---|---|
| Missed dose reminder | "Time for your 8:00 PM dose. Tap to log it." | "You MISSED your medication!" |
| Out-of-range vital | "Your reading is higher than your target range." | red "DANGER" flash |
| Symptom checker intro | "This helps you decide what to do next. It's not a diagnosis." | "Find out what's wrong with you" |
| Emergency red flag | "These symptoms may be serious. Call emergency services now." + call button | soft "you might want to see a doctor" |
| Consent | "Share your records with Dr. Lee? You can undo this anytime." | pre-checked, no explanation |
| Log confirmation | "Logged. Nice work staying on track." | "Finally!" / streak-shaming |

- **Units and numbers are explicit** — always show the unit (mg, mmol/L, mmHg) and
  the target range in words (`[[MED-011]]`, `[[MED-014]]`).
- **Times are unambiguous** — locale + timezone; "8:00 PM today," not "20:00" if the
  audience won't parse it.

## Error & alert messaging

Health errors and alerts must balance calm with clarity:

1. **What happened / what we found** — plainly ("We couldn't save your reading" /
   "This reading is above your range").
2. **How serious, honestly** — don't over- or under-state; reserve urgent styling and
   language for genuinely urgent, actionable situations.
3. **What to do now** — a concrete next step (retry, call your provider, call
   emergency services), with the action reachable.

Never show a raw error code alone. Never use fear to drive engagement. For genuine
emergencies, make the emergency-call action immediate and obvious.

---

## Rules

### MED-013 — Write plain-language, calm, non-alarming clinical copy
- **Rule:** Health copy MUST use plain language at a low reading level, define unavoidable medical terms, avoid alarmist/shaming/ALL-CAPS tone, be honest about limits (not medical advice / not a diagnosis where applicable), use person-first respectful language, and reserve urgent wording and styling strictly for genuinely urgent, actionable situations — while making emergency actions immediate and obvious.
- **Why:** The audience spans low health literacy, older adults, and anxious or in-crisis users; alarmist or jargon-heavy copy causes fear, misunderstanding, and disengagement, while under-stating real emergencies is dangerous.
- **Platforms:** all
- **Severity:** warning
- **Check:** Readability ~6th–8th grade; terms defined; no shaming/alarmist tone; limitation disclaimers present where relevant; emergency actions prominent; units/times explicit.
- **See also:** [[MED-002]], [[MED-011]], [[MED-012]], [[MED-014]]

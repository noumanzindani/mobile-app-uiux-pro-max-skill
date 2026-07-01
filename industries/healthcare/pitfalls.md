# Healthcare — Common Pitfalls

> The healthcare-specific mistakes AI-generated and human-built health apps make most
> often, why they're harmful, and the rule that prevents each. In this domain,
> mistakes can cause physical harm — treat these as safety issues, not polish.

| # | Pitfall | Why it's harmful | Fix / rule |
|---|---------|------------------|-----------|
| 1 | **Small default type; breaks at large font sizes** | Older/low-vision users can't read doses, ranges, or instructions | Large default type; legible to 200%+ without clipping → [[MED-001]] |
| 2 | **One-tap dose logging / no review on meds** | Wrong-drug/wrong-dose errors; corrupted adherence data | Confirm + review restating drug/dose/unit/route/time; easy undo → [[MED-003]], [[MED-012]] |
| 3 | **Ambiguous units (mg vs mL vs mcg)** | Dangerous dosing errors, including thousand-fold mistakes | Explicit inline units; constrained pickers; range checks → [[MED-011]] |
| 4 | **Alarming red flashes / urgent animation everywhere** | Raises anxiety; vestibular/photosensitive risk; alarm fatigue | Calm low-arousal motion; reserve alarm for real alerts; reduce-motion → [[MED-002]], [[MED-016]] |
| 5 | **Color-only vitals status (red/green)** | Color-blind/low-vision users can't tell safe from dangerous | Text + icon + position; grayscale-safe; chart data fallback → [[MED-006]], [[MED-014]] |
| 6 | **Bundled / pre-checked / implied consent** | Legal risk (special-category data); trust violation | Granular, unbundled, revocable consent gate → [[MED-004]] |
| 7 | **Data-use buried in legalese** | No real informed consent; trust collapses when discovered | Plain-language disclosure at the decision point → [[MED-010]] |
| 8 | **Records/emergency info online-only** | Care happens without signal; emergencies can't wait | Critical records offline with freshness stamp → [[MED-005]] |
| 9 | **Emergency info buried behind login/load** | Seconds and an incapacitated user matter; access must be instant | One-tap, offline, no blocking login → [[MED-008]] |
| 10 | **Alarmist or shaming copy** ("You MISSED your meds!") | Fear and guilt reduce adherence and increase distress | Plain, calm, non-judgmental, honest-about-limits copy → [[MED-013]] |
| 11 | **Reduce-motion ignored; flashing content** | Vestibular reactions; seizure risk; violates WCAG | Honor reduce-motion; never strobe → [[MED-016]] |
| 12 | **Long, rigid, timed intake forms demanding precision** | Unwell users abandon or enter wrong data | Forgiving, resumable, imprecision-allowing forms → [[MED-009]] |
| 13 | **PHI visible in app-switcher / logs / screenshots** | Privacy breach with legal and personal fallout | Background masking; keep PHI out of logs/analytics → [[MED-015]] |
| 14 | **Symptom checker implies diagnosis; no emergency routing** | Users act on false certainty; red flags missed | State "not a diagnosis"; route red flags to emergency care → [[MED-013]] |
| 15 | **Wrong-patient actions in caregiver/proxy mode** | Care delivered against the wrong record | Show active patient context on every clinical action → [[MED-015]], [[MED-003]] |

## Quick self-audit

Before shipping any health screen, confirm:

- [ ] Readable at the largest font scale — no clipped doses, ranges, or instructions.
- [ ] Harm-capable actions (meds/dosage) have confirm + review and an undo.
- [ ] Units are explicit and unambiguous everywhere a dose appears.
- [ ] Motion is calm; reduce-motion honored; nothing flashes/strobes.
- [ ] Vitals/clinical status readable in grayscale; charts have a data fallback.
- [ ] Consent is granular, unbundled, revocable, and precedes collection/sharing.
- [ ] Data-use is disclosed in plain language at the decision point.
- [ ] Critical records + emergency info work offline; freshness is shown.
- [ ] Emergency info reachable in one tap, no blocking login.
- [ ] Copy is plain, calm, non-shaming, and honest about limits.
- [ ] PHI masked in app-switcher; kept out of logs/screenshots.
- [ ] Active patient context is unmistakable in proxy/caregiver mode.

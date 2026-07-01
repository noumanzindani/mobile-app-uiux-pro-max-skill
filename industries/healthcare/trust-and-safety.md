# Healthcare — Trust & Safety / Compliance UX

> Consent, data-use transparency, PHI protection, and the HIPAA-adjacent UX a health
> app must ship. Health data is among the most sensitive categories that exists;
> trust here is a prerequisite, not a feature.

> **Note:** This is UX guidance, not legal advice. HIPAA, GDPR (special-category
> data), and regional health-privacy laws impose specific obligations — involve
> counsel/compliance. These rules cover the *interface* norms that support compliance.

## Table of contents

1. [Consent-first collection & sharing](#1-consent-first-collection--sharing)
2. [Plain-language data-use disclosure](#2-plain-language-data-use-disclosure)
3. [PHI protection on the device](#3-phi-protection-on-the-device)
4. [Proxy / caregiver access](#4-proxy--caregiver-access)
5. [Trust signals](#5-trust-signals)
6. [Rules](#rules)

---

## 1. Consent-first collection & sharing

- **Consent gates precede collection or sharing** of health data — before syncing a
  wearable, before sharing records with a provider or third party, before any
  research/marketing use (`[[MED-004]]`).
- **Granular and unbundled** — separate consent for treatment, research, marketing,
  and third-party sharing; nothing pre-checked; declining a non-essential item never
  blocks core care.
- **Revocable** — the user can withdraw consent later from settings, and the app
  honors it.

## 2. Plain-language data-use disclosure

- Tell users, in plain language at the point of decision, **what data is collected,
  why, who sees it, and how long it's kept** — not only in a buried policy
  (`[[MED-010]]`).
- Prefer a layered disclosure: a short human summary + a link to full detail.
- Be explicit about anything surprising: cloud storage, third-party processors,
  de-identified research use, or data leaving the country.

## 3. PHI protection on the device

- **Background/app-switcher masking** and optional biometric lock for PHI surfaces;
  obscure health data in the OS recents snapshot (`[[MED-015]]`).
- Keep PHI out of logs, analytics, screenshots, and clipboards.
- Session handling appropriate to sensitivity (auto-lock on background for clinical
  data); provide an accessible unlock path.

## 4. Proxy / caregiver access

- Support caregiver/parent/guardian access explicitly, with clear labeling of *whose*
  record is being viewed to prevent wrong-patient actions.
- Make the active patient context unmistakable on every clinical action (ties to
  error-intolerance, `[[MED-003]]`).

## 5. Trust signals

- Show provider/institution verification and credentials for telehealth.
- Be honest about limitations — a symptom checker states it is **not a diagnosis** and
  routes to emergency services for red-flag symptoms (`[[MED-013]]`).
- No dark patterns around consent or data sharing; no manufactured urgency on health
  decisions.

---

## Rules

### MED-004 — Gate health-data collection and sharing behind explicit consent
- **Rule:** Before collecting, syncing, or sharing health data, the app MUST present an explicit consent gate with granular, unbundled, non-pre-checked options (treatment vs research vs marketing vs third-party sharing), MUST allow later revocation from settings, and MUST NOT block core care when a non-essential consent is declined.
- **Why:** Health data is special-category data under most privacy law; bundled or implied consent is both a legal risk and a trust violation. Users must control who sees their most sensitive information.
- **Platforms:** all
- **Severity:** error
- **Check:** Consent gate precedes collection/sharing; options are granular and unbundled; nothing pre-checked; revocation exists; declining non-essential consent doesn't block care.
- **See also:** [[MED-010]], [[MED-015]], [[PERM-001]]

### MED-010 — Disclose data use in plain language at the point of decision
- **Rule:** At the point of collecting or sharing health data, the app MUST state in plain language what data is collected, why, who can access it, and retention — using a layered summary + link to full detail. Surprising uses (cloud storage, third-party processors, research, cross-border transfer) MUST be called out explicitly, not buried.
- **Why:** Informed consent requires understandable, timely disclosure; legalese buried in a policy fails users and regulators and destroys trust when discovered.
- **Platforms:** all
- **Severity:** error
- **Check:** A plain-language summary appears at the decision point; full detail is linked; non-obvious data uses are explicitly surfaced.
- **See also:** [[MED-004]], [[MED-013]], [[MED-015]]

### MED-015 — Protect PHI on the device (masking, session, background)
- **Rule:** Screens showing PHI MUST mask content in the OS app-switcher/recents snapshot and while backgrounded, SHOULD offer biometric/passcode lock for clinical data, and MUST keep PHI out of logs, analytics, screenshots, and clipboards. Provide an accessible unlock path and clear "whose record" context.
- **Why:** Health data leaking via recents snapshots, logs, or shoulder-surfing is a privacy breach with legal and personal consequences; masking and locking are standard, expected protections.
- **Platforms:** iOS (privacy overlay), Android (`FLAG_SECURE`), others where supported
- **Severity:** warning
- **Check:** PHI screens apply a background overlay; no PHI in logs/analytics; optional lock present with accessible unlock; active patient context is shown.
- **See also:** [[MED-004]], [[MED-010]], [[MED-008]]

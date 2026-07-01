# Examples — Worked Screens & Flows

> Purpose: A gallery of complete, spec-driven examples that prove the skill's output quality. Each example is a folder with a `spec.md` (intent, platforms/frameworks, states map, thumb-zone, accessibility, tokens, motion, acceptance checklist) and — for built examples — per-framework implementations plus an audit report showing the validators PASS. The **flagship 5** are built first, across all four v1 frameworks, and double as golden regression tests for the validators.

## How to read an example

Every `spec.md` follows the same sections so they're comparable and auditable:

1. **Intent / user goal** — what the user is trying to accomplish.
2. **Platforms & frameworks** — target OS paradigm(s) and v1 framework coverage.
3. **States map** — which of the 7 states apply and exactly how each looks.
4. **Layout & thumb-zone** — structure + what lives in the bottom reach arc.
5. **Accessibility** — labels/roles, contrast, target size, Dynamic Type, motion.
6. **Token usage** — the semantic tokens the screen binds to (no magic values).
7. **Motion** — durations, easing/springs, reduce-motion fallback.
8. **Acceptance checklist** — PASS gate mapped to `quality-checks/validators/`.

Specs reference rules by ID (`[[NAV-001]]`) and reuse the recipes in [`patterns/`](../patterns/_index.md).

## The 7 states (shared vocabulary)

Ideal · Empty (first-use / user-cleared / no-results) · Loading · Error · Offline · Success · Permission-denied. See [`patterns/empty-error-offline.md`](../patterns/empty-error-offline.md).

## Flagship 5 (built first — all 4 frameworks, exemplary)

| Example | Folder | Proves | Primary patterns | Key rule domains |
|---|---|---|---|---|
| **Login** | [`login/`](login/spec.md) | Accessible auth, paste/passkeys, all states | form-flows, empty-error-offline | AUTH, FRM, A11Y, STATE |
| **Dashboard** | [`dashboard/`](dashboard/spec.md) | Responsive layout, per-widget states, glanceable data | navigation, list-detail, empty-error-offline | GRD, STATE, CHT, NAV |
| **Chat** | [`chat/`](chat/spec.md) | Optimistic send, offline queue, keyboard + safe-area | feed, empty-error-offline | CHAT, OFF, A11Y, STATE |
| **Checkout** | [`checkout/`](checkout/spec.md) | Payments, trust, no double-charge, guest + native Pay | checkout, form-flows | PAY, FRM, A11Y, STATE |
| **Settings** | [`settings/`](settings/spec.md) | Platform conventions, grouped/searchable, destructive isolation | navigation, list-detail | SET, PLAT, A11Y, NAV |

## Full planned catalog (20+)

Coverage legend: v1 frameworks are **Flutter (FL)**, **React Native (RN)**, **SwiftUI (SW)**, **Jetpack Compose (JC)**. Flagships target all four; others target ≥1 in v1.

| # | Example | Industry pack | Flagship | Primary pattern(s) | Frameworks (v1) | Status |
|---:|---|---|:--:|---|---|---|
| 1 | Login | — / all | ⭐ | form-flows, empty-error-offline | FL · RN · SW · JC | spec ✅ |
| 2 | Signup | — / all | | form-flows, onboarding | FL · RN | planned |
| 3 | Dashboard | Productivity / Finance | ⭐ | navigation, list-detail | FL · RN · SW · JC | spec ✅ |
| 4 | Profile | — / all | | list-detail, form-flows | SW · JC | planned |
| 5 | Settings | — / all | ⭐ | navigation, list-detail | FL · RN · SW · JC | spec ✅ |
| 6 | Search | E-commerce / Social | | search-patterns | RN · JC | planned |
| 7 | Checkout | E-commerce | ⭐ | checkout, form-flows | FL · RN · SW · JC | spec ✅ |
| 8 | Shopping Cart | E-commerce | | checkout, list-detail | FL · RN | planned |
| 9 | Chat | Social / Messaging | ⭐ | feed, empty-error-offline | FL · RN · SW · JC | spec ✅ |
| 10 | Maps | Travel / Ride-sharing | | list-detail, empty-error-offline | SW · JC | planned |
| 11 | Analytics | Finance / Productivity | | list-detail, empty-error-offline | JC · FL | planned |
| 12 | Music Player | Streaming | | (media) empty-error-offline | SW · JC | planned |
| 13 | Video Player | Streaming | | (media) empty-error-offline | FL · RN | planned |
| 14 | Fitness | Fitness | | dashboard, empty-error-offline | SW · JC | planned |
| 15 | Banking (accounts) | Finance / Banking | | list-detail, empty-error-offline | FL · SW | planned |
| 16 | Medical (records) | Healthcare | | list-detail, form-flows | JC · FL | planned |
| 17 | CRM (contacts) | Enterprise / CRM | | list-detail, search | JC · RN | planned |
| 18 | Task Manager | Productivity | | list-detail, form-flows | FL · JC | planned |
| 19 | Food Delivery | Food delivery | | feed, checkout | RN · FL | planned |
| 20 | Ride Sharing | Ride-sharing | | maps, checkout | SW · JC | planned |
| 21 | Travel Booking | Travel | | search, checkout, form-flows | FL · RN | planned |
| 22 | AI Assistant | AI chat | | chat, empty-error-offline | RN · JC | planned |
| 23 | Onboarding | — / all | | onboarding-patterns | FL · SW | planned |
| 24 | Notifications Center | Social / all | | feed, empty-error-offline | JC · RN | planned |

> "planned" examples ship after the flagship 5. Each new example must: bind only to tokens (`token_lint` PASS), design all applicable states (`state_coverage` PASS), and pass the accessibility validators before merge (see `quality-checks/`).

## Definition of done (per example)

- [ ] `spec.md` complete with all 8 sections and a states map.
- [ ] Implementation in each targeted framework, idiomatic (correct nav/sheet/safe-area/a11y/motion primitive).
- [ ] All applicable states from the matrix implemented, not just ideal.
- [ ] `quality-checks/validators/run_all.py` → PASS / high readiness score.
- [ ] Dark mode + RTL verified; Dynamic Type to 200% without clipping.
- [ ] Audit report committed alongside the code.

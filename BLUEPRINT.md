# Mobile UI/UX Pro Max Skill — Master Technical Design Document (Blueprint)

> **Status:** Implementation-ready blueprint. Another AI (or human team) should be able to build the entire project from this document with minimal additional planning.
> **Document type:** Technical Design Doc + Build Plan.
> **Author:** "The Council" — Senior Mobile Product Designer · UX Researcher · Design Systems Architect · Flutter/RN Engineer · iOS Engineer · Android Engineer · AI Prompt Engineer.
> **Grounding:** 6 parallel research briefs verifying current (2025–2026) standards. Key sources in Appendix C.

---

## Context — Why this is being built

AI coding assistants generate mobile UI that is **generic, inaccessible, and platform-agnostic-to-a-fault**. Verified failure modes (research brief F): training corpora bias models toward non-semantic markup (no roles/labels), "Inter-everywhere" sameness, skipped invisible states (loading/empty/error/focus/disabled), and a "hybrid native to neither iOS nor Android" look. Existing AI design tools (v0, Figma Dev Mode MCP, Builder.io, the `frontend-design` skill) are **web/React-centric**, hardcode values instead of binding to tokens, and treat states + accessibility as afterthoughts.

**The gap:** there is no best-in-class, **mobile-first, cross-framework, token-driven, accessibility-enforced** open-source skill. This project fills it. The intended outcome is a single installable Claude Agent Skill that makes any AI assistant design mobile apps like a senior product designer — applying Material 3 Expressive / Apple HIG (iOS 26) / WCAG 2.2 by default, mandating all UI states, binding to design tokens, respecting thumb-zone ergonomics, and routing correctly between platforms and frameworks.

**Locked decisions (user-confirmed):**
1. **Packaging:** Single installable skill with one router `SKILL.md` + deep progressive-disclosure reference tree.
2. **Validators:** Ship runnable validators (zero context cost; deterministic PASS/FAIL audits) **and** prose checklists.
3. **License:** Apache-2.0 (patent grant, enterprise-friendly, NOTICE attribution).
4. **v1 scope:** Depth-first — Flutter, React Native, SwiftUI, Jetpack Compose + 5 industries (Finance/Banking, Healthcare, E-commerce/Marketplace, Social/Messaging, Productivity).

---

## Table of Contents
1. [Vision](#1-vision)
2. [Architecture](#2-architecture)
3. [Rule System](#3-rule-system)
4. [Industry Packs](#4-industry-packs)
5. [Framework Support](#5-framework-support)
6. [AI Behaviour](#6-ai-behaviour)
7. [Prompt Library](#7-prompt-library)
8. [Quality Checklist & Validators](#8-quality-checklist--validators)
9. [Examples](#9-examples)
10. [Roadmap](#10-roadmap)
11. [Cross-Cutting Standards](#11-cross-cutting-standards) (naming, docs, testing, versioning, contribution)
12. [Pitfalls & Mitigations](#12-pitfalls--mitigations)
13. [Appendices](#13-appendices) (decision log, rule-file schema, research sources, verification plan)

---

## 1. Vision

### Mission
> Teach any AI coding assistant to design mobile apps like a senior product designer — accessible, platform-correct, token-driven, and emotionally resonant — on the first try, across any framework.

### Goals
| # | Goal | Measurable target |
|---|------|-------------------|
| G1 | **Accessibility by default** | 100% of generated screens pass the bundled WCAG 2.2 AA validator suite (contrast, 44pt/48dp targets, labels, state announcements). |
| G2 | **All states, always** | Every generated screen ships the 7 states (ideal, empty, loading, error, offline, success, permission-denied). State-coverage validator = PASS. |
| G3 | **Token-driven output** | Zero hardcoded color/spacing/radius values; everything references semantic tokens. `token_lint` = PASS. |
| G4 | **Platform correctness** | Output obeys the correct platform paradigm (HIG/iOS 26 vs Material 3 Expressive vs adaptive) — no "neither-native" hybrids. |
| G5 | **Framework fidelity** | Idiomatic output for each supported framework (correct widgets, theming API, safe-area primitive, a11y API, animation primitive). |
| G6 | **Token-efficient at runtime** | `SKILL.md` ≤ 500 lines / ~5k tokens; deep knowledge loaded only on demand (progressive disclosure). |
| G7 | **Best open-source mobile UX skill** | Adoption (installs, GitHub stars), contributor count, and reproducible quality benchmark beating baseline generation. |

### Target users
- **Primary:** AI coding assistants (Claude Code, Cursor, Copilot, Gemini CLI, Codex) building mobile UI on behalf of developers.
- **Secondary (humans):** Indie devs & startups without a designer; design-system teams seeking an enforceable spec; agencies standardizing quality; educators teaching mobile UX; the OSS community extending the rule corpus.

### Problems solved
1. **Generic UI** → forces explicit aesthetic + platform direction; bans default-font sameness.
2. **Inaccessible UI** → bakes WCAG 2.2 + platform a11y APIs into every component; ships runnable auditors.
3. **Missing states** → mandates the 7-state model; validator fails screens that ship "loaded-only."
4. **Hardcoded values** → token-first architecture; lint rejects magic values.
5. **Platform confusion** → a decision router that picks HIG vs Material vs adaptive and applies the right nav/sheet/typography/motion.
6. **Bad ergonomics** → thumb-zone, touch-target, safe-area, gesture, and haptic rules placed by default.
7. **Framework drift** → per-framework reference packs map one semantic design to idiomatic code.

### Competitive advantages
- **Mobile-native & cross-framework** where v0/Figma-MCP are web/React-centric.
- **Enforced, not suggested:** ships executable validators (zero context cost) + prose checklists.
- **Token-driven by construction**, DTCG-2025.10 compliant.
- **Current:** Material 3 Expressive (May 2025), iOS 26 Liquid Glass (June 2025), Android 16 window size classes, WCAG 2.2.
- **Progressive disclosure:** exhaustive on disk, lean in context.
- **Open & extensible:** Apache-2.0, documented rule schema, contribution workflow → community flywheel.

---

## 2. Architecture

### 2.1 Design principle — Progressive disclosure (3 tiers)
Per verified Agent-Skills best practice, only `name` + `description` are pre-loaded (~100 tokens). So:
- **Tier 1 (always loaded):** `SKILL.md` frontmatter — the discovery surface.
- **Tier 2 (on activation):** `SKILL.md` body — a **router / table of contents**, ≤ 500 lines / ~5k tokens. It contains the *decision protocol* and *pointers*, not the knowledge itself.
- **Tier 3 (on demand):** everything in `rules/`, `frameworks/`, `industries/`, etc. — read only when relevant. Reference files are **read for knowledge**; scripts in `tools/` are **executed, not loaded** (zero context cost).

> **Architecture mandate:** `SKILL.md` is a map, not a manual. Each rule/framework/industry pack is one level deep, domain-split, with a TOC at the top of any file > 100 lines. No single Tier-3 file should be required reading in full for a routine task.

### 2.2 Full folder structure
```
mobile-uiux-pro-max-skill/
├── SKILL.md                       # Tier-2 router: frontmatter + decision protocol + pointers
├── README.md                      # Human landing page (what/why/install/quickstart)
├── LICENSE                        # Apache-2.0
├── NOTICE                         # Attribution (Apache-2.0 requirement)
├── CHANGELOG.md                   # Keep a Changelog format + SemVer
├── CONTRIBUTING.md                # Rule-proposal + PR workflow
├── CODE_OF_CONDUCT.md
├── VERSION                        # Single source of truth for skill version
│
├── rules/                         # Tier-3: the reusable rule corpus (the heart)
│   ├── _index.md                  # Master rule registry: ID → file → title → severity
│   ├── foundations/               # spacing, typography, color, elevation, shape, icon, grid, density
│   ├── components/                # buttons, cards, lists, nav, sheets, dialogs, forms, search, chips, tables, charts, badges, avatars, progress
│   ├── interaction/               # motion, micro-interactions, gestures, haptics, states
│   ├── system/                    # accessibility, performance, offline, dark-mode, localization-rtl, notifications, permissions, settings, platform-conventions
│   └── domain/                    # auth, payments, chat, maps, media, camera, biometrics, onboarding, profile, widgets
│
├── patterns/                      # Composed, multi-component recipes (how rules combine)
│   ├── _index.md
│   ├── navigation-patterns.md     # bottom nav vs rail vs drawer; tab + stack; deep links
│   ├── list-detail.md             # master-detail, responsive across size classes
│   ├── form-flows.md              # multi-step, validation, keyboard avoidance
│   ├── feed-patterns.md           # infinite scroll, pull-to-refresh, optimistic actions
│   ├── search-patterns.md         # instant search, filters, recent/suggested, zero-results
│   ├── onboarding-patterns.md     # value-first, progressive permission priming
│   ├── checkout-patterns.md       # cart → address → pay → confirm; guest checkout
│   └── empty-error-offline.md     # the state-design playbook
│
├── design-system/                 # The token + theming engine spec
│   ├── tokens/                    # DTCG-2025.10 JSON (primitive/semantic/component)
│   │   ├── primitives/            # color.json dimension.json typography.json shadow.json motion.json
│   │   ├── semantic/              # color.json spacing.json elevation.json motion.json radius.json
│   │   ├── components/            # button.json card.json input.json ...
│   │   ├── themes/                # light.json dark.json high-contrast.json brand-template.json
│   │   ├── $metadata.json
│   │   └── $themes.json
│   ├── token-spec.md              # tiering rules, naming, why semantics enable theming
│   ├── type-scale.md              # modular scale, line-height, optical sizing
│   ├── spacing-system.md          # 4/8pt grid, baseline grid
│   ├── motion-system.md           # durations, easing, M3 spring tokens, iOS springs
│   └── build/                     # Style Dictionary v4 config → css/ts/swift/kotlin/dart outputs
│       └── config.json
│
├── frameworks/                    # Tier-3: per-framework idiomatic mapping
│   ├── _index.md                  # framework router + capability matrix
│   ├── flutter/                   # (v1) ThemeExtension, Cupertino/Material adaptive, Semantics
│   ├── react-native/              # (v1) + expo notes, Reanimated, safe-area-context
│   ├── swiftui/                   # (v1) Liquid Glass, detents, Dynamic Type, accessibility modifiers
│   ├── jetpack-compose/           # (v1) M3 Expressive, WindowSizeClass, edge-to-edge
│   ├── ios-uikit/                 # (v2)
│   ├── android-views/             # (v2)
│   ├── expo/                      # (v2) router/expo-specific
│   ├── ionic/                     # (v2) mode="ios|md" adaptivity
│   └── dotnet-maui/               # (v2) handlers/mappers
│
├── industries/                    # Tier-3: domain UX packs
│   ├── _index.md
│   ├── finance-banking/           # (v1)
│   ├── healthcare/                # (v1)
│   ├── ecommerce-marketplace/     # (v1)
│   ├── social-messaging/          # (v1)
│   ├── productivity/              # (v1)
│   └── ...                        # (v2+) education, fitness, travel, food-delivery, crm, erp,
│                                  #        streaming, ai-chat, real-estate, automotive, government,
│                                  #        enterprise, gaming, ride-sharing
│
├── prompts/                       # Tier-3: reusable task prompts (generate/improve/audit/...)
│   ├── _index.md
│   ├── generate-screen.md  improve-screen.md  audit-screen.md
│   ├── accessibility-review.md  ux-review.md  animation-review.md
│   ├── design-system-generator.md  component-generator.md
│   └── *-generator.md             # onboarding/settings/dashboard/chat/profile/checkout/auth
│
├── generators/                    # Scaffolding generators (templates + driver prompts)
│   ├── _index.md
│   ├── screen-scaffold/           # produces all 7 states + a11y + tokens, per framework
│   ├── design-system-scaffold/    # emits DTCG tokens + Style Dictionary config
│   └── component-scaffold/        # single component with variants/states/a11y
│
├── quality-checks/                # Prose checklists + executable validators
│   ├── _index.md                  # the auto-review pipeline + scoring
│   ├── checklists/                # human/AI-readable PASS/FAIL lists (one per domain)
│   │   ├── accessibility.md  states.md  spacing.md  typography.md  contrast.md
│   │   ├── platform-conventions.md  responsive.md  motion.md  consistency.md
│   └── validators/                # EXECUTABLE (run, don't load) — Python, stdlib-only
│       ├── contrast_check.py       # WCAG 2.2 ratios from token pairs / source
│       ├── target_size_lint.py     # 44pt/48dp + 8dp spacing
│       ├── state_coverage.py        # detects missing empty/loading/error/offline
│       ├── token_lint.py            # flags hardcoded color/spacing/radius
│       ├── dynamic_type_check.py    # fixed text heights, truncation risks
│       ├── rtl_check.py             # hardcoded left/right, directionality
│       ├── run_all.py               # orchestrator → JSON + markdown report
│       └── tests/                   # pytest fixtures (golden good/bad inputs)
│
├── checklists/                    # Quick-reference, role-oriented (designer/dev/QA/PM)
│   └── pre-ship.md  design-review.md  handoff.md
│
├── templates/                     # Copy-paste starting points (token files, component stubs, RFCs)
│   ├── token-file.template.json
│   ├── rule.template.md
│   ├── industry-pack.template.md
│   └── framework-pack.template.md
│
├── examples/                      # Tier-3: complete worked examples (20+)
│   ├── _index.md
│   └── <example>/                 # spec.md + per-framework code + states + a11y notes
│
└── .github/
    ├── workflows/ci.yml           # lint rules registry, run validator tests, link-check
    ├── ISSUE_TEMPLATE/            # rule-proposal.md, bug.md, framework-request.md
    └── PULL_REQUEST_TEMPLATE.md
```

### 2.3 `SKILL.md` router design (Tier-2)
The body is a decision protocol + pointer table, deliberately small. Skeleton:
```markdown
---
name: mobile-uiux-pro-max
description: Use when designing, generating, improving, or auditing ANY mobile app UI/UX
  (Flutter, React Native, SwiftUI, Jetpack Compose, iOS, Android, Expo, Ionic, MAUI).
  Applies Material 3 Expressive, Apple HIG (iOS 26), and WCAG 2.2 by default; enforces
  design tokens, all 7 UI states, thumb-zone ergonomics, and platform conventions.
  Triggers: "design a screen", "build a mobile UI", "make this accessible", "audit my
  app's UX", "generate a login/checkout/dashboard", "improve this screen", "dark mode",
  "responsive/foldable layout", "RTL/localization".
---

# Mobile UI/UX Pro Max

## ALWAYS DO FIRST — Pre-Generation Protocol  (see §6)
Run the 15-point think-list before emitting any UI. Then route:

## Routers (read only the file you need)
| If the task is... | Read |
|---|---|
| pick platform paradigm | rules/system/platform-conventions.md |
| target framework X | frameworks/<x>/_index.md |
| an industry app | industries/<industry>/_index.md |
| spacing/type/color/etc | rules/foundations/<topic>.md |
| a component | rules/components/<component>.md |
| states/motion/gestures | rules/interaction/<topic>.md |
| accessibility | rules/system/accessibility.md |
| generate a full screen | prompts/generate-screen.md |
| audit/review | quality-checks/_index.md → run validators/run_all.py |

## Non-negotiables (the 5 laws)
1. Token-driven (no magic values).  2. All 7 states.  3. WCAG 2.2 AA + platform a11y.
4. Correct platform paradigm.  5. Thumb-zone & 44pt/48dp targets.
```

`★ Architecture rationale:` The router keeps Tier-2 lean so 600+ rules never bloat context; the model pulls exactly the 1–3 Tier-3 files a task needs, and runs validators as subprocesses (zero tokens). This is the single most important design decision for runtime quality.

---

## 3. Rule System

### 3.1 Rule-file schema (every rule is atomic & testable)
```markdown
### SPC-001 — Snap spacing to the 4/8pt grid
- **Rule:** All margins, padding, gaps MUST be multiples of 4dp (prefer 8dp steps: 4,8,12,16,24,32,48,64).
- **Why:** Optical rhythm + cross-platform density consistency (Material baseline grid).
- **Platforms:** all
- **Severity:** error | warning | suggestion
- **Check:** `token_lint.py` flags off-grid literals.
- **Exceptions:** hairline borders (1px), platform insets read dynamically.
- **See also:** [[GRD-004]], [[DEN-002]]
```
Every rule has a stable **ID**, severity, machine-checkable `Check` where possible, and `See also` cross-links (`[[ID]]`). `rules/_index.md` is the generated registry (ID → file → title → severity → check).

### 3.2 Rule domains, ID prefixes, target counts (~680 rules total)

**Foundations (~110)**
| Prefix | Domain | Why | Count | Example rule |
|---|---|---|---|---|
| SPC | Spacing & layout grid | Rhythm/consistency; 4/8pt grid | 18 | SPC: screen edge margins 16–20pt (iOS) / 16dp (Android). |
| TYP | Typography | Hierarchy, legibility, Dynamic Type | 22 | TYP: body base 16, modular scale ~1.2; line-height body 1.5. |
| COL | Color & theming | Semantic roles, contrast, Material You | 20 | COL: components reference semantic roles only, never primitives. |
| ELV | Elevation & shadow | Depth hierarchy | 10 | ELV: use 5 M3 elevation levels; raise one level on interaction. |
| SHP | Shape & corner radius | M3 10-step scale, hardware-concentric on iOS | 8 | SHP: cards 12–16dp; pill = 9999; iOS corners concentric w/ device. |
| ICN | Iconography | Clarity, hit area, SF Symbols/Material | 10 | ICN: pad icon glyphs to ≥44pt/48dp hit area. |
| GRD | Grid & responsive layout | Size classes, multi-pane | 16 | GRD: <600dp single column; ≥840dp two-pane list-detail. |
| DEN | Density | Comfortable vs compact | 6 | DEN: provide a density token set; default comfortable on mobile. |

**Components (~212)**
| Prefix | Domain | Count | Example |
|---|---|---|---|
| BTN | Buttons | 18 | BTN: one primary action per view; min 44pt/48dp; loading + disabled states. |
| CRD | Cards | 12 | CRD: tappable card = single primary target; avoid nested tap conflicts. |
| LST | Lists & collections | 18 | LST: virtualize (builder/Lazy/FlatList/RecyclerView); skeleton on load. |
| NAV | Navigation | 24 | NAV: ≤5 bottom tabs; rail at ≥600dp; never override system back. |
| BSH | Bottom sheets | 12 | BSH: use detents/breakpoints; respect 34pt home-indicator inset. |
| DLG | Dialogs & alerts | 14 | DLG: destructive confirm is explicit; primary action right (platform-aware). |
| FRM | Forms & inputs | 30 | FRM: inline validation 150–200ms; keyboard avoidance; correct keyboard type. |
| SRCH | Search | 12 | SRCH: debounce; recent + suggested; distinct zero-results empty state. |
| CHP | Chips & filters | 8 | CHP: selected state not color-only; ≥8dp gaps. |
| TAB | Tables & data grids | 12 | TAB: prefer cards on compact; sticky header; horizontal-scroll affordance. |
| CHT | Charts & data viz | 14 | CHT: never color-only encoding; provide data table a11y fallback. |
| BDG | Badges/banners/snackbars | 12 | BDG: snackbar transient + Undo; offline banner non-blocking, auto-dismiss. |
| AVT | Avatars & media thumbs | 6 | AVT: fallback initials/icon; alt text. |
| PRG | Progress & sliders | 10 | PRG: determinate when duration knowable; slider = adjustable a11y trait. |

**Interaction & Motion (~80)**
| Prefix | Domain | Count | Example |
|---|---|---|---|
| MOT | Motion & transitions | 20 | MOT: micro 100ms / small 200–250 / medium 300–400 / large 400–500; never >500 routine. |
| MIC | Micro-interactions | 12 | MIC: button press scale 0.96–0.98 + haptic; like 300–400ms bouncy. |
| GES | Gestures | 16 | GES: never gesture-only critical paths; inset carousels from system edges. |
| HAP | Haptics | 8 | HAP: meaningful events only; never sole feedback; describe intent (Android). |
| STATE | UI states | 24 | STATE: ship empty(×3)/loading/error/offline/success/permission-denied per screen. |

**System & Platform (~154)**
| Prefix | Domain | Count | Example |
|---|---|---|---|
| A11Y | Accessibility | 40 | A11Y: text ≥4.5:1; targets 44pt/48dp; labels+roles+state; live-region announce. |
| PERF | Performance | 16 | PERF: animate transform/opacity only; hold 16ms frame budget; lazy images. |
| OFF | Offline & sync | 14 | OFF: optimistic UI + visible rollback; queue + exponential backoff; sync states. |
| DRK | Dark mode | 12 | DRK: theme via semantic layer; not pure #000; elevation overlays in dark. |
| L10N | Localization & RTL | 18 | L10N: mirror layout/icons in RTL; no string concatenation; pseudo-localize. |
| NOTIF | Notifications | 12 | NOTIF: prime before requesting; channels/categories; deep-link to context. |
| PERM | Permissions | 12 | PERM: just-in-time, value-first; handle denied with settings deep-link. |
| SET | Settings | 10 | SET: grouped, searchable; destructive actions isolated. |
| PLAT | Platform conventions | 20 | PLAT: pick HIG vs M3 vs adaptive; correct nav/sheet/typography/back per OS. |

**Domain features (~126)**
| Prefix | Domain | Count | Example |
|---|---|---|---|
| AUTH | Authentication | 18 | AUTH: allow paste/password managers/passkeys (WCAG 3.3.8); biometric opt-in. |
| PAY | Payments & checkout | 18 | PAY: native Pay buttons; review before charge; guest checkout; error recovery. |
| CHAT | Chat & messaging | 16 | CHAT: optimistic send + status; typing/read receipts; keyboard + safe-area. |
| MAP | Maps & location | 12 | MAP: bottom-sheet detail; one-handed controls; location-denied state. |
| MEDIA | Media (a/v/image) | 14 | MEDIA: captions/transcripts; no autoplay audio; PiP; scrub haptics. |
| CAM | Camera & scanning | 10 | CAM: clear capture affordance; permission priming; result confirmation. |
| BIO | Biometrics | 8 | BIO: always provide passcode fallback; never store biometric as only factor. |
| ONB | Onboarding | 12 | ONB: value-first; skippable; progressive permission priming. |
| PROF | Profile & account | 10 | PROF: account deletion reachable (store policy); edit with optimistic save. |
| WID | Home-screen widgets | 8 | WID: glanceable; tap deep-links; respect platform widget sizes. |

> Counts are **targets**, not caps; the registry tracks actual. "Hundreds of rules" = ~680 at v1-complete; v1 depth-first ships the Foundations + Components + Interaction + System core (~450) plus the 5 industry/4 framework packs.

---

## 4. Industry Packs

Each pack is one folder with a fixed structure (`templates/industry-pack.template.md`):
```
industries/<name>/
  _index.md          # when to use, the 5 most load-bearing patterns, links to rules
  patterns.md        # domain screen patterns (e.g. account dashboard, transfer flow)
  components.md      # domain-specific components (e.g. transaction row, vitals card)
  trust-and-safety.md# domain trust signals, compliance UX (e.g. PCI, HIPAA-adjacent UX)
  copy-and-tone.md   # voice, microcopy, error messaging norms
  accessibility.md   # domain-specific a11y (e.g. medical legibility, finance numerals)
  pitfalls.md        # common domain mistakes
```

| Industry | v | Load-bearing concerns (extracted as rules) |
|---|---|---|
| **Finance / Banking** | v1 | Trust & security cues; tabular numerals + alignment; balance privacy toggle; destructive/irreversible (transfer/pay) out of thumb arc + confirm; transaction states; biometric + paste-friendly auth (3.3.8). |
| **Healthcare** | v1 | Legibility at large Dynamic Type; calm/low-arousal motion; error-intolerant flows (dosage); privacy/consent UX; offline reliability; color-independent status. |
| **E-commerce / Marketplace** | v1 | Product grid/list responsive; cart + optimistic add; checkout pattern; guest checkout; trust badges; zero-results & filter empty states; native Pay. |
| **Social / Messaging** | v1 | Feed + infinite scroll + pull-to-refresh; optimistic post/like/send + rollback; chat keyboard/safe-area; notification priming; report/block safety. |
| **Productivity** | v1 | List-detail across size classes; multi-select/bulk actions; offline-first + sync indicators; keyboard shortcuts (tablet/foldable); undo. |
| Education | v2 | Progress, streaks, focus mode, accessibility for young/older users. |
| Fitness | v2 | Glanceable metrics, haptics, during-activity one-handed/no-look UI. |
| Travel | v2 | Itinerary, maps, offline tickets, time-zone/locale. |
| Food delivery | v2 | Live tracking, ETA, address/maps, reorder. |
| CRM / ERP / Enterprise | v2 | Dense data, tables, roles/permissions, audit, tablet-first. |
| Streaming | v2 | Media player, continue-watching, dark-first, casting. |
| AI Chat | v2 | Streaming responses, stop/regenerate, citations, token/latency states. |
| Real estate / Automotive / Government / Gaming / Ride-sharing | v2 | Maps, media-heavy, trust/compliance, live state. |

---

## 5. Framework Support

### 5.1 Strategy
**Design once as semantic tokens; map per framework.** Each framework pack maps the *same* design system to idiomatic code. v1 ships 4 (depth-first); v2 adds 5.

### 5.2 Framework pack structure
```
frameworks/<name>/
  _index.md        # capability summary + when to choose adaptive vs single-platform
  tokens.md        # how this framework consumes DTCG tokens / theming API
  components.md    # idiomatic button/list/sheet/nav + safe area + a11y + animation
  states.md        # how to implement the 7 states here
  adaptive.md      # platform-adaptive guidance (where supported)
  snippets/        # minimal, copy-paste idiomatic stubs (per component)
```

### 5.3 Capability matrix (from research brief F — drives each pack)
| Framework | v | Tokens/Theming | Safe area | Sheet | A11y API | Animation | Adaptive |
|---|---|---|---|---|---|---|---|
| **Flutter** | v1 | `ThemeExtension`, `ColorScheme.fromSeed` | `SafeArea`, `MediaQuery` | `showModalBottomSheet`/`DraggableScrollableSheet` | `Semantics` | `AnimationController`/implicit | Material vs Cupertino, `.adaptive` ctors |
| **React Native (+Expo)** | v1 | context + Restyle/NativeWind/Unistyles | `react-native-safe-area-context` | `@gorhom/bottom-sheet` | `accessibilityLabel/Role/State` | Reanimated 3 + Gesture Handler | manual `Platform.select`, `.ios/.android.tsx` |
| **SwiftUI** | v1 | semantic `Color` sets, `@Environment` | auto + `.safeAreaInset` | `.sheet` + `.presentationDetents` | `.accessibility*`, Dynamic Type | `withAnimation`, springs, `PhaseAnimator` | Apple-only; size classes; **Liquid Glass** |
| **Jetpack Compose** | v1 | `MaterialTheme` + `CompositionLocal`, dynamicColor | `WindowInsets`, `enableEdgeToEdge` | `ModalBottomSheet` | `Modifier.semantics` | `animate*AsState`, springs | `WindowSizeClass`; **M3 Expressive** |
| iOS UIKit | v2 | semantic `UIColor`, `UIAppearance` | `safeAreaLayoutGuide` | `UISheetPresentationController` | `accessibilityLabel/Traits` | `UIViewPropertyAnimator` | Apple-native |
| Android Views | v2 | `themes.xml`, `?attr`, DynamicColors | `WindowInsetsCompat` | `BottomSheetBehavior` | `contentDescription` | `ObjectAnimator`/`MotionLayout` | Android-native |
| Expo | v2 | (RN +) Expo Router, `userInterfaceStyle` | safe-area-context | gorhom | RN a11y | Reanimated | RN-manual |
| Ionic | v2 | CSS vars `--ion-*` | `env(safe-area-inset-*)` | `ion-modal` breakpoints | web ARIA | Animations API | **`mode="ios\|md"`** auto |
| .NET MAUI | v2 | `ResourceDictionary`, `AppThemeBinding` | `SafeAreaEdges` (.NET 9) | community plugin | `SemanticProperties` | `ViewExtensions` | handlers/mappers, `OnPlatform/OnIdiom` |

> **Rule baked into every pack:** lists must be virtualized; always use the framework's safe-area primitive; prefer adaptive APIs where they exist; sheets/nav diverge most → use detents/breakpoints + platform nav stacks.

---

## 6. AI Behaviour

This is *how the skill changes the assistant*. Two mechanisms: a mandatory **Pre-Generation Protocol** and a set of **decision routers**.

### 6.1 Pre-Generation Protocol (the 15-point think-list, in `SKILL.md`)
Before emitting any UI, the assistant must reason through:
1. **User goal** — what is the user trying to accomplish on this screen?
2. **Platform paradigm** — iOS (HIG/Liquid Glass) / Android (M3 Expressive) / adaptive?
3. **Framework** — which, and its idiomatic components/APIs?
4. **Information hierarchy** — primary action, secondary, content priority.
5. **Thumb reach & one-handed use** — where do primary/destructive actions go?
6. **Touch targets** — everything ≥ 44pt/48dp with ≥8dp spacing.
7. **All 7 states** — ideal, empty(×3), loading, error, offline, success, permission-denied.
8. **Accessibility** — contrast, labels/roles, focus order, Dynamic Type, reduce-motion.
9. **Dark mode** — semantic tokens resolve in both themes.
10. **Motion** — purposeful durations/easing or springs; reduce-motion fallback.
11. **Gestures & safe areas** — system gestures untouched; insets read dynamically.
12. **Localization & RTL** — no concatenation; layout mirrors; text expansion.
13. **Responsive / foldable** — size-class behavior; multi-pane ≥840dp.
14. **Tokens** — no magic values; reference semantic tokens.
15. **Consistency & performance** — reuse system components; virtualize; 16ms budget.

> Output contract: the assistant states (briefly) its platform/framework/paradigm choice, then generates, then self-audits against `quality-checks/` (running validators where code exists).

### 6.2 Decision routers (deterministic forks)
- **Platform router:** target OS unknown → ask or default to adaptive; iOS-only → HIG/Liquid Glass; Android-only → M3 Expressive; cross-platform → adaptive APIs + per-platform nav/sheet.
- **State router:** for each data-backed view, enumerate which of the 7 states apply and design each.
- **Component router:** map intent → idiomatic component per framework (e.g., "modal picker" → SwiftUI `.sheet`+detents / Compose `ModalBottomSheet` / Flutter `showModalBottomSheet` / gorhom).
- **Motion router:** Android target post-May-2025 → M3 spring tokens; iOS → SwiftUI springs / curve easing; always provide reduce-motion path.
- **A11y router:** any interactive element → require label+role+state; any color-encoded meaning → add non-color cue.

`★ Behavior rationale:` The protocol converts implicit senior-designer instincts into an explicit, repeatable checklist the model executes every time — this is what moves output from "plausible" to "correct," and it's why the skill mandates a self-audit pass rather than trusting first-shot generation.

---

## 7. Prompt Library

Each prompt file: **Purpose · Inputs · Procedure (steps + which rules/files to load) · Output format · Self-check.**

| Prompt | Purpose | Key inputs | Output |
|---|---|---|---|
| `generate-screen` | New screen, all states, a11y, tokens | screen intent, platform, framework, industry | code (all 7 states) + a11y notes + token usage |
| `improve-screen` | Upgrade existing screen | code/screenshot, goals | diff + rationale mapped to rule IDs |
| `audit-screen` | Full review | code/screenshot, platform | scored report (validators + checklists) |
| `accessibility-review` | WCAG 2.2 + platform a11y | code | 14-rule PASS/FAIL + fixes |
| `ux-review` | Heuristic + ergonomics | code/flow | findings by severity |
| `animation-review` | Motion correctness | code | timing/easing/reduce-motion findings |
| `design-system-generator` | Emit DTCG tokens + theme | brand seed, platforms | token files + Style Dictionary config |
| `component-generator` | One component, variants/states/a11y | component, framework | code + usage |
| `onboarding-generator` | Value-first onboarding + permission priming | app purpose | multi-screen flow |
| `settings-generator` | Grouped, searchable settings | sections | screen |
| `dashboard-generator` | Glanceable metrics, responsive | metrics, roles | screen(s) |
| `chat-generator` | Messaging UI, optimistic send | features | screen + states |
| `profile-generator` | Account/profile + deletion path | fields | screen |
| `checkout-generator` | Cart→pay→confirm, native Pay | steps | flow |
| `authentication-generator` | Login/signup, passkeys, biometrics, paste-friendly | methods | flow + states |

---

## 8. Quality Checklist & Validators

### 8.1 Two layers
- **Prose checklists** (`quality-checks/checklists/`): AI-readable PASS/FAIL lists, one per domain. The auditor reasons against them.
- **Executable validators** (`quality-checks/validators/`, Python stdlib-only, run not loaded): deterministic, zero context cost.

### 8.2 Master review pipeline (`quality-checks/_index.md`)
```
1. token_lint.py        → no hardcoded color/spacing/radius
2. contrast_check.py    → text ≥4.5:1, large ≥3:1, UI/icon/focus ≥3:1 (WCAG 2.2)
3. target_size_lint.py  → ≥44pt/48dp targets, ≥8dp spacing
4. state_coverage.py    → empty/loading/error/offline present
5. dynamic_type_check.py→ no fixed text heights; scales to 200%
6. rtl_check.py         → no hardcoded left/right; directionality-safe
7. run_all.py           → aggregates → weighted score + markdown report
8. (AI) reason through prose checklists for the non-mechanical items
```

### 8.3 The canonical auditor checklist (✓ items)
✓ Touch targets (44pt/48dp, ≥8dp spacing) ✓ Contrast (4.5:1 / 3:1 / 3:1) ✓ Accessibility labels+roles+state ✓ Focus/reading order ✓ Typography scale + Dynamic Type ✓ Spacing on 4/8pt grid ✓ Alignment ✓ Consistency (system components reused) ✓ Dark mode resolves ✓ Empty state ✓ Loading state ✓ Error state ✓ Offline state ✓ Reduced-motion path ✓ Responsive (size classes) ✓ Platform guidelines ✓ Tokens (no magic values) ✓ Localization/RTL ✓ No color-only meaning ✓ Drag has tap alternative (2.5.7) ✓ Auth allows paste/passkeys (3.3.8) ✓ Focus not obscured (2.4.11)

### 8.4 Scoring
`run_all.py` outputs a weighted **readiness score** (errors block, warnings deduct, suggestions inform) + a per-category breakdown, mirroring the project's `store-readiness` style so teams can gate CI on it.

`★ Validator rationale:` Scripts are *executed, not read into context*, so a 300-line contrast checker costs zero tokens at runtime while giving a deterministic verdict — strictly better than asking the model to eyeball ratios. Stdlib-only keeps install frictionless.

---

## 9. Examples

Each example: `examples/<name>/spec.md` (intent, platform, states map, a11y notes) + per-framework implementations (v1: at least one of the 4 frameworks; flagship examples in all 4) + all 7 states + audit report showing PASS.

**Planned (20+):** Login · Signup · Dashboard · Profile · Search · Checkout · Shopping Cart · Chat · Maps · Analytics · Music Player · Video Player · Fitness · Banking · Medical · CRM · Task Manager · Food Delivery · Ride Sharing · Travel Booking · AI Assistant.

**Flagship 5 (built first, all 4 frameworks, exemplary):** Login (auth/a11y), Dashboard (responsive/states), Chat (optimistic/offline), Checkout (payments/trust), Settings (platform conventions). These double as **golden tests** for the validators and as the proof-of-quality benchmark.

---

## 10. Roadmap

Effort assumes a small team (or 1 maintainer + AI agents). **E** = est. effort (person-weeks). Each phase has Milestones / Risks / Success criteria.

### Phase 1 — Foundation (E: 1–2)
- **Milestones:** repo scaffold, Apache-2.0 + NOTICE, `SKILL.md` router + Pre-Generation Protocol, rule schema + `templates/`, `rules/_index.md` registry, CI skeleton, CONTRIBUTING.
- **Risks:** over-stuffing `SKILL.md` (token bloat). **Mitigation:** enforce ≤500-line lint in CI.
- **Success:** skill installs & triggers; router resolves to stub files; CI green.

### Phase 2 — Core Rules (E: 3–4)
- **Milestones:** Foundations + Interaction + System rule domains written (~290 rules) with IDs, severities, checks; design-system token spec + DTCG token files + Style Dictionary build.
- **Risks:** inconsistent rule quality. **Mitigation:** rule template + peer review + registry lint.
- **Success:** every rule has ID/severity/why; tokens build to css/ts/swift/kotlin/dart.

### Phase 3 — Components (E: 2–3)
- **Milestones:** Components domain (~212 rules) + `patterns/` recipes; component-generator.
- **Risks:** components drift from tokens. **Mitigation:** examples must pass `token_lint`.
- **Success:** component-generator emits token-bound, all-state components.

### Phase 4 — Validators & Quality (E: 2–3)  *(elevated per "ship validators" decision)*
- **Milestones:** all 6 validators + `run_all.py` + pytest golden fixtures; prose checklists; scoring; wire into CI and the audit prompts.
- **Risks:** validator false positives erode trust. **Mitigation:** golden good/bad corpus; tune to high precision; clear "why" + fix in each finding.
- **Success:** flagship examples score PASS; bad fixtures correctly fail; <5% false-positive on corpus.

### Phase 5 — Framework Packs (v1 four) (E: 3–4)
- **Milestones:** Flutter, RN, SwiftUI, Compose packs (tokens/components/states/adaptive/snippets); flagship 5 examples implemented in all 4.
- **Risks:** framework API drift (e.g., Compose BOM, SwiftUI). **Mitigation:** date-stamp facts; quarterly review task; avoid pinning fragile versions in prose.
- **Success:** idiomatic output per framework; examples compile/lint in each.

### Phase 6 — Industry Packs (v1 five) (E: 2–3)
- **Milestones:** Finance, Healthcare, E-commerce, Social, Productivity packs.
- **Risks:** shallow/generic packs. **Mitigation:** each pack must add ≥10 domain-specific rules + 1 flagship example.
- **Success:** packs change generation measurably vs core-only baseline.

### Phase 7 — AI Optimization & Eval (E: 2)
- **Milestones:** eval suite (prompt → generation → validator score), description tuning for triggering, A-authors/B-tests loop, benchmark vs baseline.
- **Risks:** poor triggering / over-prescription. **Mitigation:** eval-driven description edits; "principles over rigidity" guidance in router.
- **Success:** measurable lift on benchmark; reliable trigger on target prompts.

### Phase 8 — Docs & Open-Source Release (E: 1–2)
- **Milestones:** README, docs site (optional), examples gallery, issue/PR templates, v1.0.0 tag + CHANGELOG, launch.
- **Risks:** contribution friction. **Mitigation:** rule-proposal template + good-first-issues.
- **Success:** external contributor merges a rule; v1.0.0 published.

> **Critical path:** P1→P2→P4 (validators) early, because validators are the quality backbone; framework/industry packs (P5/P6) can parallelize once rules + validators exist. Total v1: ~16–23 person-weeks, heavily compressible with parallel AI agents per pack.

---

## 11. Cross-Cutting Standards

### 11.1 Naming conventions
- **Rule IDs:** `PREFIX-NNN` (e.g., `A11Y-007`), stable forever; deprecate, never reuse.
- **Files/folders:** kebab-case; `_index.md` for routers; `*.template.*` for templates.
- **Skill `name`:** `mobile-uiux-pro-max` (lowercase, hyphens, ≤64 chars, no "claude"/"anthropic", gerund-friendly).
- **Tokens:** primitives by value (`color.blue.500`, `space.4`), semantics by intent (`color.action.primary`, `color.surface`), components by scope (`button.primary.bg`). Pattern: `[category]-[concept]-[property]-[variant]-[state]`.
- **Cross-links:** `[[RULE-ID]]` inside rule bodies; the registry resolves them.

### 11.2 Documentation standards
- Every rule uses the schema in §3.1; every pack uses its `templates/*.template.md`.
- Any file > 100 lines starts with a TOC. Reference files one level deep from `SKILL.md`.
- **Date-stamp volatile facts** ("as of 2025-12, Compose BOM…") and centralize them in `frameworks/<x>/_index.md` so refreshes are localized.
- README answers: what, why, who, install, 60-second quickstart, one before/after example.

### 11.3 Testing strategy
- **Validator unit tests:** pytest with golden good/bad fixtures (`validators/tests/`).
- **Golden examples:** flagship 5 must score PASS in CI (regression guard).
- **Registry lint:** every rule referenced in registry exists, has ID/severity/why; no dup IDs; `[[links]]` resolve.
- **Skill evals:** scenario prompts → generation → `run_all.py` score; track lift vs baseline; description-trigger tests.
- **Link/spec checks:** dead-link check; DTCG token files validate against schema; Style Dictionary build succeeds.
- **CI gates (`.github/workflows/ci.yml`):** SKILL.md size limit, registry lint, validator tests, token build, golden examples, link check.

### 11.4 Versioning
- **SemVer** on `VERSION` + git tags. **Major:** rule-ID removal/semantic change or breaking token rename. **Minor:** new rules/packs/frameworks/industries. **Patch:** fixes/clarifications.
- **Keep a Changelog** format in `CHANGELOG.md`.
- Record the **standards baseline** (Material 3 Expressive 2025, iOS 26, WCAG 2.2, DTCG 2025.10) in README; bump via a quarterly "standards refresh" issue.

### 11.5 Contribution workflow
- **Conventional Commits** (`feat:`, `fix:`, `docs:`, `rule:`…); branches `feat/`, `fix/`, `rule/`.
- **Rule proposal issue template:** problem, proposed rule, why, platforms, check, severity, sources.
- **PR template:** which rules/packs touched, validator results, examples updated, standards sources cited.
- **Review bar:** new rules need a rationale + (where possible) a machine check; packs need ≥1 example.
- **Governance:** CODEOWNERS per top-level area; "good first issue" = add/clarify a single rule.

---

## 12. Pitfalls & Mitigations

| # | Pitfall | Mitigation |
|---|---------|------------|
| 1 | **`SKILL.md` token bloat** kills runtime efficiency | CI line/size limit; keep it a router; push knowledge to Tier-3. |
| 2 | **Weak `description` → skill never triggers** | Treat description as the product surface; eval-test triggering; include concrete keywords. |
| 3 | **Stale platform facts** (OS/framework churn) | Date-stamp + centralize volatile facts; quarterly refresh; never hard-pin fragile versions in prose. |
| 4 | **Over-prescription kills creativity** | Mark rules error/warning/suggestion; router says "principles over rigidity" for flexible domains (aesthetics, motion personality). |
| 5 | **Validator false positives erode trust** | Golden corpus; tune for precision; every finding has a "why" + fix; allow inline opt-out comments. |
| 6 | **Generic output despite the skill** | Force explicit platform + aesthetic direction in Pre-Generation Protocol; ban default-font sameness. |
| 7 | **Token system ignored under deadline** | Make `token_lint` a default audit step; generators emit tokens by construction. |
| 8 | **RTL/localization neglected** | `rtl_check` validator; L10N rules in core; pseudo-localization in examples. |
| 9 | **Dark mode as afterthought** | Semantic-layer theming mandated; examples ship both themes; contrast checked per theme. |
| 10 | **Framework packs diverge from core rules** | Packs *reference* rule IDs, never restate; examples must pass validators. |
| 11 | **Dated ergonomics stats overstated** | Flag Hoober/Hurff figures as directional (per research caveats); rely on platform minimums for hard numbers. |
| 12 | **Scope creep (21 industries × 9 frameworks)** | Depth-first v1; template-driven packs; community-contributed expansion. |
| 13 | **APCA vs WCAG confusion** | Audit against **WCAG 2.2** now; treat APCA/WCAG 3.0 as informational (WCAG 3 not before ~2030). |
| 14 | **Gesture-only critical paths** | Rule + review: every gesture needs a visible fallback; never override system back/home. |

---

## 13. Appendices

### 13.A Decision log (locked)
1. Single skill + deep progressive-disclosure tree (token efficiency, simplest install).
2. Ship runnable validators + prose checklists (deterministic, zero-context audits).
3. Apache-2.0 + NOTICE (patent grant, enterprise-friendly).
4. Depth-first v1: Flutter/RN/SwiftUI/Compose + Finance/Healthcare/E-commerce/Social/Productivity.

### 13.B Rule-file & pack schemas
See §3.1 (rule schema), §4 (industry pack), §5.2 (framework pack); canonical copies live in `templates/`.

### 13.C Research grounding (sources)
- **Tokens/DTCG:** designtokens.org Format Module 2025.10 (first stable); Style Dictionary v4; Tokens Studio; material-color-utilities.
- **Platform:** Material 3 Expressive (m3.material.io, May 2025) — shape 10-step scale, 5 elevation levels, spring tokens; Apple HIG + iOS 26 Liquid Glass (apple.com newsroom, WWDC June 2025) + SF Symbols 7; Android 16 + Compose Material 3 (developer.android.com) — window size classes <600/600–839/≥840dp, predictive back, edge-to-edge.
- **Accessibility:** WCAG 2.2 (W3C Rec, Oct 2023) — 1.4.3/1.4.11 contrast, 2.5.8 target size, 2.4.11 focus-not-obscured, 2.5.7 dragging, 3.3.8 accessible auth; Apple 44pt / Material 48dp; VoiceOver/TalkBack; Dynamic Type; APCA/WCAG 3 status.
- **Ergonomics:** Hoober (UXmatters, directional), Hurff/Smashing thumb zones, LukeW touch targets, Fitts's Law, Apple/Android gesture + safe-area docs, haptics principles.
- **Motion/states:** Material 3 motion tokens + Expressive springs, Apple HIG motion, Nielsen response-time limits (<0.1s/1s/10s), NN/g skeletons, Atlassian/Carbon empty-state copy.
- **Frameworks/skill-authoring:** Anthropic Agent Skills engineering blog + platform docs (name ≤64, description ≤1024, SKILL.md ≤~500 lines/5k tokens, 3-tier progressive disclosure, scripts executed-not-loaded); cross-framework UI mapping; competitive landscape (v0, Figma Dev Mode MCP, Builder.io, frontend-design, Open Design).

### 13.D Verification plan (how to prove the build works)
End-to-end acceptance once implemented:
1. **Install & trigger:** load the skill; confirm it triggers on prompts like "design a login screen in Flutter" and "audit this screen for accessibility."
2. **Generate:** run `generate-screen` for the 5 flagship examples across the 4 frameworks; confirm all 7 states are present and platform paradigm is correctly chosen.
3. **Audit (deterministic):** run `quality-checks/validators/run_all.py` on each generated example → expect PASS / high readiness score; run it on the "bad" golden fixtures → expect correct failures.
4. **Validator tests:** `pytest quality-checks/validators/tests` → all green.
5. **Registry & CI:** registry lint (no dup/broken IDs), SKILL.md size gate, token build (css/ts/swift/kotlin/dart), link check → all green.
6. **Eval lift:** run the eval suite; confirm measurable score lift vs baseline generation without the skill.
7. **Manual platform spot-check:** verify a generated SwiftUI screen uses Liquid Glass-appropriate materials + detents, and a Compose screen uses M3 Expressive springs + WindowSizeClass — i.e., no "neither-native" hybrid.

---

*End of blueprint. Build order follows the Roadmap (§10); the validators (Phase 4) and the router/protocol (Phases 1 & 6 of AI Behaviour) are the highest-leverage components and should be prioritized.*

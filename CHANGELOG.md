# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Ionic flagship examples + eval parity — Ionic is now measured, not just documented.**
  Real Ionic 8 (@ionic/react + Capacitor) implementations of all five flagships (login,
  checkout, chat, dashboard, settings), each **100/100** on `run_all.py`, plus a committed
  naive Ionic baseline per flagship. Token discipline lives in a `.css` custom-property
  layer (the screen `.tsx` references `var(--…)`/classes only), giving a value-free
  scanned file. The eval matrix grows **20 → 25 cells** (5 flagships × 5 frameworks); mean
  lift **+77.6 pts** (100.0 vs 22.4), full-coverage gate still holds.
- **Ionic framework pack (`frameworks/ionic/`) — the 5th supported framework.** Maps
  the semantic design system to idiomatic Ionic 8 + Capacitor: **CSS-variable tokens**
  (`--ion-color-*` full 5-var sets, stepped neutrals, app spacing/radius custom
  properties) with class-based dark **palettes**; the built-in **`mode="ios|md"`**
  adaptive engine (auto-detected, override-able) as the native-feel path *without*
  `Platform.select`; components (`ion-button`/`ion-list`/`ion-modal` breakpoint sheets/
  `ion-tabs`/`ion-split-pane`) wired to targets, ARIA, and safe area
  (`viewport-fit=cover` + `--ion-safe-area-*`); all 7 states with Ionic idioms
  (`ion-skeleton-text`, `@capacitor/network` offline, `ion-toast`, Capacitor
  permissions); and `snippets/{button,list,sheet,safe-area,theme}`. Added to the
  `SKILL.md` framework router. Notes the removed `ion-virtual-scroll` (virtualize with a
  framework library) and the "test both modes" pitfall. References existing rule IDs —
  no registry change.
- **Eval harness (`eval/`) — the skill's quality claim is now a reproducible,
  CI-gated number.** Two committed corpora (with-skill = the flagship `examples/`,
  baseline = intentionally-naive "no-skill" code in `eval/baselines/`) are graded by
  the exact validators that ship, with no model call or API key. `run_eval.py` reports
  the readiness **lift** and gates CI on *every with-skill cell scoring 100 AND mean
  lift ≥ 40 pts* (current: **+77.6 pts** across **all 25 cells** — 5 flagships × 5
  frameworks — each with a committed naive baseline; `test_full_baseline_coverage` fails
  if any cell is unpaired). `trigger_test.py` guards activation (Goal G2): the
  `SKILL.md` description must carry every flagship trigger keyword and clear
  recall/specificity ≥ 0.90 on a labeled prompt corpus. Declarative scenarios in
  `eval/scenarios/*.json`; 12-test self-suite (incl. "the gate bites"); both wired into
  `.github/workflows/ci.yml`.

### Fixed
- `run_eval.py` treats an unscoreable with-skill cell (no source) as 0 so the floor
  fails cleanly instead of crashing on a `None`/`int` comparison (caught by the
  harness's own gate-bites test).

## [0.3.0] - 2026-07-01

### Added
- **Settings flagship — real code in all four v1 frameworks** (Flutter, React Native,
  SwiftUI, Jetpack Compose): platform-correct grouped + searchable list (zero-results
  empty), switches exposing a11y state, **isolated destructive zone** with multi-step
  account deletion (store policy), failed toggles that revert (no silent false success),
  light/dark/system theme switch, and responsive single-list → two-pane at ≥840dp. Each
  scores **100/100** on `run_all.py`. Completes the five-flagship set (login, chat,
  checkout, dashboard, settings) — 20 implementations across 4 frameworks.
- **Dashboard flagship — real code in all four v1 frameworks** (Flutter, React Native,
  SwiftUI, Jetpack Compose): responsive size-class reflow (1 → 2 → 3–4 columns across
  compact/medium/expanded + capped max measure), **per-widget independent states** (each
  tile loads/errors/empties on its own — no global spinner), a bar chart with
  non-color-only encoding + a screen-reader **data-table fallback**, tabular numerals,
  and cached+stale offline tiles. Each scores **100/100** on `run_all.py`.
- **Checkout flagship — real code in all four v1 frameworks** (Flutter, React Native,
  SwiftUI, Jetpack Compose): cart → address → pay → editable review → confirm, native
  Apple/Google Pay, guest checkout, always-visible honest itemized totals (tabular
  figures + locale currency), and an **idempotent payment that cannot double-charge**
  (disable+spin on tap, offline blocks the charge, declines preserve all input). All 7
  states incl. the safety-critical *processing* state; WCAG 2.2. Each scores **100/100**.
- **Chat flagship — real code in all four v1 frameworks** (Flutter, React Native,
  SwiftUI, Jetpack Compose): optimistic send lifecycle (sending→sent→delivered→read,
  failed + tap-to-retry, offline queue + auto-flush), inverted virtualized list,
  keyboard + safe-area handling, typing indicator, all 7 states, WCAG 2.2 (bubble
  contrast ≥4.5:1 both themes, icon+text status not color-only). Each scores
  **100/100** on `run_all.py`. SwiftUI guards iOS-only modifiers for cross-SDK compile.

### Fixed
- `token_lint` no longer false-flags bare `width`/`height` identifiers (e.g. a
  `double width` parameter or a `width >= 600` comparison) as off-grid spacing — the
  ambiguous keywords now require a numeric assignment (`width: 30`, `width={30}`), while
  clear styling keywords (padding/margin/gap/`EdgeInsets`) stay loose. Added a regression
  fixture + test; verified no change to the 20 flagship implementations (still 100/100).

## [0.2.0] - 2026-07-01

### Added
- **Login flagship — real code in all four v1 frameworks** (Flutter, React Native,
  SwiftUI, Jetpack Compose): token-driven, all 7 states, WCAG 2.2, keyboard-safe,
  RTL-safe, reduce-motion aware. Each scores **100/100** on `run_all.py`.
- SwiftUI token layer made cross-SDK (UIKit/AppKit `canImport` shim) so it compiles
  on both iOS and macOS toolchains.

## [0.1.0] - 2026-07-01

### Added
- Initial project scaffold (Phase 1 — Foundation).
- `SKILL.md` router with the 15-point Pre-Generation Protocol and decision routers.
- Design-system spec + DTCG-2025.10 token files (primitives, semantic, themes) and Style Dictionary build config.
- Six executable validators (`contrast_check`, `target_size_lint`, `state_coverage`, `token_lint`, `dynamic_type_check`, `rtl_check`) + `run_all` orchestrator and pytest suite.
- Rule corpus across foundations, components, interaction, system, and domain domains.
- Framework packs: Flutter, React Native, SwiftUI, Jetpack Compose.
- Industry packs: Finance/Banking, Healthcare, E-commerce/Marketplace, Social/Messaging, Productivity.
- Prompt library (15 prompts), patterns, generators, and flagship example specs.
- Quality checklists and the master review pipeline.

### Standards baseline
- Material 3 Expressive (May 2025), Apple HIG + iOS 26 Liquid Glass (June 2025),
  Android 16 window size classes, WCAG 2.2 (Oct 2023), DTCG 2025.10.

[Unreleased]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/releases/tag/v0.1.0

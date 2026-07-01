# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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

[Unreleased]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/noumanzindani/mobile-app-uiux-pro-max-skill/releases/tag/v0.1.0

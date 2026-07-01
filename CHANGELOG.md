# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://example.com/compare/v0.1.0...HEAD

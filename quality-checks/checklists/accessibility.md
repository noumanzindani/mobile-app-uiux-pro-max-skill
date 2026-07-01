# Accessibility Checklist (WCAG 2.2 AA + platform)

> Model-judged PASS/FAIL. Mechanical items (contrast, target size, RTL, fixed text)
> are also enforced by validators; the rest need judgment. Audit against **WCAG 2.2**.

1. **Text contrast** ≥ 4.5:1 (normal), ≥ 3:1 (large ≥18pt/24px or 14pt bold) — 1.4.3. → `contrast_check.py`
2. **Non-text/UI/icon/focus contrast** ≥ 3:1 — 1.4.11. → `contrast_check.py`
3. **Touch targets** ≥ 44pt (iOS) / 48dp (Android); WCAG AA floor 24×24px — 2.5.8. → `target_size_lint.py`
4. **Target spacing** ≥ 8dp between adjacent targets.
5. **No color-only meaning** — status/errors/links carry a non-color cue (icon/text/shape) — 1.4.1.
6. **Every interactive element has a non-empty accessibility label** (purpose, not icon name).
7. **Correct role/trait + state** exposed (button/link/header/selected/disabled/adjustable).
8. **Focus/reading order** matches visual order (RTL mirrored); no focus traps — 2.4.3.
9. **Dynamic content / errors announced** via live region; focus moves to modals/errors.
10. **Text scales to 200%+** with no truncation/overlap/clipping; no fixed text heights — 1.4.4/1.4.10. → `dynamic_type_check.py`
11. **Drag actions have a single-tap alternative** — 2.5.7.
12. **Reduced Motion honored** — no parallax/large motion when enabled — 2.3.3.
13. **Accessible authentication** — allow paste/password managers/passkeys; no memory/transcription puzzle — 3.3.8.
14. **Focused element never fully obscured** by sticky/overlay content — 2.4.11.
15. **Media has captions/transcripts**; no autoplay audio — 1.2.2 / 1.4.2.
16. **RTL-safe layout** — logical start/end, not hardcoded left/right — 1.3.2. → `rtl_check.py`

**Screen-reader pass:** navigate the screen with VoiceOver (iOS) and TalkBack (Android);
confirm every element is reachable, labeled, ordered, and that headings expose semantics.

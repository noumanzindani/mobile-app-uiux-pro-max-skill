# Localization & RTL (L10N)

> Externalize every string, mirror layout and directional icons in RTL, format dates/numbers/currency per locale, allow ~30% text expansion, and pseudo-localize to catch breakage before translators do.

## Table of contents
- Strings & grammar — L10N-001, L10N-005, L10N-006, L10N-013, L10N-016
- RTL & bidi — L10N-002, L10N-003, L10N-004, L10N-012, L10N-018
- Locale formatting — L10N-008, L10N-009, L10N-010, L10N-014, L10N-015
- Layout resilience & testing — L10N-007, L10N-011, L10N-017

---

### L10N-001 — Externalize all user-facing strings
- **Rule:** No user-facing string may be hardcoded in UI code; every label, message, and error MUST come from a localization resource keyed by ID (Flutter ARB/`intl`, iOS String Catalog/`Localizable`, Android `strings.xml`, RN i18n).
- **Why:** Hardcoded strings cannot be translated, reviewed, or reused, and silently ship English to every locale.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` / grep for string literals in UI widgets; verify every visible string has a key.
- **Exceptions:** Non-user-facing debug logs, developer-only diagnostics.
- **See also:** [[L10N-005]], [[L10N-013]]

### L10N-002 — Mirror layout in RTL
- **Rule:** In RTL locales (Arabic, Hebrew, Farsi, Urdu) the entire layout MUST mirror: leading/trailing (not left/right), text alignment, list disclosure, back-button and progress direction flow right-to-left. Use direction-aware primitives (`EdgeInsetsDirectional`, `start`/`end`, `MarginStart`, `layoutDirection`), never hardcoded left/right.
- **Why:** RTL users read right-to-left; an unmirrored layout is disorienting and reads as broken.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual RTL-locale sweep; grep for hardcoded `left`/`right`/`Left`/`Right` padding/alignment.
- **Exceptions:** None for RTL-supported apps.
- **See also:** [[L10N-003]], [[L10N-004]], [[A11Y-017]]

### L10N-003 — Mirror directional icons; keep non-directional icons fixed
- **Rule:** Directional glyphs (back/forward arrows, chevrons, progress, send, undo/redo) MUST mirror in RTL; non-directional and universally-oriented icons (checkmark, search, clock/time, most media play, phone, logos) MUST NOT mirror.
- **Why:** A back arrow pointing the wrong way breaks navigation; mirroring a clock or checkmark makes it wrong.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual RTL icon review; verify `autoMirrored`/`flipsForRightToLeftLayoutDirection` set correctly per icon.
- **Exceptions:** Icons whose direction is meaningful and universal (media playback conventions may vary — verify per icon).
- **See also:** [[L10N-002]], [[ICN-001]]

### L10N-004 — Drive text direction from the locale, not manually
- **Rule:** Text and layout direction MUST derive from the active locale via the framework (`Directionality`/`TextDirection`, `layoutDirection`, `Locale`), not hardcoded LTR assumptions or manual per-string flags.
- **Why:** Locale-driven direction ensures every new widget inherits correct RTL/LTR behavior automatically.
- **Platforms:** all
- **Severity:** error
- **Check:** Code review for hardcoded `TextDirection.ltr`; RTL smoke test.
- **Exceptions:** Locale-independent content (e.g., a code editor) that intentionally stays LTR.
- **See also:** [[L10N-002]], [[L10N-012]]

### L10N-005 — No string concatenation; use placeholders
- **Rule:** Never build sentences by concatenating fragments/variables. Use full templated strings with named placeholders (`"Hello, {name}"`, ICU message format) so translators control word order.
- **Why:** Word order and grammar differ across languages; concatenation produces broken, untranslatable sentences.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` / grep for `+`-joined user-facing strings; review for placeholder usage.
- **Exceptions:** Joining non-linguistic tokens (e.g., building a file path).
- **See also:** [[L10N-001]], [[L10N-006]]

### L10N-006 — Handle plurals with ICU plural rules
- **Rule:** Quantity-dependent text MUST use the platform's plural/ICU mechanism (`plural`, `Plurals`/`quantityString`, `.stringsdict`), covering the target language's categories (zero/one/two/few/many/other) — never `if (n == 1)`.
- **Why:** Languages have up to six plural categories; hardcoded English singular/plural logic mistranslates most locales.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` flags manual `== 1` pluralization; review for plural resources.
- **Exceptions:** None where quantity affects wording.
- **See also:** [[L10N-005]], [[L10N-009]]

### L10N-007 — Allow ~30% text expansion; no fixed-width text
- **Rule:** Layouts MUST accommodate translated text growing ~30% longer than English (German/Finnish/Russian) without truncation, clipping, or overlap. Avoid fixed-width buttons/labels; allow wrapping or ellipsis with tooltip.
- **Why:** Translations are frequently longer than source text; tight layouts break in production for non-English users.
- **Platforms:** all
- **Severity:** error
- **Check:** Pseudo-localization render ([[L10N-011]]); manual review of longest-locale screens.
- **Exceptions:** Numeric/fixed-format fields.
- **See also:** [[L10N-011]], [[L10N-017]], [[A11Y-026]]

### L10N-008 — Locale-aware date & time formatting
- **Rule:** Dates/times MUST format via locale-aware APIs (`intl`/`DateFormat`, `DateFormatter`, `DateUtils`/`java.time` with locale) respecting order, separators, 12/24h, and the user's calendar — never hardcoded `MM/DD/YYYY` or manual string building.
- **Why:** Date formats vary widely (11/03 is Nov 3 in the US, 11 Mar in the EU); hardcoding causes real misreadings.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` for hardcoded date patterns; review formatter usage.
- **Exceptions:** ISO-8601 for machine/API contexts.
- **See also:** [[L10N-009]], [[L10N-015]]

### L10N-009 — Locale-aware number formatting
- **Rule:** Numbers MUST use locale formatters for decimal/grouping separators and digit shaping (`1,234.56` vs `1.234,56` vs `1 234,56`) — never hardcode separators or assume ASCII digits.
- **Why:** Separator conventions invert between locales; wrong grouping changes the perceived value.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` for manual separator insertion; review number formatting.
- **Exceptions:** Developer-facing/technical numeric output.
- **See also:** [[L10N-010]], [[L10N-015]]

### L10N-010 — Locale-aware currency formatting
- **Rule:** Currency MUST format with locale-aware symbol placement, spacing, decimals, and code, and MUST carry an explicit currency (never render a bare number as money or assume `$`).
- **Why:** Symbol position and decimals differ by locale/currency; ambiguous money is a correctness and trust risk.
- **Platforms:** all
- **Severity:** error
- **Check:** `l10n_lint` / review currency formatter usage; verify currency code accompanies amounts.
- **Exceptions:** None for monetary values.
- **See also:** [[L10N-009]], [[PAY-002]]

### L10N-011 — Pseudo-localize early to catch breakage
- **Rule:** Wire up pseudo-localization (accented/expanded strings, bracketed bounds, e.g. `[!!! Ⱨéļļö Ⱳörļđ !!!]`) so truncation, clipping, concatenation, and un-externalized strings are caught before real translation.
- **Why:** Pseudo-locales surface layout and hardcoding bugs during development without waiting on translators.
- **Platforms:** all
- **Severity:** warning
- **Check:** Enable pseudo-locale build; visual review for `[…]`-untouched (hardcoded) strings and truncation.
- **Exceptions:** None — it's a cheap safety net.
- **See also:** [[L10N-001]], [[L10N-007]]

### L10N-012 — Isolate bidirectional text
- **Rule:** Mixed-direction content (an LTR name/number/URL inside RTL text, or vice versa) MUST use Unicode bidi isolation (`Bidi`/first-strong isolates, `unicodeBidi`, `<bdi>`-equivalent) so embedded runs render in the correct order.
- **Why:** Without isolation, numbers, handles, and file names scramble inside opposite-direction sentences.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual RTL test with embedded LTR tokens (phone numbers, @handles, URLs).
- **Exceptions:** Purely single-direction content.
- **See also:** [[L10N-002]], [[L10N-004]]

### L10N-013 — Don't bake text into images
- **Rule:** User-facing text MUST NOT be embedded in raster images/icons; keep it as localizable text so it can translate and scale. Provide text via strings, overlay, or SVG with swappable labels.
- **Why:** Text baked into images can't be translated, scaled for Dynamic Type, or read by screen readers.
- **Platforms:** all
- **Severity:** warning
- **Check:** Asset review for embedded text; verify strings are externalized.
- **Exceptions:** Brand logos/wordmarks.
- **See also:** [[L10N-001]], [[A11Y-025]]

### L10N-014 — Locale-aware sorting & search
- **Rule:** Sorting and comparison of user-facing text MUST use locale-aware collation (`Collator`/`localizedCompare`/ICU), not byte/ASCII ordering, so lists sort correctly per language (accents, ß, digraphs).
- **Why:** ASCII sort mis-orders accented and non-Latin text, making alphabetized lists wrong for most locales.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review sort/compare calls for locale collation.
- **Exceptions:** Machine/stable-ID ordering.
- **See also:** [[L10N-009]], [[SRCH-002]]

### L10N-015 — Respect locale numerals & calendars where appropriate
- **Rule:** Support locale digit shaping (Eastern Arabic/Devanagari numerals) and alternate calendars (Hijri, Buddhist, etc.) where the locale expects them, via platform locale settings rather than forcing Western defaults.
- **Why:** Some locales expect native numerals/calendars; forcing Western forms feels foreign and can misinform.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Manual test in a numeral/calendar-variant locale.
- **Exceptions:** Contexts standardized on Western numerals (e.g., version numbers).
- **See also:** [[L10N-008]], [[L10N-009]]

### L10N-016 — Language selection independent of region, with graceful fallback
- **Rule:** Let users pick language separately from region where feasible, and define a fallback chain (specific locale → base language → default) so a missing translation degrades gracefully instead of showing a key or crashing.
- **Why:** Users' language and region often differ; a robust fallback prevents blank or key-leaking UI.
- **Platforms:** all
- **Severity:** warning
- **Check:** Test a partially-translated locale for fallback; verify no raw keys surface.
- **Exceptions:** Single-language apps.
- **See also:** [[L10N-001]], [[SET-007]]

### L10N-017 — Wrap/truncate gracefully; test the longest locale
- **Rule:** Text containers MUST wrap or truncate gracefully (with an accessible full-text path) and be validated against the longest supported locale so no critical label is cut off.
- **Why:** Even with expansion budget, some strings overflow; graceful handling prevents lost meaning.
- **Platforms:** all
- **Severity:** warning
- **Check:** Longest-locale + pseudo-locale render review.
- **Exceptions:** Deliberately single-line ellipsized secondary text with a details path.
- **See also:** [[L10N-007]], [[L10N-011]]

### L10N-018 — Mirror gesture & animation direction in RTL
- **Rule:** Directional gestures and transitions MUST mirror in RTL — swipe-to-go-back, carousel/paging direction, slide-in transitions, and progress animations flow according to reading direction.
- **Why:** An LTR-fixed swipe/transition direction feels backwards and breaks muscle memory for RTL users.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual RTL test of swipe-back, carousels, and page transitions.
- **Exceptions:** Direction-neutral animations.
- **See also:** [[L10N-002]], [[GES-003]], [[MOT-004]]

# Home-Screen Widgets (WID)

> Purpose: Design glanceable, deep-linking home-screen widgets that respect platform size families, interaction limits, refresh budgets, theming, and accessibility.

## Contents
- [WID-001 — Keep widgets glanceable with one primary focus](#wid-001--keep-widgets-glanceable-with-one-primary-focus)
- [WID-002 — Taps deep-link into the relevant in-app context](#wid-002--taps-deep-link-into-the-relevant-in-app-context)
- [WID-003 — Support the platform widget size families](#wid-003--support-the-platform-widget-size-families)
- [WID-004 — Design within platform interaction limits](#wid-004--design-within-platform-interaction-limits)
- [WID-005 — Respect the refresh budget and show data freshness](#wid-005--respect-the-refresh-budget-and-show-data-freshness)
- [WID-006 — Be theme-aware and legible on any background](#wid-006--be-theme-aware-and-legible-on-any-background)
- [WID-007 — Provide placeholder and redacted states](#wid-007--provide-placeholder-and-redacted-states)
- [WID-008 — Make widget content accessible](#wid-008--make-widget-content-accessible)

---

### WID-001 — Keep widgets glanceable with one primary focus
- **Rule:** A widget MUST surface a single primary piece of information/action per size; do not cram a dashboard into a small widget. Prioritize the one thing the user checks most.
- **Why:** Widgets are read in a glance from the home screen; density defeats their purpose and reduces legibility.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm each widget size has one clear primary focus.
- **Exceptions:** Large/extra-large widgets may show a small, prioritized set.
- **See also:** [[WID-003]], [[WID-006]]

### WID-002 — Taps deep-link into the relevant in-app context
- **Rule:** Tapping a widget (or an element within it) MUST deep-link to the specific relevant screen/content, not merely cold-launch the app to its default home.
- **Why:** Dumping users on the home screen wastes the widget's contextual value and forces re-navigation.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — tap widget elements and confirm they open the matching in-app context.
- **Exceptions:** Single-purpose widgets whose only sensible destination is the app home.
- **See also:** [[WID-001]], [[NAV-014]]

### WID-003 — Support the platform widget size families
- **Rule:** Widgets MUST provide layouts for the platform's supported size families (iOS small/medium/large/extra-large; Android resizable grid cells) and reflow gracefully, never clipping or stretching a single fixed design.
- **Why:** A layout built for one size looks broken at others; users place widgets at varied sizes.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — add the widget at each supported size and verify the layout adapts.
- **Exceptions:** A widget deliberately offered in only one size family.
- **See also:** [[WID-001]], [[GRD-001]]

### WID-004 — Design within platform interaction limits
- **Rule:** Widgets MUST NOT rely on scrolling, text input, or rich gestures; limit interaction to taps and platform-supported interactive controls (e.g. iOS 17+ Button/Toggle, Android RemoteViews actions), with a full-app fallback for anything richer.
- **Why:** Widget runtimes are intentionally constrained; designing for unsupported interaction yields dead or broken controls.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify no scroll/keyboard reliance; interactive elements use supported APIs.
- **Exceptions:** Platform-blessed interactive widget controls within their documented limits.
- **See also:** [[WID-002]], [[PLAT-010]]

### WID-005 — Respect the refresh budget and show data freshness
- **Rule:** Widgets MUST work within the OS refresh/timeline budget (they are not real-time), show a last-updated cue when data can be stale, and degrade gracefully rather than showing wrong-but-confident values.
- **Why:** Over-requesting refreshes gets throttled by the OS; unmarked stale data misleads users who trust the glance.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — observe update cadence and confirm a freshness/last-updated cue.
- **Exceptions:** Widgets whose data is inherently static between user actions.
- **See also:** [[WID-007]], [[OFF-003]]

### WID-006 — Be theme-aware and legible on any background
- **Rule:** Widgets MUST render correctly in light/dark and accent/tint modes, use semantic tokens, and maintain ≥4.5:1 text contrast against their own background (not relying on the wallpaper).
- **Why:** Widgets sit on unpredictable wallpapers and system tints; token-driven theming keeps them legible everywhere (WCAG §1.4.3).
- **Platforms:** all
- **Severity:** error
- **Check:** contrast_check.py on widget token pairs; manual — verify light/dark/tinted rendering.
- **Exceptions:** None.
- **See also:** [[WID-008]], [[DRK-002]], [[COL-004]]

### WID-007 — Provide placeholder and redacted states
- **Rule:** Widgets MUST render a sensible placeholder/redacted state while loading and a locked/private state that hides sensitive content on the lock screen per user/platform settings.
- **Why:** A blank or spinning widget looks broken, and leaking private data on a locked device is a privacy failure.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — observe the initial placeholder and the lock-screen/redacted rendering.
- **Exceptions:** Widgets with no sensitive content may skip redaction.
- **See also:** [[WID-005]], [[STATE-002]]

### WID-008 — Make widget content accessible
- **Rule:** Widget content MUST expose accessible labels/values for screen readers, avoid encoding meaning by color alone, and remain legible when the system uses larger text sizes.
- **Why:** Widgets are part of the OS home experience and must be perceivable to assistive-tech users like any other UI (WCAG §1.1.1, §1.4.1).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — inspect the widget with VoiceOver/TalkBack and larger text settings.
- **Exceptions:** None.
- **See also:** [[WID-006]], [[A11Y-018]], [[TYP-016]]

# Navigation (NAV)

> Rules for app navigation: bottom tabs, navigation rail/drawer, responsive switching, system back/home, predictive back, state preservation, deep links, and accessible route changes.

## Contents
- [NAV-001 — Five bottom tabs maximum](#nav-001--five-bottom-tabs-maximum)
- [NAV-002 — Bottom nav is for top-level peer destinations](#nav-002--bottom-nav-is-for-top-level-peer-destinations)
- [NAV-003 — Switch to a navigation rail at ≥600dp](#nav-003--switch-to-a-navigation-rail-at-600dp)
- [NAV-004 — Overflow extra destinations, don't cram](#nav-004--overflow-extra-destinations-dont-cram)
- [NAV-005 — Preserve each tab's back stack and scroll state](#nav-005--preserve-each-tabs-back-stack-and-scroll-state)
- [NAV-006 — Never override system back](#nav-006--never-override-system-back)
- [NAV-007 — Support Android predictive back](#nav-007--support-android-predictive-back)
- [NAV-008 — Never block system home/navigation gestures](#nav-008--never-block-system-homenavigation-gestures)
- [NAV-009 — Keep primary navigation reachable](#nav-009--keep-primary-navigation-reachable)
- [NAV-010 — Selected destination is not color-only](#nav-010--selected-destination-is-not-color-only)
- [NAV-011 — Nav items meet target and spacing minimums](#nav-011--nav-items-meet-target-and-spacing-minimums)
- [NAV-012 — Respect safe-area insets on nav bars](#nav-012--respect-safe-area-insets-on-nav-bars)
- [NAV-013 — Tab badges are accessible and don't shrink targets](#nav-013--tab-badges-are-accessible-and-dont-shrink-targets)
- [NAV-014 — Re-tapping the active tab returns to root/top](#nav-014--re-tapping-the-active-tab-returns-to-roottop)
- [NAV-015 — Provide a clear, labeled back affordance](#nav-015--provide-a-clear-labeled-back-affordance)
- [NAV-016 — Use the platform-correct primary nav pattern](#nav-016--use-the-platform-correct-primary-nav-pattern)
- [NAV-017 — Top app bar / large title behaves correctly](#nav-017--top-app-bar--large-title-behaves-correctly)
- [NAV-018 — Bottom nav items show labels, not icon-only](#nav-018--bottom-nav-items-show-labels-not-icon-only)
- [NAV-019 — Deep links resolve with a sensible back stack](#nav-019--deep-links-resolve-with-a-sensible-back-stack)
- [NAV-020 — Distinguish modal presentation from push](#nav-020--distinguish-modal-presentation-from-push)
- [NAV-021 — Preserve iOS interactive edge-swipe back](#nav-021--preserve-ios-interactive-edge-swipe-back)
- [NAV-022 — Announce route changes and move focus](#nav-022--announce-route-changes-and-move-focus)
- [NAV-023 — Keep the tab set and order stable](#nav-023--keep-the-tab-set-and-order-stable)
- [NAV-024 — Don't nest tab bars within tab bars](#nav-024--dont-nest-tab-bars-within-tab-bars)

---

### NAV-001 — Five bottom tabs maximum
- **Rule:** A bottom tab/navigation bar MUST contain 3–5 destinations; never more than 5.
- **Why:** More than 5 tabs shrinks targets below usable size and dilutes focus; matches HIG and Material guidance.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — count tabs.
- **Exceptions:** None — use a "More" tab or drawer for additional destinations.
- **See also:** [[NAV-004]], [[NAV-011]]

### NAV-002 — Bottom nav is for top-level peer destinations
- **Rule:** Bottom navigation MUST switch between co-equal top-level sections, not trigger actions (share, compose) or navigate to nested/detail screens.
- **Why:** Mixing actions into nav breaks the mental model of "where am I" vs "do something."
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — each tab is a destination, not an action.
- **Exceptions:** A central FAB-style compose affordance embedded in the bar is acceptable on Android when clearly distinct.
- **See also:** [[BTN-013]], [[NAV-016]]

### NAV-003 — Switch to a navigation rail at ≥600dp
- **Rule:** At the medium window size class (≥600dp wide) the app SHOULD move primary navigation from a bottom bar to a navigation rail; at expanded widths (≥840dp) a persistent drawer or rail with list-detail is preferred.
- **Why:** Bottom bars waste horizontal space and are a long reach on tablets/foldables; rails suit wider layouts (Android window size classes).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual at ≥600dp / ≥840dp.
- **Exceptions:** iPhone-only apps that never run at ≥600dp.
- **See also:** [[GRD-002]], [[NAV-016]]

### NAV-004 — Overflow extra destinations, don't cram
- **Rule:** When there are more than 5 top-level destinations, secondary ones MUST move into a "More" tab, drawer, or overflow — never squeeze 6+ into the bottom bar.
- **Why:** Preserves target size and clarity for the most-used destinations.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[NAV-001]], [[SET-001]]

### NAV-005 — Preserve each tab's back stack and scroll state
- **Rule:** Switching away from and back to a tab MUST restore that tab's navigation stack and scroll position; tabs maintain independent back stacks.
- **Why:** Losing a tab's state on switch is a top navigation frustration.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — drill into a tab, switch, return.
- **Exceptions:** Intentional reset flows (e.g., after completing a task).
- **See also:** [[LST-013]], [[NAV-014]]

### NAV-006 — Never override system back
- **Rule:** The app MUST NOT hijack, disable, or repurpose the system Back gesture/button; back MUST reverse navigation predictably (pop the stack) and never perform a destructive or unrelated action.
- **Why:** Overriding back is disorienting and, on Android, a policy and usability violation.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — press system back on each screen.
- **Exceptions:** A confirm-to-discard prompt on unsaved input (which still ultimately allows back).
- **See also:** [[NAV-007]], [[DLG-011]]

### NAV-007 — Support Android predictive back
- **Rule:** Android apps MUST opt into and support predictive back so the system can render the back-preview animation, and MUST handle the back callback via the modern API (`OnBackPressedDispatcher`/`BackHandler`), not deprecated overrides.
- **Why:** Predictive back is the current Android 14+ standard; unsupported apps show a jarring flash instead of a preview.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual on Android 14+ with predictive back enabled.
- **Exceptions:** None.
- **See also:** [[NAV-006]], [[PLAT-002]]

### NAV-008 — Never block system home/navigation gestures
- **Rule:** UI MUST NOT place interactive controls in the system gesture zones (bottom home-indicator area, screen edges used for back) such that they conflict with home/back gestures; inset content from these areas.
- **Why:** Competing with system gestures causes accidental app exits and failed taps.
- **Platforms:** all
- **Severity:** error
- **Check:** manual on gesture-nav devices.
- **Exceptions:** Full-screen immersive experiences (media/games) that follow platform edge-protection APIs.
- **See also:** [[GES-002]], [[NAV-012]]

### NAV-009 — Keep primary navigation reachable
- **Rule:** Primary navigation MUST remain reachable; if the bottom bar hides on scroll to maximize content, it MUST reappear on scroll-up/at rest, and MUST NOT be permanently hidden without an alternative.
- **Why:** Hidden-forever navigation strands users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll down and up.
- **Exceptions:** Immersive modes with an obvious exit affordance.
- **See also:** [[NAV-002]], [[LST-015]]

### NAV-010 — Selected destination is not color-only
- **Rule:** The active tab/rail item MUST indicate selection with a non-color cue (filled icon, indicator pill, bold label) plus expose selected state to assistive tech — not color alone.
- **Why:** WCAG 1.4.1; color-only selection is invisible to color-blind users and screen readers.
- **Platforms:** all
- **Severity:** error
- **Check:** manual (desaturate) + a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[CHP-003]]

### NAV-011 — Nav items meet target and spacing minimums
- **Rule:** Each bottom-nav/rail item MUST have a hit area ≥44pt/48dp with ≥8dp between items.
- **Why:** WCAG 2.5.8; cramped nav items are the most-tapped and most mis-tapped.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[NAV-001]]

### NAV-012 — Respect safe-area insets on nav bars
- **Rule:** Bottom nav bars MUST sit above the home-indicator inset and side nav rails MUST inset for notches/cutouts; content behind translucent bars uses matching content insets.
- **Why:** Nav controls under system insets are hard to tap and can conflict with gestures.
- **Platforms:** all
- **Severity:** error
- **Check:** manual on notched/gesture-nav devices.
- **Exceptions:** None.
- **See also:** [[BSH-004]], [[NAV-008]]

### NAV-013 — Tab badges are accessible and don't shrink targets
- **Rule:** Notification badges on tabs MUST expose the true count/meaning to assistive tech and MUST NOT reduce the tab's tap target below 44pt/48dp or obscure its icon.
- **Why:** Screen-reader users need the count; badges shouldn't degrade the target.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[BDG-005]], [[BDG-006]]

### NAV-014 — Re-tapping the active tab returns to root/top
- **Rule:** Tapping the already-selected tab MUST pop that tab's stack to its root and/or scroll its content to the top (platform-standard behavior).
- **Why:** Users expect a quick way back to a section's home and to the top of a long feed.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — drill in, re-tap the active tab.
- **Exceptions:** None.
- **See also:** [[NAV-005]], [[LST-013]]

### NAV-015 — Provide a clear, labeled back affordance
- **Rule:** Pushed/detail screens MUST show an on-screen back affordance (iOS back chevron with title where appropriate, Android up arrow) with an accessible label ("Back"/"Up") in addition to the system back.
- **Why:** A visible back control aids discoverability and one-handed use; the label serves screen readers.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + manual.
- **Exceptions:** Root/top-level screens with no parent.
- **See also:** [[NAV-006]], [[A11Y-004]]

### NAV-016 — Use the platform-correct primary nav pattern
- **Rule:** Navigation MUST follow the target platform: iOS uses a bottom tab bar (and/or navigation stack with large titles); Android/M3 uses a navigation bar/rail/drawer per size class — do not ship an "neither-native" hybrid.
- **Why:** Platform-correct navigation is a core signal of a native-feeling app.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual per platform.
- **Exceptions:** Deliberately branded cross-platform apps that still respect back/home and insets.
- **See also:** [[PLAT-001]], [[NAV-003]]

### NAV-017 — Top app bar / large title behaves correctly
- **Rule:** Where used, a large title/top app bar MUST collapse to a compact title on scroll, keep its actions reachable and labeled, and respect the top safe-area; it MUST NOT overlap content or trap actions.
- **Why:** Correct app-bar collapse is idiomatic and preserves content space and reachable actions.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — scroll the screen.
- **Exceptions:** None.
- **See also:** [[NAV-016]], [[LST-011]]

### NAV-018 — Bottom nav items show labels, not icon-only
- **Rule:** Bottom-nav destinations MUST show a text label with each icon (at least for the selected item on Android's older patterns; prefer always-visible labels), never icon-only, so meaning is unambiguous.
- **Why:** Icon-only nav is frequently misinterpreted; labels aid comprehension and accessibility.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Space-constrained rails may show labels on selection/expansion, but each item still has an accessible name.
- **See also:** [[BTN-010]], [[NAV-010]]

### NAV-019 — Deep links resolve with a sensible back stack
- **Rule:** Opening a deep link (notification, universal/app link) MUST land on the correct screen and synthesize a logical back stack so system back returns the user to a coherent parent, not straight out of the app.
- **Why:** Deep links that dead-end on back feel broken and lose the user.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — open a deep link cold, then press back.
- **Exceptions:** None.
- **See also:** [[NAV-006]], [[NOTIF-003]]

### NAV-020 — Distinguish modal presentation from push
- **Rule:** Self-contained tasks (create/edit, pickers) SHOULD be presented modally (slide-up/sheet with a Cancel/Done) while hierarchical drill-downs use push; modals MUST have an explicit dismiss and not rely on back alone.
- **Why:** Correct present-vs-push semantics set the right expectation for how to exit.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[BSH-003]], [[DLG-011]]

### NAV-021 — Preserve iOS interactive edge-swipe back
- **Rule:** On iOS, pushed screens MUST keep the interactive left-edge swipe-back gesture working (don't disable it with custom back buttons or edge gestures that swallow it).
- **Why:** Edge-swipe back is a deeply ingrained iOS expectation; breaking it frustrates users.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual — swipe from the left edge.
- **Exceptions:** Screens with an intentional full-width horizontal gesture that provides an equivalent back affordance.
- **See also:** [[GES-002]], [[NAV-006]]

### NAV-022 — Announce route changes and move focus
- **Rule:** On navigation, assistive-tech focus SHOULD move to the new screen's title/first element and the screen change SHOULD be announced, so screen-reader users know the context changed.
- **Why:** Silent route changes leave non-visual users unsure where they are (WCAG 2.4.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[A11Y-007]]

### NAV-023 — Keep the tab set and order stable
- **Rule:** The set and order of primary navigation destinations MUST stay stable across sessions and not reorder dynamically based on usage; personalization belongs elsewhere.
- **Why:** Spatial memory drives fast navigation; shifting tabs forces re-learning and causes mis-taps.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual across sessions.
- **Exceptions:** User-initiated customization the user controls.
- **See also:** [[NAV-016]], [[SET-001]]

### NAV-024 — Don't nest tab bars within tab bars
- **Rule:** A screen reached from a bottom tab MUST NOT present its own second bottom tab bar; use segmented controls, top tabs, or push navigation for sub-sections instead.
- **Why:** Nested tab bars are confusing and consume scarce bottom space and reachability.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — inspect for tabs-in-tabs.
- **Exceptions:** None.
- **See also:** [[NAV-002]], [[NAV-016]]

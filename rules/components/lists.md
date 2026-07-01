# Lists & Collections (LST)

> Rules for scrolling lists, grids, and feeds: virtualization, skeletons, pull-to-refresh, pagination, swipe actions, and the full set of empty/error/offline states.

## Contents
- [LST-001 — Virtualize every scrolling collection](#lst-001--virtualize-every-scrolling-collection)
- [LST-002 — List rows meet the touch-target minimum](#lst-002--list-rows-meet-the-touch-target-minimum)
- [LST-003 — Keep rows scannable and truncate predictably](#lst-003--keep-rows-scannable-and-truncate-predictably)
- [LST-004 — One primary tap target per row](#lst-004--one-primary-tap-target-per-row)
- [LST-005 — Swipe actions need a non-gesture alternative](#lst-005--swipe-actions-need-a-non-gesture-alternative)
- [LST-006 — Provide pull-to-refresh at the top](#lst-006--provide-pull-to-refresh-at-the-top)
- [LST-007 — Paginate with a clear loading and end state](#lst-007--paginate-with-a-clear-loading-and-end-state)
- [LST-008 — Show skeletons on first load](#lst-008--show-skeletons-on-first-load)
- [LST-009 — Design the empty, error, and offline states](#lst-009--design-the-empty-error-and-offline-states)
- [LST-010 — Reserve row/media size to prevent reflow](#lst-010--reserve-rowmedia-size-to-prevent-reflow)
- [LST-011 — Sticky section headers stay accessible](#lst-011--sticky-section-headers-stay-accessible)
- [LST-012 — Expose list and item semantics](#lst-012--expose-list-and-item-semantics)
- [LST-013 — Preserve scroll position across navigation](#lst-013--preserve-scroll-position-across-navigation)
- [LST-014 — Multi-select and bulk actions with undo](#lst-014--multi-select-and-bulk-actions-with-undo)
- [LST-015 — Respect safe-area and bottom insets](#lst-015--respect-safe-area-and-bottom-insets)
- [LST-016 — Dividers/row separators meet ≥3:1 when load-bearing](#lst-016--dividersrow-separators-meet-31-when-load-bearing)
- [LST-017 — Keyed, stable items for smooth updates](#lst-017--keyed-stable-items-for-smooth-updates)
- [LST-018 — Optimistic reordering with visible rollback](#lst-018--optimistic-reordering-with-visible-rollback)

---

### LST-001 — Virtualize every scrolling collection
- **Rule:** Any list/grid that can exceed the viewport MUST use the framework's virtualization primitive: Flutter `ListView.builder`/`SliverList`, Compose `LazyColumn`/`LazyVerticalGrid`, React Native `FlashList`/`FlatList`, native `RecyclerView`/`UICollectionView`. Never map an unbounded array into eagerly-built children.
- **Why:** Eager rendering blows memory and the 16ms frame budget, causing jank and OOM on long lists.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — inspect the list widget; `grep` for eager `.map()`/`Column(children:[...spread])` over dynamic data.
- **Exceptions:** Small, fixed lists (≤ ~10 items) known to fit on screen.
- **See also:** [[PERF-002]], [[CRD-012]], [[LST-017]]

### LST-002 — List rows meet the touch-target minimum
- **Rule:** Tappable rows MUST be ≥44pt (iOS) / 48dp (Android) tall; inline row controls (checkbox, toggle, overflow) MUST each be ≥44pt/48dp and ≥8dp apart.
- **Why:** WCAG 2.5.8; short rows and crowded controls cause mis-taps.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[LST-004]]

### LST-003 — Keep rows scannable and truncate predictably
- **Rule:** Rows SHOULD lead with the most identifying content; text that can overflow MUST truncate with an ellipsis at a defined line count (typically 1–2) and MUST still expand correctly at large Dynamic Type without clipping.
- **Why:** Predictable truncation keeps rows aligned and scannable; unbounded text breaks layout.
- **Platforms:** all
- **Severity:** warning
- **Check:** `dynamic_type_check.py` for fixed heights that clip.
- **Exceptions:** None.
- **See also:** [[A11Y-008]], [[TYP-006]]

### LST-004 — One primary tap target per row
- **Rule:** A navigational row MUST expose one primary tap target with one accessible name; secondary actions (swipe, overflow) are separate, labeled targets that don't collide with the row tap.
- **Why:** Ambiguous multi-target rows fire the wrong action and confuse screen readers.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[CRD-001]], [[LST-005]]

### LST-005 — Swipe actions need a non-gesture alternative
- **Rule:** Swipe-to-delete/archive/etc. MUST also be reachable without the gesture (overflow menu, edit mode, or long-press menu) and MUST reveal a labeled action with adequate target size.
- **Why:** WCAG 2.5.7 (dragging) and 2.5.1 (pointer gestures); swipe-only actions exclude motor-impaired and screen-reader users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual + a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-012]], [[GES-001]]

### LST-006 — Provide pull-to-refresh at the top
- **Rule:** Refreshable feeds/lists MUST support pull-to-refresh anchored at the top with a visible progress indicator, and MUST also offer a non-gesture refresh (button/menu) for accessibility.
- **Why:** Pull-to-refresh is the expected mobile idiom; a non-gesture path keeps it accessible.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Static or realtime-updating lists that never require manual refresh.
- **See also:** [[LST-007]], [[GES-001]]

### LST-007 — Paginate with a clear loading and end state
- **Rule:** Infinite/paged lists MUST show a footer loading indicator while fetching the next page, surface a retry affordance on page-fetch failure, and show an explicit "end of list" cue when no more items exist.
- **Why:** Silent pagination leaves users unsure whether more content is loading, failed, or ended.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll to the end and simulate a failed page fetch.
- **Exceptions:** None.
- **See also:** [[STATE-003]], [[BDG-002]]

### LST-008 — Show skeletons on first load
- **Rule:** First load of a list MUST show skeleton placeholders that mirror row structure — not a blank screen or a single centered spinner.
- **Why:** Skeletons communicate structure and cut perceived latency.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Instant local data.
- **See also:** [[PRG-003]], [[STATE-001]]

### LST-009 — Design the empty, error, and offline states
- **Rule:** Every data-backed list MUST implement a distinct empty state (with guidance/CTA), an error state (with retry), and an offline state (showing cached data where possible) — not just the loaded state.
- **Why:** The 7-state model; "loaded-only" lists break the moment data is absent, fails, or the device is offline.
- **Platforms:** all
- **Severity:** error
- **Check:** `state_coverage.py`.
- **Exceptions:** None.
- **See also:** [[STATE-002]], [[STATE-003]], [[STATE-004]]

### LST-010 — Reserve row/media size to prevent reflow
- **Rule:** Rows with remote images/media MUST reserve final dimensions before load so the list does not reflow or shift tap targets as items arrive.
- **Why:** Layout shift causes mis-taps and disorientation while scrolling.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual on a throttled connection.
- **Exceptions:** None.
- **See also:** [[CRD-007]], [[AVT-003]]

### LST-011 — Sticky section headers stay accessible
- **Rule:** Sticky/pinned section headers MUST remain readable (≥4.5:1), not overlap row content or the safe-area, and be exposed as headers to assistive tech for section navigation.
- **Why:** Headers orient users in long lists; screen readers use them to jump between sections.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + contrast.
- **Exceptions:** None.
- **See also:** [[A11Y-007]], [[TAB-004]]

### LST-012 — Expose list and item semantics
- **Rule:** Lists MUST expose collection semantics (list role and item count/position where the platform supports it) so assistive tech can announce "item 3 of 40".
- **Why:** Positional context is essential for non-visual navigation.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-005]], [[A11Y-006]]

### LST-013 — Preserve scroll position across navigation
- **Rule:** When the user drills into a detail and returns, the list MUST restore the prior scroll position (and expanded/selection state where relevant).
- **Why:** Losing scroll position on back is a top mobile frustration, especially in long feeds.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll, open an item, go back.
- **Exceptions:** Realtime feeds that intentionally jump to newest.
- **See also:** [[NAV-005]], [[PERF-002]]

### LST-014 — Multi-select and bulk actions with undo
- **Rule:** When a list supports multi-select, entering selection mode MUST clearly indicate it, show a live selected count, keep bulk actions reachable within the thumb zone, and provide undo for destructive bulk actions.
- **Why:** Bulk actions are high-stakes; clear mode + undo prevent costly mistakes.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Lists without bulk operations.
- **See also:** [[BDG-002]], [[BTN-009]]

### LST-015 — Respect safe-area and bottom insets
- **Rule:** List content MUST inset for safe-areas and add bottom padding so the last item is not hidden behind bottom navigation, a FAB, or the home indicator; scroll content extends edge-to-edge behind translucent bars only with matching content insets.
- **Why:** Content trapped under system chrome is unreachable/unreadable.
- **Platforms:** all
- **Severity:** error
- **Check:** manual on notched/gesture-nav devices.
- **Exceptions:** None.
- **See also:** [[NAV-012]], [[BSH-005]]

### LST-016 — Dividers/row separators meet ≥3:1 when load-bearing
- **Rule:** When a divider is the only visual boundary between rows, it MUST have ≥3:1 contrast against the background; otherwise separate rows with adequate spacing instead.
- **Why:** WCAG 1.4.11; low-contrast hairlines vanish for low-vision users and in sunlight.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `contrast_check.py`.
- **Exceptions:** Rows already separated by spacing/elevation.
- **See also:** [[A11Y-002]], [[SPC-001]]

### LST-017 — Keyed, stable items for smooth updates
- **Rule:** List items MUST use stable, unique keys/IDs (not array index) so inserts, removals, and reorders animate correctly and don't recycle the wrong view state.
- **Why:** Index keys cause state bleed, flicker, and wrong-item animations on updates.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual / code review — key derivation.
- **Exceptions:** Truly static lists.
- **See also:** [[LST-001]], [[PERF-002]]

### LST-018 — Optimistic reordering with visible rollback
- **Rule:** Drag-to-reorder or optimistic list mutations MUST update the UI immediately and, on failure, visibly roll back to the prior order with an explanation.
- **Why:** Optimistic UI feels fast, but silent divergence from server state confuses users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — simulate a failed reorder.
- **Exceptions:** None.
- **See also:** [[OFF-001]], [[LST-005]]

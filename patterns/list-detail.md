# List–Detail Pattern

> Purpose: Build a browse-then-open flow (a list that opens a detail view) that adapts correctly across window size classes — stacked navigation on phones, side-by-side two-pane on tablets/foldables/desktop — while keeping selection, scroll position, and the 7 states coherent in both panes.

## Contents
- [When to use](#when-to-use)
- [Responsive fork by size class](#responsive-fork-by-size-class)
- [Anatomy](#anatomy)
- [Selection & state coordination](#selection--state-coordination)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states (per pane)](#the-7-states-per-pane)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

Any "collection → item" experience: mail, messages, settings groups, product catalog, files, contacts, tasks. If a user picks one thing from many and drills in, this is the pattern. It is the canonical **responsive** pattern and pairs directly with [navigation-patterns.md](navigation-patterns.md) at ≥840dp.

## Responsive fork by size class

Drive every decision from the window width class via breakpoint tokens ([[GRD-004]]), never device model:

```
Width class
├─ Compact  (< 600dp)  → SINGLE PANE, stacked
│     List is a full screen; tapping a row PUSHES the detail. Back returns to list. [[GRD-001]] [[NAV-005]]
├─ Medium   (600–839dp)→ SINGLE PANE (list) with optional supporting pane,
│     or two-pane if content is narrow. Prefer list + push, or list + detail if it fits. [[GRD-002]]
└─ Expanded (≥ 840dp)  → TWO-PANE side-by-side
      List rail (≈320–360dp) on the leading side + detail fills the rest.
      Selecting a row updates the detail pane in place; no push. [[GRD-003]]
```

- Re-flow live on resize / rotation / fold-unfold / split-screen — the same session may cross classes ([[GRD-008]]).
- On collapse from two-pane to single-pane while a detail is open, land the user **on the detail** with a Back to the list (don't silently drop them to the list).
- On expand from single-pane with a detail open, show both panes with that item selected.

## Anatomy

**List pane**
- Virtualized/lazy list — never build all rows eagerly ([[LST-001]], [[PERF-004]]).
- Rows ≥44pt/48dp tall, 16dp leading inset, whole row is one tap target ([[SPC-008]], [[CRD-001]]).
- Skeleton rows while loading, not a bare spinner ([[LST-002]], [[STATE-005]]).
- Optional pull-to-refresh ([[LST-003]]) and section headers ([[LST-006]]).
- Swipe actions (archive/delete) must have a **visible non-gesture alternative** (row menu / detail action) ([[LST-005]], [[GES-005]], [[A11Y-016]]).

**Detail pane**
- Its own scroll, title, and primary action.
- In two-pane mode it has **no back button** (there's nothing to pop) — instead show a placeholder when nothing is selected.
- Primary/destructive actions follow thumb-zone + confirmation rules ([[BTN-001]], [[DLG-001]]).

## Selection & state coordination

- **Selected row** is visually persistent in two-pane mode (highlight + non-color cue) and announced as `selected` ([[A11Y-006]], [[A11Y-012]]).
- Preserve list scroll offset and the selected item across resize and tab switches ([[LST-008]], [[NAV-012]]).
- Empty detail pane (two-pane, nothing chosen yet) is a **designed placeholder** ("Select an item"), not blank ([[STATE-012]]).
- List and detail can be in **different states simultaneously** (list loaded, detail loading/error) — design each independently.

## Thumb-zone layout

| Zone | Compact (stacked) | Expanded (two-pane) |
|---|---|---|
| Bottom arc | Primary detail action (Save/Reply); list FAB (New) | Detail primary action anchored bottom-right of detail pane |
| Middle | Scroll content | Both panes' content |
| Top | Title, back, overflow/destructive | Pane titles; destructive in overflow, out of the reach arc |

Destructive detail actions (Delete) stay out of the easy-reach arc and require confirmation ([[DLG-001]], [[BTN-005]]).

## The 7 states (per pane)

| State | List pane | Detail pane |
|---|---|---|
| Ideal | Rows render, selection works | Content shown, actions enabled |
| Empty | First-use/no-items empty with a CTA to create ([[STATE-002]]) | "Select an item" placeholder ([[STATE-012]]) |
| Loading | Skeleton rows ([[STATE-005]], [[LST-002]]) | Skeleton detail layout, not a spinner |
| Error | Inline retry banner atop the list; keep any cached rows ([[STATE-007]]) | Scoped error in the detail pane with Retry; list stays usable |
| Offline | Offline banner; show cached rows; disable actions needing network ([[STATE-008]], [[OFF-004]]) | Cached detail read-only; queue edits ([[OFF-001]]) |
| Success | New/updated row appears (optimistic) ([[OFF-001]]) | Save confirmation, then return/refresh ([[STATE-009]]) |
| Permission-denied | If list needs a permission (e.g., contacts), explain + Settings link ([[STATE-010]]) | Same, scoped to the feature the detail needs ([[PERM-003]]) |

## Accessibility

- List is a `list`; rows are `button`/`link` with a clear accessible name; selected rows announce `selected` ([[A11Y-005]], [[A11Y-006]]).
- Two-pane: expose both panes as distinct regions/landmarks so screen-reader users can jump between them; moving focus to the detail on selection ([[A11Y-008]], [[A11Y-017]]).
- Swipe actions duplicated as focusable buttons for switch/keyboard/VoiceOver users ([[A11Y-016]]).
- All targets ≥44pt/48dp with ≥8dp spacing; text scales to 200% without row clipping ([[A11Y-003]], [[A11Y-010]]).
- Contrast of selected-row highlight and text ≥ required ratios in both themes ([[A11Y-001]], [[DRK-004]]).

## Motion

- Compact push/pop: platform stack transition, small tier (~250ms), reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Two-pane selection: detail content cross-fades/updates in place (no full-screen push) — small, ≤200ms ([[MOT-001]]).
- Consider a shared-element/container transform from the tapped row's thumbnail to the detail header ([[MOT-003]]); provide a reduced fallback.
- List insert/remove (optimistic add, swipe delete) animates the row, not the whole list ([[MIC-001]], [[PERF-001]]).

## Applied rules

| Intent | Rule |
|---|---|
| Single column < 600dp | [[GRD-001]] |
| Rail/medium behavior | [[GRD-002]] |
| Two-pane ≥840dp | [[GRD-003]] |
| Re-flow on resize/fold | [[GRD-008]] |
| Virtualize the list | [[LST-001]], [[PERF-004]] |
| Skeleton on load | [[LST-002]], [[STATE-005]] |
| Pull-to-refresh | [[LST-003]] |
| Swipe action + visible alternative | [[LST-005]], [[A11Y-016]] |
| Preserve scroll/selection | [[LST-008]], [[NAV-012]] |
| Row = full target | [[SPC-008]], [[CRD-001]] |
| Placeholder detail pane | [[STATE-012]] |
| Destructive confirm | [[DLG-001]], [[BTN-005]] |
| Optimistic list edits | [[OFF-001]] |

## Anti-patterns

- ❌ Fixed phone layout stretched to full width on a tablet — no two-pane ([[GRD-003]]).
- ❌ Detail pane shows a back button in two-pane mode (nothing to go back to).
- ❌ Blank detail pane when nothing is selected ([[STATE-012]]).
- ❌ Losing scroll position / selection on rotate or tab return ([[LST-008]]).
- ❌ Swipe-only delete with no visible alternative ([[LST-005]], [[A11Y-016]]).
- ❌ Building all rows at once (jank on long lists) ([[LST-001]]).
- ❌ One global "loading" that blanks both panes instead of per-pane states.

## Acceptance checklist

- [ ] Layout forks Compact → single/stacked, Expanded → two-pane, via breakpoint tokens ([[GRD-001]], [[GRD-003]], [[GRD-004]]).
- [ ] Re-flows correctly on rotate/fold/split without losing the selected item ([[GRD-008]]).
- [ ] List virtualized; rows are full ≥44pt/48dp targets with skeleton loading ([[LST-001]], [[LST-002]], [[SPC-008]]).
- [ ] Selection persists and announces `selected`; scroll offset preserved ([[LST-008]], [[A11Y-006]]).
- [ ] Empty detail pane is a designed placeholder ([[STATE-012]]).
- [ ] All 7 states designed independently per pane ([[STATE-001]]).
- [ ] Swipe actions have a visible, focusable alternative ([[LST-005]], [[A11Y-016]]).
- [ ] Two panes exposed as distinct a11y regions; focus moves to detail on selection ([[A11Y-008]], [[A11Y-017]]).
- [ ] Reduce-motion fallback for push/selection transitions ([[MOT-004]]).

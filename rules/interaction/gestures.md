# Gestures (GES)

> Discoverable, forgiving touch gestures that always have a visible fallback, never fight system navigation, and respect edge-swipe reserved zones.

## Contents
- [GES-001 — No gesture-only critical paths](#ges-001--no-gesture-only-critical-paths)
- [GES-002 — Single-pointer alternative (WCAG 2.5.1)](#ges-002--single-pointer-alternative-wcag-251)
- [GES-003 — Dragging alternative (WCAG 2.5.7)](#ges-003--dragging-alternative-wcag-257)
- [GES-004 — Never override system gestures](#ges-004--never-override-system-gestures)
- [GES-005 — iOS reserved edges](#ges-005--ios-reserved-edges)
- [GES-006 — Android predictive back opt-in](#ges-006--android-predictive-back-opt-in)
- [GES-007 — Inset horizontal scrollers from edges](#ges-007--inset-horizontal-scrollers-from-edges)
- [GES-008 — Gesture handle target size](#ges-008--gesture-handle-target-size)
- [GES-009 — Swipe actions reveal & confirm](#ges-009--swipe-actions-reveal--confirm)
- [GES-010 — Long-press threshold & affordance](#ges-010--long-press-threshold--affordance)
- [GES-011 — Pinch/rotate alternatives](#ges-011--pinchrotate-alternatives)
- [GES-012 — Disambiguate nested gestures](#ges-012--disambiguate-nested-gestures)
- [GES-013 — Show gesture affordances](#ges-013--show-gesture-affordances)
- [GES-014 — Respect touch slop](#ges-014--respect-touch-slop)
- [GES-015 — Drawer edge-swipe coexists with system back](#ges-015--drawer-edge-swipe-coexists-with-system-back)
- [GES-016 — Degrade gesture animation gracefully](#ges-016--degrade-gesture-animation-gracefully)

---

### GES-001 — No gesture-only critical paths
- **Rule:** No critical or destructive action may be reachable by gesture alone. Every gesture-triggered action (delete, archive, submit, navigate) must also have a visible control (button/menu item) that performs the same thing.
- **Why:** Gestures are invisible and undiscoverable; relying on them alone strands users who don't know the gesture and blocks assistive-technology users entirely.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — for each gesture action, confirm an equivalent visible control exists.
- **Exceptions:** none
- **See also:** [[GES-002]], [[GES-003]], [[GES-013]]

### GES-002 — Single-pointer alternative (WCAG 2.5.1)
- **Rule:** Any path-based or multipoint gesture (swipe-path, two-finger, pinch, rotate) must have a single-pointer alternative that doesn't require tracing a path or using multiple fingers (e.g. tap buttons/steppers).
- **Why:** WCAG 2.2 Success Criterion 2.5.1 (Pointer Gestures) requires operation with a single pointer for users with motor impairments who cannot perform complex gestures.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify a single-pointer path exists for every path/multipoint gesture.
- **Exceptions:** Gestures essential and intrinsic to the function (e.g. a signature/drawing canvas).
- **See also:** [[GES-011]], [[A11Y-018]]

### GES-003 — Dragging alternative (WCAG 2.5.7)
- **Rule:** Any action performed by dragging (reorder, slider, swipe-to-delete, drag-to-dismiss) must have a non-dragging alternative — tap, long-press menu, stepper, or buttons.
- **Why:** WCAG 2.2 Success Criterion 2.5.7 (Dragging Movements) requires a single-tap alternative for drag operations, which are hard for tremor/limited-dexterity users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm each draggable interaction has a tap/button alternative.
- **Exceptions:** Where dragging is essential (e.g. freehand drawing).
- **See also:** [[GES-009]], [[GES-011]], [[PRG-006]]

### GES-004 — Never override system gestures
- **Rule:** Never intercept or remap system-reserved gestures: OS back swipe, home/app-switch, notification/control-center pulls, or the status bar tap-to-top. App gestures must not sit where they collide with these.
- **Why:** Overriding platform navigation breaks the user's mental model and OS-level muscle memory, and can trap users in a screen.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify no custom gesture handler consumes system navigation zones/events.
- **Exceptions:** Immersive full-screen experiences (games, media) that use the platform's sanctioned immersive/edge-protection APIs.
- **See also:** [[GES-005]], [[GES-006]], [[GES-015]]

### GES-005 — iOS reserved edges
- **Rule:** On iOS, keep custom gestures and controls clear of the reserved edges: the bottom ~34pt home-indicator area and the left screen edge (interactive pop/back swipe). Do not place edge-swipe carousels or draggable handles in these zones.
- **Why:** The bottom edge belongs to the home indicator and the left edge to system back; custom gestures there cause accidental app dismissal or navigation.
- **Platforms:** ios
- **Severity:** error
- **Check:** manual — confirm no custom gesture targets overlap the bottom 34pt or left edge-swipe region.
- **Exceptions:** Full-screen media/games using the sanctioned edge-protection/deferred-gesture APIs.
- **See also:** [[GES-004]], [[GES-007]]

### GES-006 — Android predictive back opt-in
- **Rule:** On Android 13+, predictive back is opt-in: declare support (manifest flag) and migrate to the platform back-handling APIs (`OnBackInvokedCallback`/`PredictiveBackHandler`) so the back-swipe preview animates correctly; do not consume back with a legacy blocking callback that defeats the preview.
- **Why:** Predictive back shows the user where a back gesture leads; opting out or blocking it produces a jarring, preview-less back and inconsistent system behavior.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual — verify predictive-back support is declared and back handling uses the modern callback APIs.
- **Exceptions:** none
- **See also:** [[GES-004]]

### GES-007 — Inset horizontal scrollers from edges
- **Rule:** Horizontally-scrolling content (carousels, image galleries, sliders, swipeable tabs) must be inset from the screen's system edge-swipe zones (≥16dp) or use the platform's edge-conflict resolution, so a horizontal swipe near the edge doesn't trigger system back.
- **Why:** Edge-anchored horizontal scrollers directly conflict with edge-swipe back navigation, making the carousel feel broken at its most-used region.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm horizontal scrollers are inset from or reconcile with system edge zones.
- **Exceptions:** none
- **See also:** [[GES-005]], [[GES-015]]

### GES-008 — Gesture handle target size
- **Rule:** Draggable handles, sheet grabbers, resize knobs, and swipe-action hit areas must present a touch target ≥44pt (iOS) / 48dp (Android), even if the visible glyph is smaller.
- **Why:** Small drag handles are hard to grab; an adequate hit area makes gestures reliable and meets platform touch-target minimums.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint` flags gesture handles/targets below 44pt/48dp.
- **Exceptions:** none
- **See also:** [[GES-013]], [[A11Y-007]]

### GES-009 — Swipe actions reveal & confirm
- **Rule:** Swipe-to-act on a list row must reveal labeled action buttons rather than firing on swipe alone; destructive swipe actions (delete) require an explicit confirm (tap the revealed button or a follow-up dialog) and offer Undo.
- **Why:** Blind, threshold-triggered destructive swipes cause accidental data loss; revealing buttons keeps the gesture discoverable and reversible.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm destructive swipe reveals a button/confirm and provides Undo.
- **Exceptions:** Non-destructive, easily-reversible swipes (mark read) may fire on full swipe if Undo is offered.
- **See also:** [[GES-003]], [[BDG-004]], [[STATE-018]]

### GES-010 — Long-press threshold & affordance
- **Rule:** Long-press must use a ~500ms threshold, give immediate feedback at press-and-hold (scale/haptic) so the user knows it's registering, and expose the same options through a visible affordance (overflow menu / context button).
- **Why:** Without feedback a long-press feels unresponsive; without a visible alternative the feature is undiscoverable (see [[GES-001]]).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify long-press timing, hold feedback, and a visible equivalent.
- **Exceptions:** none
- **See also:** [[GES-001]], [[HAP-003]]

### GES-011 — Pinch/rotate alternatives
- **Rule:** Pinch-to-zoom and two-finger rotate must be backed by on-screen controls (zoom +/− buttons or stepper, rotate/reset button), since they are multipoint gestures.
- **Why:** Multipoint gestures are impossible for single-pointer/assistive-tech users and hard on small screens; explicit controls make the capability universal (WCAG 2.5.1).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm zoom/rotate surfaces have on-screen control equivalents.
- **Exceptions:** Maps/photo viewers may keep pinch primary but must still expose controls.
- **See also:** [[GES-002]], [[GES-003]]

### GES-012 — Disambiguate nested gestures
- **Rule:** When gestures nest (horizontal swipe inside a vertical scroll, drag handle inside a scrollable sheet), implement direction locking / gesture arbitration so one gesture claims the drag; the wrong handler must not steal or jitter between owners.
- **Why:** Ambiguous nested gestures cause the UI to scroll when the user meant to swipe (or vice-versa), which feels broken and unpredictable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — test nested scroll/swipe regions for clean, locked disambiguation.
- **Exceptions:** none
- **See also:** [[MOT-019]], [[GES-007]]

### GES-013 — Show gesture affordances
- **Rule:** Signal available gestures with visible affordances: a sheet grabber bar, a peeking next-card edge on a carousel, a partial swipe-action reveal, or a first-run hint. Do not ship hidden gestures with zero visual cue.
- **Why:** Discoverability is the top failure of gesture UIs; a small affordance turns an invisible gesture into a learnable one.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify each primary gesture has an on-screen affordance or onboarding hint.
- **Exceptions:** Universally-understood platform gestures (vertical scroll, edge back).
- **See also:** [[GES-001]], [[MIC-006]]

### GES-014 — Respect touch slop
- **Rule:** Require a minimum movement threshold (platform touch slop, ~8dp) before a drag/swipe commits, and distinguish taps from drags, so a slightly-moved tap isn't misread as a swipe.
- **Why:** Firing gestures on the tiniest movement makes taps accidentally trigger swipes and makes the UI feel twitchy and error-prone.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm gestures use a slop threshold and separate tap vs drag intent.
- **Exceptions:** none
- **See also:** [[GES-012]]

### GES-015 — Drawer edge-swipe coexists with system back
- **Rule:** If a navigation drawer opens via left-edge swipe, it must coexist with (not override) system back: provide an in-content trigger (hamburger button) as the primary opener, and reconcile edge conflicts per platform rather than swallowing the system back gesture.
- **Why:** A drawer that hijacks the edge-back gesture breaks OS navigation; the button ensures the drawer stays reachable without gesture conflict.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify drawer has a visible opener and does not consume system back.
- **Exceptions:** none
- **See also:** [[GES-004]], [[GES-007]], [[NAV-011]]

### GES-016 — Degrade gesture animation gracefully
- **Rule:** Gesture-driven visual effects (parallax, drag-scale, rubber-banding) must honor reduce-motion and system pointer/accessibility settings, degrading to a simpler or instant response while keeping the gesture functional.
- **Why:** Motion tied to a finger can be uncomfortable for motion-sensitive users; the gesture must still work when its decoration is turned down.
- **Platforms:** all
- **Severity:** warning
- **Check:** `animation_lint` — verify gesture-driven animations branch on reduce-motion.
- **Exceptions:** none
- **See also:** [[MOT-010]], [[GES-006]]

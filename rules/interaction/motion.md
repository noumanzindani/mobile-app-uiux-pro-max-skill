# Motion & Transitions (MOT)

> Purposeful, token-driven motion: correct durations, easing, spring physics, performance budget, and a mandatory reduce-motion path for every animation.

## Contents
- [MOT-001 — Duration tiers by scope](#mot-001--duration-tiers-by-scope)
- [MOT-002 — Standard easing token](#mot-002--standard-easing-token)
- [MOT-003 — Decelerate (enter) easing](#mot-003--decelerate-enter-easing)
- [MOT-004 — Accelerate (exit) easing](#mot-004--accelerate-exit-easing)
- [MOT-005 — Emphasized easing for hero moments](#mot-005--emphasized-easing-for-hero-moments)
- [MOT-006 — Never linear except continuous loops](#mot-006--never-linear-except-continuous-loops)
- [MOT-007 — Enter/exit asymmetry](#mot-007--enterexit-asymmetry)
- [MOT-008 — Animate transform & opacity only](#mot-008--animate-transform--opacity-only)
- [MOT-009 — Hold the frame budget](#mot-009--hold-the-frame-budget)
- [MOT-010 — Reduce-motion path is mandatory](#mot-010--reduce-motion-path-is-mandatory)
- [MOT-011 — Drive motion from tokens](#mot-011--drive-motion-from-tokens)
- [MOT-012 — Spatial vs effects springs (M3 Expressive)](#mot-012--spatial-vs-effects-springs-m3-expressive)
- [MOT-013 — Map spring type to animated property](#mot-013--map-spring-type-to-animated-property)
- [MOT-014 — M3 spring schemes: standard vs expressive](#mot-014--m3-spring-schemes-standard-vs-expressive)
- [MOT-015 — iOS/SwiftUI spring presets](#mot-015--iosswiftui-spring-presets)
- [MOT-016 — Shared-element / container transform for navigation](#mot-016--shared-element--container-transform-for-navigation)
- [MOT-017 — Stagger list & grid entrances](#mot-017--stagger-list--grid-entrances)
- [MOT-018 — One motion focal point](#mot-018--one-motion-focal-point)
- [MOT-019 — Interruptible, reversible transitions](#mot-019--interruptible-reversible-transitions)
- [MOT-020 — Looping animations stay subtle](#mot-020--looping-animations-stay-subtle)

---

### MOT-001 — Duration tiers by scope
- **Rule:** Size duration to the change: micro (icon/state toggle) 100–150ms; small (chip, switch, small fade) 200–250ms; medium (card expand, sheet, dialog) 300–400ms; large (full-screen/route transition) 400–500ms. Never exceed 500ms for routine UI; only onboarding/hero/celebration moments may run >1000ms.
- **Why:** Perceived responsiveness drops sharply past ~400ms; oversized durations make an app feel sluggish, undersized ones feel abrupt and skip the eye's ability to track continuity.
- **Platforms:** all
- **Severity:** error
- **Check:** `animation_lint` flags any transition/animation `duration > 500ms` outside an onboarding/hero-flagged context.
- **Exceptions:** Deliberate hero/onboarding/empty-celebration animations, and continuous loops (see [[MOT-020]]).
- **See also:** [[MOT-007]], [[MIC-005]], [[STATE-021]]

### MOT-002 — Standard easing token
- **Rule:** Use the standard easing curve `cubic-bezier(0.2, 0, 0, 1)` for on-screen elements that both begin and end visible (e.g. reposition, resize, in-place move).
- **Why:** A fast-start/slow-settle curve reads as natural physical deceleration and is the Material default for elements that persist on screen.
- **Platforms:** all
- **Severity:** warning
- **Check:** `animation_lint` verifies easing references a named token, not an ad-hoc curve.
- **Exceptions:** Spring/physics-based motion (see [[MOT-012]]).
- **See also:** [[MOT-003]], [[MOT-004]], [[MOT-011]]

### MOT-003 — Decelerate (enter) easing
- **Rule:** For elements entering the screen, use the decelerate curve `cubic-bezier(0, 0, 0, 1)` — start at full speed, ease to rest.
- **Why:** Incoming content should arrive quickly and settle gently, drawing the eye to its final resting position without a jarring stop.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify entering elements use decelerate/enter easing and the longer side of the duration pair.
- **Exceptions:** Spring-based entrances (see [[MOT-013]]).
- **See also:** [[MOT-004]], [[MOT-007]]

### MOT-004 — Accelerate (exit) easing
- **Rule:** For elements leaving the screen, use the accelerate curve `cubic-bezier(0.3, 0, 1, 1)` — start slow, accelerate off-screen.
- **Why:** Departing content should build speed and get out of the way; it needs no gentle landing because the user's attention is moving elsewhere.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify exiting elements use accelerate/exit easing and the shorter side of the duration pair.
- **Exceptions:** Spring-based exits.
- **See also:** [[MOT-003]], [[MOT-007]]

### MOT-005 — Emphasized easing for hero moments
- **Rule:** For large, expressive transitions (full-screen route change, hero container transform), use emphasized-decelerate `cubic-bezier(0.05, 0.7, 0.1, 1)` at the 400–500ms tier.
- **Why:** The emphasized curve has a stronger, more characterful settle that suits high-attention transitions without overshooting position.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — reserve emphasized easing for large/hero transitions only.
- **Exceptions:** none
- **See also:** [[MOT-001]], [[MOT-016]]

### MOT-006 — Never linear except continuous loops
- **Rule:** Do not use linear easing for discrete UI transitions. Linear is permitted only for continuous, indefinitely-repeating motion (spinner rotation, progress marquee, looping shimmer).
- **Why:** Real objects accelerate and decelerate; linear motion reads as mechanical and lifeless for start/stop transitions, but is correct for constant-velocity loops.
- **Platforms:** all
- **Severity:** error
- **Check:** `animation_lint` flags `linear`/`Curves.linear`/`.linear` on any non-looping transition.
- **Exceptions:** Continuous loops (see [[MOT-020]]).
- **See also:** [[MOT-002]], [[MOT-020]]

### MOT-007 — Enter/exit asymmetry
- **Rule:** Enter and exit of the same element must not be symmetric: entrances decelerate and run at the full duration; exits accelerate and run ~30% shorter (e.g. enter 300ms / exit 200ms).
- **Why:** Asymmetric timing mirrors physical intuition — arrivals are deliberate and tracked, departures are quick and dismissive — and keeps dismissals feeling snappy.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm exit duration is shorter than the paired enter duration and uses accelerate easing.
- **Exceptions:** Reversible gesture-driven transitions that must mirror velocity (see [[MOT-019]]).
- **See also:** [[MOT-003]], [[MOT-004]]

### MOT-008 — Animate transform & opacity only
- **Rule:** Animate only compositor-friendly properties — `transform` (translate/scale/rotate) and `opacity`. Never animate layout-triggering properties (width, height, top/left, margin, padding, font-size) frame-by-frame.
- **Why:** Transform/opacity run on the GPU compositor; layout properties force reflow/relayout every frame, blowing the frame budget and causing jank.
- **Platforms:** all
- **Severity:** error
- **Check:** `animation_lint` flags animated width/height/margin/top/left/padding; suggests transform/scale alternatives.
- **Exceptions:** One-shot, off-thread layout animations where the framework guarantees compositing (rare); document explicitly.
- **See also:** [[MOT-009]], [[PERF-006]]

### MOT-009 — Hold the frame budget
- **Rule:** Every animation frame must complete within the display budget: 16.7ms at 60Hz, 8.3ms at 120Hz (ProMotion/high-refresh). Profile animated screens on a mid-tier device, not just the simulator.
- **Why:** A single dropped frame is a visible stutter; high-refresh displays halve the budget, so animations that pass at 60Hz can still jank at 120Hz.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — profile with the platform frame profiler (Flutter DevTools, Instruments, Perfetto/GPU profiler) and confirm no dropped frames.
- **Exceptions:** none
- **See also:** [[MOT-008]], [[PERF-006]]

### MOT-010 — Reduce-motion path is mandatory
- **Rule:** Every animation must honor the OS reduce-motion setting (`prefers-reduced-motion`, iOS Reduce Motion, Android `ANIMATOR_DURATION_SCALE`/Remove Animations). When reduced, replace movement/parallax/scale with a cross-fade or instant swap — never remove the feedback itself.
- **Why:** Vestibular disorders make large motion physically painful; WCAG 2.2 requires respecting user motion preferences while preserving the state change the animation communicated.
- **Platforms:** all
- **Severity:** error
- **Check:** `animation_lint` requires a reduce-motion branch for every registered transition; manual verification that feedback survives.
- **Exceptions:** Motion essential to the information being conveyed (WCAG 2.3.3), which must still be minimized.
- **See also:** [[MIC-009]], [[STATE-011]], [[A11Y-031]]

### MOT-011 — Drive motion from tokens
- **Rule:** Reference named motion tokens for all durations and easing (e.g. `motion.duration.medium`, `motion.easing.standard`); never hardcode literal millisecond values or raw cubic-bezier tuples in components.
- **Why:** Tokenized motion lets the whole app be retuned or themed centrally and keeps timing consistent across screens and frameworks.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint` flags literal durations/curves in component code that should reference a motion token.
- **Exceptions:** The token definitions themselves.
- **See also:** [[MOT-001]], [[MOT-002]]

### MOT-012 — Spatial vs effects springs (M3 Expressive)
- **Rule:** With Material 3 Expressive spring tokens (May 2025), classify motion as either **spatial** (position/size — may overshoot) or **effects** (color/opacity/elevation — no overshoot), and use the matching spring family. Spring tokens are defined by stiffness + damping (+ optional initial velocity), not a fixed duration.
- **Why:** Physics-based springs feel more alive and interruptible than fixed curves; overshoot is expressive for movement but wrong for color/opacity, where it would flicker.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual — confirm spatial motion uses spatial spring tokens and effects use effects spring tokens.
- **Exceptions:** Pre-Expressive targets that lack spring tokens fall back to curve easing ([[MOT-002]]).
- **See also:** [[MOT-013]], [[MOT-014]]

### MOT-013 — Map spring type to animated property
- **Rule:** Use spatial springs (overshoot allowed) for translate/scale/reposition/size; use effects springs (critically damped, no overshoot) for color, opacity, and elevation cross-fades.
- **Why:** Matching spring damping to the property prevents unwanted bounce on visual effects while keeping motion springy where overshoot reads as energy.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual — audit color/opacity animations for zero overshoot.
- **Exceptions:** none
- **See also:** [[MOT-012]]

### MOT-014 — M3 spring schemes: standard vs expressive
- **Rule:** Choose one spring scheme per product personality: **standard** (subtle, efficient, less overshoot) for utility/enterprise apps; **expressive** (more bounce/energy) for consumer/brand-forward apps. Do not mix schemes arbitrarily within one surface.
- **Why:** Motion personality is a brand decision; consistent scheme selection keeps the whole app feeling coherent rather than randomly bouncy.
- **Platforms:** android
- **Severity:** suggestion
- **Check:** manual — verify a single documented spring scheme per app/surface.
- **Exceptions:** none
- **See also:** [[MOT-012]], [[MOT-018]]

### MOT-015 — iOS/SwiftUI spring presets
- **Rule:** On iOS/SwiftUI prefer the semantic spring presets — `.smooth` (no bounce), `.snappy` (small bounce), `.bouncy` (more bounce) — or a tuned `.spring(response:dampingFraction:)`. The system default spring is `response: 0.55`, `dampingFraction: 0.825`; deviate only with intent.
- **Why:** SwiftUI springs are interruptible and velocity-aware by default; the semantic presets keep motion consistent with iOS system behavior and Liquid Glass transitions.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual — confirm springs use presets or documented response/damping, not arbitrary numbers.
- **Exceptions:** none
- **See also:** [[MOT-012]], [[MOT-019]]

### MOT-016 — Shared-element / container transform for navigation
- **Rule:** For hierarchical navigation where a source element becomes the destination (list row → detail, thumbnail → full image), use a shared-element / container transform that morphs the element, rather than an unrelated slide/fade.
- **Why:** Morphing the shared element preserves spatial continuity and context, so users understand where they came from and where they are.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify list→detail and thumbnail→media navigations use a shared-element transition.
- **Exceptions:** Non-hierarchical/peer navigation (tabs) uses a fade/x-axis shared-axis transition instead.
- **See also:** [[MOT-005]], [[GES-013]]

### MOT-017 — Stagger list & grid entrances
- **Rule:** When animating a list/grid into view, stagger items with a small per-item delay (~20–50ms) and cap the total choreography at ~300–400ms; do not delay item N by N×full-duration.
- **Why:** A gentle stagger guides the eye and adds polish, but uncapped per-item delays make long lists feel like they're loading forever.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm total stagger window stays within the medium tier regardless of item count.
- **Exceptions:** Reduce-motion: fade the whole list at once (see [[MOT-010]]).
- **See also:** [[MOT-001]], [[STATE-012]]

### MOT-018 — One motion focal point
- **Rule:** Limit a transition to a single primary motion focal point; avoid multiple large, competing animations playing simultaneously in different regions of the screen.
- **Why:** The eye can track one primary movement at a time; competing animations split attention and read as chaotic rather than choreographed.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — review that concurrent animations have a clear hierarchy (one lead, others subordinate).
- **Exceptions:** Coordinated choreography (e.g. staggered list) that reads as one gesture.
- **See also:** [[MOT-017]], [[MIC-011]]

### MOT-019 — Interruptible, reversible transitions
- **Rule:** Gesture-driven and long-running transitions must be interruptible and reversible mid-flight, preserving current velocity when the user reverses or cancels (e.g. swipe-to-dismiss that snaps back).
- **Why:** Animations that lock out input until they finish feel unresponsive and fight the user; velocity-preserving springs keep control in the user's hands.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm gesture transitions can be reversed before completion without visual snapping.
- **Exceptions:** Non-interactive confirmation animations.
- **See also:** [[MOT-015]], [[GES-012]]

### MOT-020 — Looping animations stay subtle
- **Rule:** Continuous/looping animations (spinners, shimmer, pulsing dots, recording indicator) may use linear or ease-in-out loops but must stay subtle and low-amplitude; never run an infinite high-motion, attention-grabbing loop in primary content. Provide a static fallback under reduce-motion.
- **Why:** Persistent large motion is distracting and, for some users, physically uncomfortable; loops should signal "in progress," not dominate the screen.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — audit any infinite loop for amplitude and a reduce-motion static fallback.
- **Exceptions:** Deliberate hero/celebration moments (time-boxed, not infinite).
- **See also:** [[MOT-006]], [[MOT-010]], [[STATE-011]]

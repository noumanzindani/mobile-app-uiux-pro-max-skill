# Micro-interactions (MIC)

> Small, purposeful feedback moments — each with a trigger, rules, feedback, and loops/modes (Saffer) — that confirm actions instantly without blocking the user.

## Contents
- [MIC-001 — Complete Saffer anatomy](#mic-001--complete-saffer-anatomy)
- [MIC-002 — Button press feedback](#mic-002--button-press-feedback)
- [MIC-003 — Toggle & switch travel](#mic-003--toggle--switch-travel)
- [MIC-004 — Like/favorite bounce](#mic-004--likefavorite-bounce)
- [MIC-005 — Feedback within 100ms](#mic-005--feedback-within-100ms)
- [MIC-006 — Pull-to-refresh coupling](#mic-006--pull-to-refresh-coupling)
- [MIC-007 — Input focus transition](#mic-007--input-focus-transition)
- [MIC-008 — Checkbox/radio draw](#mic-008--checkboxradio-draw)
- [MIC-009 — Token-driven & reduce-motion aware](#mic-009--token-driven--reduce-motion-aware)
- [MIC-010 — Success confirmation](#mic-010--success-confirmation)
- [MIC-011 — Never block on a micro-interaction](#mic-011--never-block-on-a-micro-interaction)
- [MIC-012 — Loops & modes for ongoing state](#mic-012--loops--modes-for-ongoing-state)

---

### MIC-001 — Complete Saffer anatomy
- **Rule:** Every micro-interaction must define all four parts of Saffer's model: a **trigger** (user or system event), **rules** (what it does and its constraints), **feedback** (visible/audible/haptic response), and **loops & modes** (repetition, timing, edge/error states). Do not ship feedback with no defined rules or an undefined error mode.
- **Why:** A complete anatomy prevents half-designed interactions that fire inconsistently, lack failure handling, or give ambiguous feedback.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — review each interactive element for all four parts, including its error/edge mode.
- **Exceptions:** none
- **See also:** [[MIC-002]], [[MIC-012]], [[STATE-020]]

### MIC-002 — Button press feedback
- **Rule:** On press, scale the button/target to 0.96–0.98 within ~100ms and (optionally) fire a light impact haptic; restore to 1.0 on release. Pair with a state-layer/overlay color change so feedback is not scale-only.
- **Why:** A small press-scale plus tactile cue makes taps feel physical and confirms the target registered the touch before the action completes.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm pressable elements show a press state within ~100ms and a non-scale visual cue.
- **Exceptions:** Full-bleed content tiles may use only an overlay/state-layer without scale.
- **See also:** [[MIC-005]], [[HAP-003]], [[MOT-001]]

### MIC-003 — Toggle & switch travel
- **Rule:** Animate switch/toggle thumb travel over ~200ms with a simultaneous track color cross-fade between off and on states; the thumb position and color must both change (not color-only).
- **Why:** A 200ms travel reads as a deliberate state flip, and dual position+color encoding keeps the state distinguishable for color-blind users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify toggle animates position + color at ~200ms.
- **Exceptions:** Reduce-motion: instant thumb snap with color cross-fade (see [[MIC-009]]).
- **See also:** [[MOT-003]], [[STATE-024]]

### MIC-004 — Like/favorite bounce
- **Rule:** For affirmative reactions (like, favorite, save), play a bouncy spring animation of 300–400ms with a brief scale overshoot (~1.1–1.2) that settles back to 1.0.
- **Why:** A little overshoot delivers a moment of delight that rewards the action and makes the state change unmistakable.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm reaction animations use a bouncy spring in the 300–400ms range.
- **Exceptions:** Reduce-motion: instant fill + optional haptic, no scale bounce.
- **See also:** [[MOT-012]], [[HAP-004]], [[MIC-009]]

### MIC-005 — Feedback within 100ms
- **Rule:** Visible feedback for any direct manipulation (tap, drag start, toggle) must begin within 100ms of the trigger, even if the underlying action is still processing.
- **Why:** Under ~100ms feels instantaneous (Nielsen); beyond it the user perceives lag and may re-tap, causing duplicate actions.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify immediate press/hover feedback is decoupled from async work completion.
- **Exceptions:** none
- **See also:** [[MIC-002]], [[STATE-005]], [[STATE-020]]

### MIC-006 — Pull-to-refresh coupling
- **Rule:** Pull-to-refresh must couple the indicator directly to drag distance (rubber-band/elastic feel), cross a clear release threshold before triggering, then show a determinate-or-indeterminate spinner until the refresh resolves.
- **Why:** Coupling the indicator to the finger makes the gesture feel physical and communicates exactly when a release will trigger a refresh.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm indicator tracks drag, has a release threshold, and resolves to a loading state.
- **Exceptions:** none
- **See also:** [[GES-013]], [[STATE-006]]

### MIC-007 — Input focus transition
- **Rule:** On text-field focus, animate the label float and border/underline emphasis over 150–200ms; on blur, reverse over a slightly shorter duration.
- **Why:** A smooth focus transition signals where input is going and which field is active without a jarring instant jump.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify focus/blur animates label and border within 150–200ms.
- **Exceptions:** Reduce-motion: instant label/border change.
- **See also:** [[MOT-007]], [[FRM-012]]

### MIC-008 — Checkbox/radio draw
- **Rule:** Animate checkbox check-mark draw and radio fill in ≤200ms with easing; the control must also change shape/fill, never color alone, to encode the selected state.
- **Why:** A short animated draw confirms the selection registered; non-color encoding keeps it perceivable without color vision.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm selection controls animate ≤200ms and use a non-color state cue.
- **Exceptions:** Reduce-motion: instant fill.
- **See also:** [[MIC-003]], [[CHP-004]]

### MIC-009 — Token-driven & reduce-motion aware
- **Rule:** Micro-interactions must reference motion tokens (duration/easing) and provide a reduce-motion variant. Under reduce-motion, drop movement/scale/overshoot but keep the feedback itself (color/opacity change, haptic, checkmark).
- **Why:** The confirmation is the point of a micro-interaction; only the decorative movement is optional. Tokens keep timing consistent app-wide.
- **Platforms:** all
- **Severity:** error
- **Check:** `animation_lint` requires a reduce-motion branch and token references for each micro-interaction.
- **Exceptions:** none
- **See also:** [[MOT-010]], [[MOT-011]], [[HAP-007]]

### MIC-010 — Success confirmation
- **Rule:** Confirm a completed action with a brief success micro-animation (checkmark draw or state morph) of 200–300ms that then settles into the resolved state; transient confirmations auto-dismiss.
- **Why:** A short, unmistakable success moment closes the interaction loop so the user knows the action landed and can move on.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify completed actions show a bounded success cue.
- **Exceptions:** none
- **See also:** [[STATE-018]], [[MOT-001]]

### MIC-011 — Never block on a micro-interaction
- **Rule:** A micro-interaction must never block input or the underlying action while it plays; the user can continue interacting and the animation is interruptible.
- **Why:** Feedback should ride alongside the task, not gate it; blocking animations make the UI feel slow and unresponsive.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm interactions remain responsive during and can interrupt micro-animations.
- **Exceptions:** none
- **See also:** [[MOT-019]], [[MOT-018]]

### MIC-012 — Loops & modes for ongoing state
- **Rule:** For continuous states (recording, playing, uploading, live), provide a subtle looping cue (pulsing dot, waveform, progress ring) that clearly reads as an ongoing mode and stops when the state ends.
- **Why:** The loops/modes leg of a micro-interaction communicates that something is still happening; a persistent, gentle cue reassures without nagging.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify ongoing states have a start, a looping in-progress cue, and a clean stop.
- **Exceptions:** Reduce-motion: static badge/label instead of a loop (see [[MOT-020]]).
- **See also:** [[MIC-001]], [[STATE-007]]

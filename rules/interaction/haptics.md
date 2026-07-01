# Haptics (HAP)

> Meaningful, intent-described tactile feedback that reinforces (never replaces) visual/audible cues and respects system haptic settings.

### HAP-001 — Meaningful events only
- **Rule:** Fire haptics only for meaningful, discrete events (action confirmed, selection changed, threshold crossed, success/error). Never emit a haptic on every scroll tick, animation frame, or continuous drag update.
- **Why:** Constant buzzing desensitizes users, drains battery, and turns a helpful signal into noise; sparse haptics keep each pulse informative.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — audit haptic call sites; flag any tied to scroll/frame/continuous callbacks.
- **Exceptions:** Discrete detents within a continuous gesture (e.g. a picker snapping to each value) may pulse per detent, not per frame.
- **See also:** [[HAP-008]], [[MIC-001]]

### HAP-002 — Never the sole feedback
- **Rule:** Haptics must never be the only feedback channel; always pair a haptic with a visible (and where relevant audible) change. Assume the device is in a case, on a table, or has haptics disabled.
- **Why:** Many users can't feel haptics (device down, motor/tactile differences, setting off); the tactile cue is reinforcement, not the message itself.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify every haptic has an accompanying visual/audible cue.
- **Exceptions:** none
- **See also:** [[HAP-007]], [[MIC-005]]

### HAP-003 — iOS impact generators
- **Rule:** On iOS use `UIImpactFeedbackGenerator` with the correct style — `.light`/`.soft` for subtle taps, `.medium` for standard confirmations, `.heavy`/`.rigid` for consequential impacts — and call `prepare()` before firing to minimize latency.
- **Why:** Using the semantic impact styles keeps tactile weight consistent with iOS system feel; `prepare()` avoids the delay of spinning up the Taptic Engine.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual — verify impact style matches event weight and generators are prepared.
- **Exceptions:** none
- **See also:** [[HAP-004]], [[HAP-005]], [[MIC-002]]

### HAP-004 — iOS selection feedback
- **Rule:** Use `UISelectionFeedbackGenerator` for discrete selection changes — picker wheels, segmented controls, steppers, snapping sliders — one crisp tick per selection change.
- **Why:** The selection generator is tuned for light, repeatable ticks that communicate "value changed" without the weight of an impact.
- **Platforms:** ios
- **Severity:** suggestion
- **Check:** manual — verify selection changes use the selection generator, not impact.
- **Exceptions:** none
- **See also:** [[HAP-001]], [[MIC-003]]

### HAP-005 — iOS notification feedback
- **Rule:** Use `UINotificationFeedbackGenerator` with `.success`, `.warning`, or `.error` for operation outcomes (payment complete, validation failed, form rejected); match the type to the actual result.
- **Why:** Notification haptics have distinct multi-part patterns users learn to associate with success vs failure, reinforcing the outcome tactilely.
- **Platforms:** ios
- **Severity:** suggestion
- **Check:** manual — verify outcome events use the matching notification type.
- **Exceptions:** none
- **See also:** [[STATE-014]], [[STATE-018]], [[HAP-008]]

### HAP-006 — Android semantic constants
- **Rule:** On Android use semantic `HapticFeedbackConstants` that describe intent — e.g. `CONFIRM`, `REJECT`, `LONG_PRESS`, `CLOCK_TICK`, `GESTURE_START/END`, `SEGMENT_TICK` — rather than hardcoding raw `Vibrator`/`VibrationEffect` timing patterns for UI feedback.
- **Why:** Semantic constants let the OS and device tune the actual waveform per hardware and honor user settings; raw patterns feel wrong across devices and ignore accessibility preferences.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual — flag raw `Vibrator`/`VibrationEffect` used for standard UI feedback in place of `performHapticFeedback` constants.
- **Exceptions:** Purpose-built custom haptic experiences (games, custom waveforms) where semantic constants can't express the intent.
- **See also:** [[HAP-001]], [[HAP-007]]

### HAP-007 — Respect system settings & accessibility
- **Rule:** Haptics must respect the OS haptic/system-feedback setting and be fully optional — the app must remain completely usable with haptics off. Do not re-enable haptics the user disabled, and treat them as degradable like motion.
- **Why:** Haptics are an accessibility and comfort preference; overriding the user's choice is intrusive and, for some, physically unpleasant.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify haptics honor system settings and nothing breaks when disabled.
- **Exceptions:** none
- **See also:** [[HAP-002]], [[MOT-010]]

### HAP-008 — Match intensity to severity
- **Rule:** Scale haptic strength to event importance: light/selection ticks for routine feedback; reserve heavy impacts and error/warning notification haptics for consequential or destructive actions (delete, payment failure, irreversible confirm).
- **Why:** A calibrated intensity ladder makes tactile feedback meaningful — a strong buzz signals "pay attention" only when it truly matters.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — review that heavy/error haptics are reserved for high-severity events.
- **Exceptions:** none
- **See also:** [[HAP-001]], [[HAP-005]]

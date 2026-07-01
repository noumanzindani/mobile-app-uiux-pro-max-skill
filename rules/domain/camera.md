# Camera & Scanning (CAM)

> Purpose: Make capture obvious and forgiving — a clear shutter, in-context permission priming, result confirmation with retake, torch/flip controls, and scanning guidance overlays.

## Contents
- [CAM-001 — Provide a clear, thumb-reachable capture control](#cam-001--provide-a-clear-thumb-reachable-capture-control)
- [CAM-002 — Prime camera permission before the OS prompt](#cam-002--prime-camera-permission-before-the-os-prompt)
- [CAM-003 — Confirm the result with retake and use options](#cam-003--confirm-the-result-with-retake-and-use-options)
- [CAM-004 — Provide torch/flash and camera-flip controls](#cam-004--provide-torchflash-and-camera-flip-controls)
- [CAM-005 — Show a scanning guidance overlay](#cam-005--show-a-scanning-guidance-overlay)
- [CAM-006 — Handle camera-permission-denied with a Settings path](#cam-006--handle-camera-permission-denied-with-a-settings-path)
- [CAM-007 — Give capture feedback and block double-capture](#cam-007--give-capture-feedback-and-block-double-capture)
- [CAM-008 — Respect safe areas and gesture edges in the camera UI](#cam-008--respect-safe-areas-and-gesture-edges-in-the-camera-ui)
- [CAM-009 — Label camera controls and announce outcomes](#cam-009--label-camera-controls-and-announce-outcomes)
- [CAM-010 — Provide loading, processing, and hardware-error states](#cam-010--provide-loading-processing-and-hardware-error-states)

---

### CAM-001 — Provide a clear, thumb-reachable capture control
- **Rule:** The shutter/capture button MUST be the largest, most prominent control (≥64pt recommended), centered in the bottom thumb zone, and visually unambiguous.
- **Why:** Capture is the primary action; a small or ambiguous shutter causes missed shots and fumbling.
- **Platforms:** all
- **Severity:** error
- **Check:** target_size_lint.py on the shutter; manual — confirm bottom-center prominence.
- **Exceptions:** Continuous scanning modes that capture automatically on detection.
- **See also:** [[CAM-007]], [[BTN-001]]

### CAM-002 — Prime camera permission before the OS prompt
- **Rule:** Explain why the camera is needed in-context BEFORE triggering the OS permission dialog, tied to the user's action (e.g. 'To scan the code, allow camera access').
- **Why:** Value-first priming raises grant rates and avoids permanently burning the one-shot OS prompt on a confused 'Don't Allow'.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm a rationale precedes the OS camera dialog.
- **Exceptions:** None.
- **See also:** [[CAM-006]], [[PERM-002]], [[CAM-010]]

### CAM-003 — Confirm the result with retake and use options
- **Rule:** After capture, show the photo/scan for review with clear 'Retake' and 'Use'/'Confirm' actions before committing it to the flow.
- **Why:** A confirmation step catches blurry or wrong shots and prevents forcing the user to restart a whole flow.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — capture and verify a retake/use review step.
- **Exceptions:** Burst/continuous capture or scanners that intentionally auto-accept a valid read.
- **See also:** [[CAM-001]], [[CAM-005]]

### CAM-004 — Provide torch/flash and camera-flip controls
- **Rule:** Offer clearly-labeled flash/torch (on/off/auto) and front/back flip controls, positioned away from the shutter to avoid mis-taps.
- **Why:** Low light and selfie/rear switching are core capture needs; mislabeled or crowded controls cause errors.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on controls; manual — verify labels and separation from shutter.
- **Exceptions:** Devices/modes without a torch or second camera.
- **See also:** [[CAM-001]], [[CAM-009]]

### CAM-005 — Show a scanning guidance overlay
- **Rule:** For QR/barcode/document scanning, show a framing overlay with a target reticle and hint text ('Center the code'), plus dynamic feedback on detection/alignment.
- **Why:** Guidance dramatically improves first-try scan success and reduces user frustration.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enter scan mode and confirm framing overlay + hint + detection feedback.
- **Exceptions:** Free-form photo capture with no scan target.
- **See also:** [[CAM-003]], [[CAM-009]]

### CAM-006 — Handle camera-permission-denied with a Settings path
- **Rule:** When camera permission is denied, show an explanatory state (not a black screen) and a one-tap deep link to the OS Settings, plus any non-camera alternative (e.g. upload from library).
- **Why:** Once denied, only Settings can re-grant; a black screen reads as a crash.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — deny camera and confirm the explained state + Settings link.
- **Exceptions:** None.
- **See also:** [[CAM-002]], [[PERM-004]]

### CAM-007 — Give capture feedback and block double-capture
- **Rule:** Capture MUST give immediate feedback (shutter animation and/or haptic) and disable the shutter while the frame is processing so a second tap cannot fire.
- **Why:** Feedback confirms the shot landed; disabling during processing prevents duplicate or corrupted captures.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — capture and observe feedback + disabled shutter during processing.
- **Exceptions:** Burst mode.
- **See also:** [[CAM-001]], [[HAP-002]], [[STATE-005]]

### CAM-008 — Respect safe areas and gesture edges in the camera UI
- **Rule:** Camera controls MUST inset from notches/cutouts and the home-indicator/gesture zone so controls are not clipped and system gestures do not conflict with capture.
- **Why:** Full-bleed camera previews easily push controls under system UI or gesture zones, causing mis-taps.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify controls clear safe areas on notched/gesture-nav devices.
- **Exceptions:** The preview canvas itself is intentionally full-bleed.
- **See also:** [[CAM-004]], [[SPC-011]], [[GES-006]]

### CAM-009 — Label camera controls and announce outcomes
- **Rule:** All camera controls MUST have accessible labels, and capture/scan success or failure MUST be announced (haptic + live region/text), not conveyed by the preview alone.
- **Why:** Icon-only camera controls and silent success are inaccessible to blind/low-vision users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — operate capture and read outcomes via VoiceOver/TalkBack.
- **Exceptions:** None.
- **See also:** [[CAM-005]], [[A11Y-012]]

### CAM-010 — Provide loading, processing, and hardware-error states
- **Rule:** The camera surface MUST handle initializing/loading, post-capture processing, and unavailable-hardware/error states (e.g. camera in use, no camera) with clear messaging.
- **Why:** Camera init and hardware conflicts are common; a frozen preview with no state looks broken.
- **Platforms:** all
- **Severity:** warning
- **Check:** state_coverage.py; manual — occupy the camera from another app and observe the error state.
- **Exceptions:** None.
- **See also:** [[CAM-006]], [[STATE-002]], [[STATE-003]]

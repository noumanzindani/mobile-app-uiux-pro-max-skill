# Animation Review

**Purpose:** Review a screen's motion for correctness — durations, easing/springs, purpose, performance, and (critically) a reduce-motion fallback — and return timing findings with fixes.

**Inputs:**
- *Required:* **The screen / component** — source code (animation code must be visible) and/or a screen recording.
- *Required:* **Framework** (drives the expected animation primitive — Flutter `AnimationController`/implicit, RN Reanimated 3, SwiftUI `withAnimation`/springs/`PhaseAnimator`, Compose `animate*AsState`/springs).
- **Platform target** — sets the motion vocabulary (iOS springs / curves vs Material 3 Expressive spring tokens).
- **Industry** — optional; e.g. healthcare mandates calm, low-arousal motion.

**Procedure:**
1. Load the motion rule set — `rules/interaction/motion.md` (durations: micro 100ms / small 200–250 / medium 300–400 / large 400–500; never >500ms routine) and `rules/interaction/micro-interactions.md` (press scale 0.96–0.98 + haptic, etc.).
2. Load the motion system spec — `design-system/motion-system.md` — and confirm durations/easing reference **motion tokens**, not magic numbers.
3. Load the framework's animation idioms — `frameworks/<framework>/components.md` (animation section) — to confirm the correct primitive and that only `transform`/`opacity` are animated (per `rules/system/performance.md`, hold the 16ms frame budget).
4. Load platform motion vocabulary — `rules/system/platform-conventions.md` — and run the **Motion router** (Android post-May-2025 → M3 spring tokens; iOS → SwiftUI springs / curve easing).
5. **Verify the reduce-motion path exists** for every non-essential animation (respects `prefers-reduced-motion` / `UIAccessibility.isReduceMotionEnabled` / platform equivalent) — this is mandatory, not optional.
6. Check haptics — `rules/interaction/haptics.md` — meaningful events only, never the sole feedback.
7. Reason through `quality-checks/checklists/motion.md`.

**Output format:** **Motion findings**, each: rule ID · location · property animated · measured/declared duration & easing · verdict (correct / too long / wrong curve / not token-bound / animates layout not transform) · fix.
- A **reduce-motion audit** (per animation: fallback present? adequate?).
- A **performance note** (any animation touching layout/paint instead of transform/opacity).
- A **token-binding note** (durations/easing that should reference `design-system/motion-system.md` tokens).
- A one-line **motion verdict**.

**Self-check:** Run `quality-checks/validators/token_lint.py` to catch hardcoded duration/easing magic values; confirm **every** non-essential animation has a documented reduce-motion fallback (fail the review if any is missing); confirm every finding cites a rule ID and a target duration/easing. Reason through `quality-checks/checklists/motion.md` before returning.

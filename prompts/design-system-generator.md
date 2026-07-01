# Design System Generator

**Purpose:** Emit a complete, DTCG-2025.10-compliant token set (primitive → semantic → component) with light/dark/high-contrast themes and a Style Dictionary build config, ready to feed every other prompt.

**Inputs:**
- *Required:* **Brand seed** — a seed/brand color (hex), or a small brand palette, or a Figma/reference link.
- **Platforms/frameworks** to build outputs for (css · ts · swift · kotlin · dart). Default: all five.
- **Aesthetic direction** (playful, calm/clinical, premium/trust, dense/pro) — steers type scale, radius, and motion personality; avoids default-font sameness.
- **Density** (comfortable default vs compact) and **industry** — optional; industry pulls domain constraints (e.g. finance tabular numerals, healthcare large-type legibility).

**Procedure:**
1. Run the aesthetic + platform points of the **Pre-Generation Protocol** (`SKILL.md` §6.1): declare the aesthetic direction and target platforms explicitly so the output isn't generic.
2. Load the token architecture spec — `design-system/token-spec.md` (three-tier tiering, naming `[category]-[concept]-[property]-[variant]-[state]`, "semantics enable theming"), plus `design-system/type-scale.md`, `design-system/spacing-system.md`, and `design-system/motion-system.md`.
3. Generate **primitives** — `design-system/tokens/primitives/` (color ramp from the seed via a Material-color-utilities-style tonal approach, dimension/space scale on the 4/8pt grid, typography, shadow, motion). Named by value (`color.blue.500`, `space.4`).
4. Generate **semantics** — `design-system/tokens/semantic/` (color roles like `color.action.primary`, `color.surface`; spacing, elevation, radius, motion). Components will reference these only, never primitives (per `rules/foundations/color.md` COL rule).
5. Generate **component tokens** — `design-system/tokens/components/` (e.g. `button.json`, `card.json`, `input.json`) scoped as `button.primary.bg`, etc.
6. Generate **themes** — `design-system/tokens/themes/light.json`, `dark.json`, `high-contrast.json` — remapping semantic roles per theme (dark surfaces not pure #000; elevation overlays in dark, per `rules/system/dark-mode.md`).
7. Emit `$metadata.json`, `$themes.json`, and the **Style Dictionary v4** config at `design-system/build/config.json` producing the requested platform outputs.
8. Verify contrast of every semantic foreground/background pairing in each theme against `rules/system/accessibility.md` before finalizing.

**Output format:**
- The **DTCG JSON token files** (primitives / semantic / components / themes + `$metadata.json` + `$themes.json`).
- The **Style Dictionary `config.json`** and the list of generated platform outputs (css/ts/swift/kotlin/dart).
- A **theme matrix** (semantic role → light / dark / high-contrast value) with the computed contrast ratio per pairing.
- A short **usage note**: how each target framework consumes these tokens (link `frameworks/<framework>/tokens.md`).

**Self-check:** Run `quality-checks/validators/contrast_check.py` over the semantic color pairings in **all three themes** (fail on any text pair <4.5:1 or UI pair <3:1) and `token_lint.py` to confirm the token files are internally consistent (semantics reference primitives; components reference semantics; no orphan magic values). Confirm the Style Dictionary `config.json` build succeeds and reason through `quality-checks/checklists/contrast.md` and `typography.md`.

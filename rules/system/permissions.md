# Permissions (PERM)

> Request permissions just-in-time with value-first priming, ask for the minimum scope, never block core features on optional grants, and handle denial with a settings deep-link.

## Table of contents
- Timing & priming — PERM-001, PERM-002, PERM-012
- Scope & honesty — PERM-005, PERM-006, PERM-008, PERM-010
- Denial & recovery — PERM-003, PERM-004, PERM-007, PERM-009, PERM-011

---

### PERM-001 — Request just-in-time, at the point of need
- **Rule:** Request each permission at the moment the user invokes the feature that needs it (camera when they tap the shutter, location when they tap "find near me") — never a batch of prompts on first launch.
- **Why:** In-context requests have obvious purpose and far higher grant rates; upfront prompt-walls get reflexively denied.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual first-run: verify no permission dialogs before the relevant feature is used.
- **Exceptions:** A permission genuinely required before any use (rare) with a clear onboarding rationale.
- **See also:** [[PERM-002]], [[NOTIF-002]]

### PERM-002 — Value-first priming before the system dialog
- **Rule:** Precede each OS permission dialog with an in-app priming screen that states the concrete benefit and lets the user opt in (or "Not now") before the un-repeatable system prompt fires.
- **Why:** The OS prompt can typically be shown only once; priming preserves a second chance and improves acceptance.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual flow: benefit explanation appears before every system dialog.
- **Exceptions:** OS flows that don't allow a pre-prompt.
- **See also:** [[PERM-001]], [[NOTIF-001]]

### PERM-003 — Never block core functionality on optional permissions
- **Rule:** Core flows MUST remain usable when an optional permission is denied; provide a manual fallback (type an address instead of GPS, pick from library instead of camera, paste instead of contacts).
- **Why:** Holding core features hostage to optional grants frustrates users and triggers store rejection for coercive permission gating.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: deny each optional permission → verify the feature still has a usable fallback.
- **Exceptions:** Permissions truly essential to a feature's core purpose (e.g., camera for a camera app).
- **See also:** [[PERM-009]], [[PERM-004]]

### PERM-004 — Handle denial: explain and deep-link to Settings
- **Rule:** When a needed permission is denied/blocked, show a clear explanation and a button that deep-links to the app's OS Settings page (`openAppSettings`/`UIApplication.openSettingsURLString`/`ACTION_APPLICATION_DETAILS_SETTINGS`) — do not dead-end or just silently fail.
- **Why:** After denial the app can't re-prompt directly, so guiding the user to Settings is the only recovery path.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: deny → verify explanatory state with a working Settings deep-link.
- **Exceptions:** None where the feature needs the permission.
- **See also:** [[PERM-007]], [[PERM-011]], [[STATE-006]]

### PERM-005 — Request the minimum scope
- **Rule:** Ask for the narrowest permission that satisfies the feature: When-In-Use over Always location, approximate over precise where sufficient, limited/selected photo access over full library, specific media types over broad storage.
- **Why:** Least-privilege requests build trust, grant more easily, and are required by store privacy policies.
- **Platforms:** all
- **Severity:** error
- **Check:** Review requested scopes vs feature need; verify no over-broad permissions.
- **Exceptions:** Features that provably require the broader scope, justified in the manifest.
- **See also:** [[PERM-008]], [[PERM-010]]

### PERM-006 — Accurate, honest purpose strings
- **Rule:** Usage-description strings (iOS `Info.plist NS*UsageDescription`, Android manifest/rationale) MUST accurately and specifically describe why the permission is used, and match actual behavior and the store data-use declaration.
- **Why:** Vague or dishonest purpose strings cause store rejection and mislead users about data use.
- **Platforms:** all
- **Severity:** error
- **Check:** Review purpose strings for specificity; cross-check against store data-safety/privacy declarations.
- **Exceptions:** None.
- **See also:** [[PERM-005]], [[PERM-010]]

### PERM-007 — Don't re-prompt after permanent denial
- **Rule:** After a permanent denial, do not attempt to re-fire the system dialog (the OS suppresses it); route the user to Settings instead and only re-surface the ask when they actively re-engage the feature.
- **Why:** Repeated no-op prompts frustrate users and waste the interaction; Settings is the only real path back.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: permanently deny → verify app routes to Settings, not a broken re-prompt.
- **Exceptions:** None.
- **See also:** [[PERM-004]], [[NOTIF-009]]

### PERM-008 — Handle partial / limited grants
- **Rule:** Support partial grants gracefully — iOS limited photo selection, approximate-only location, one-time grants — degrading features to what's permitted and offering an in-context path to expand access if needed.
- **Why:** Modern OSes commonly return partial access; assuming full access breaks features and confuses users.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: grant limited/approximate/one-time → verify feature adapts without errors.
- **Exceptions:** Features unaffected by partial scopes.
- **See also:** [[PERM-005]], [[PERM-009]]

### PERM-009 — Degrade gracefully with a permission-denied state
- **Rule:** Feature-detect permission status and render an explicit permission-denied state ([[STATE-006]]) explaining what's unavailable and how to enable it — never crash, spin forever, or show an empty screen when a permission is missing.
- **Why:** A clear denied state keeps the app trustworthy and gives the user a recovery path.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: enter each permission-gated screen while denied → verify a proper denied state.
- **Exceptions:** None.
- **See also:** [[PERM-003]], [[PERM-004]], [[STATE-006]]

### PERM-010 — Request only permissions actually used
- **Rule:** The app MUST declare/request only permissions its shipped features actually use; remove speculative, leftover, or transitively-pulled-in permissions from dependencies.
- **Why:** Unused permissions raise privacy red flags, hurt store review, and lower user trust.
- **Platforms:** all
- **Severity:** error
- **Check:** Audit manifest/Info.plist against actual feature usage; review SDK-added permissions.
- **Exceptions:** None.
- **See also:** [[PERM-005]], [[PERM-006]]

### PERM-011 — Provide in-app access to change permissions
- **Rule:** Surface current permission status and a path to change it within app settings (deep-linking to OS Settings), so users can review and revoke grants without hunting through the OS.
- **Why:** Transparent, reachable permission controls respect user autonomy and reduce support burden.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Verify settings exposes permission status + Settings deep-link.
- **Exceptions:** Apps using no runtime permissions.
- **See also:** [[PERM-004]], [[SET-008]]

### PERM-012 — Sequence multiple permissions; never stack dialogs
- **Rule:** When several permissions are needed, request them one at a time in context; never fire multiple system dialogs simultaneously or back-to-back at launch.
- **Why:** Dialog stacking overwhelms users into blanket denial and looks predatory.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: verify no permission-prompt pile-up; each is spaced by context.
- **Exceptions:** None.
- **See also:** [[PERM-001]], [[PERM-002]]

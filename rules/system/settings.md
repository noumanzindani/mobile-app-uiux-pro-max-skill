# Settings (SET)

> Group settings logically, make them searchable when numerous, isolate destructive actions, and guarantee account deletion is reachable in-app per store policy.

## Table of contents
- Structure & findability — SET-001, SET-002, SET-005
- Controls present — SET-006, SET-007, SET-008, SET-009
- Safety & persistence — SET-003, SET-004, SET-010

---

### SET-001 — Group settings into logical, labeled sections
- **Rule:** Settings MUST be organized into clearly-labeled groups (Account, Notifications, Privacy, Appearance, About) rather than a flat undifferentiated list; related controls sit together under section headers.
- **Why:** Grouping matches users' mental model and makes options findable; a flat wall of toggles is overwhelming.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review settings IA for section grouping and headers.
- **Exceptions:** Apps with only a handful of settings.
- **See also:** [[SET-002]], [[PLAT-002]]

### SET-002 — Make settings searchable when numerous
- **Rule:** When settings exceed roughly one to two screens, provide in-app search/filter so users can jump directly to a setting by name.
- **Why:** Deep settings trees are hard to navigate; search is the fastest path to a specific option.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Verify a search field exists for large settings sets.
- **Exceptions:** Small settings surfaces.
- **See also:** [[SET-001]], [[SRCH-001]]

### SET-003 — Isolate and confirm destructive actions
- **Rule:** Destructive actions (sign out, clear data, delete account) MUST be visually separated (bottom of the list, warning styling) and require explicit confirmation; never place them adjacent to routine toggles where they can be hit by accident.
- **Why:** Accidental destructive taps cause irreversible data loss and account lockout.
- **Platforms:** all
- **Severity:** error
- **Check:** Review placement/styling of destructive actions; verify a confirmation step.
- **Exceptions:** Trivially reversible actions.
- **See also:** [[SET-004]], [[DLG-003]]

### SET-004 — Account deletion is reachable in-app
- **Rule:** If the app supports account creation, it MUST provide an in-app path to delete the account and associated data (Apple App Store Guideline 5.1.1(v) and Google Play policy), not just a website or support email.
- **Why:** Both stores require in-app account deletion; its absence is a hard rejection/enforcement blocker.
- **Platforms:** all
- **Severity:** error
- **Check:** Verify a discoverable in-app "Delete account" flow exists and completes.
- **Exceptions:** Apps with no account system.
- **See also:** [[SET-003]], [[SET-009]]

### SET-005 — Show current values and apply changes consistently
- **Rule:** Each setting MUST display its current value/state inline, and the app MUST use one consistent apply model (immediate-apply preferred on mobile; if explicit save is used, apply it uniformly and warn on unsaved changes).
- **Why:** Hidden current values and mixed apply/save behavior confuse users about what state they're in.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review that toggles/rows show current state; verify a single apply model.
- **Exceptions:** Multi-field forms that legitimately need an explicit save.
- **See also:** [[SET-001]], [[FRM-005]]

### SET-006 — Provide an appearance / theme control
- **Rule:** Settings MUST include an appearance control offering Light / Dark / System, persisting the choice.
- **Why:** Users expect direct control over theme; it's a baseline personalization option.
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify a Light/Dark/System control that persists.
- **Exceptions:** Single-theme brand apps with justification.
- **See also:** [[DRK-008]], [[SET-010]]

### SET-007 — Provide language / region control
- **Rule:** Settings MUST let users choose the app language (and region where relevant) independently of switching the whole device, with a graceful fallback for missing translations.
- **Why:** Users often want the app in a different language than their device; in-app choice serves multilingual users.
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify an in-app language selector that takes effect.
- **Exceptions:** Single-language apps.
- **See also:** [[L10N-016]], [[SET-010]]

### SET-008 — Expose notification & privacy controls with OS deep-links
- **Rule:** Settings MUST provide notification and privacy/permission controls, deep-linking to OS settings where the actual control lives (notification channels, permission grants).
- **Why:** Centralized, discoverable privacy/notification controls reduce blanket opt-outs and support requests.
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify notification + privacy sections with working OS deep-links.
- **Exceptions:** Apps with no notifications or runtime permissions.
- **See also:** [[NOTIF-006]], [[PERM-011]]

### SET-009 — Include About / legal / help
- **Rule:** Settings MUST include an About section with app version, Terms of Service, Privacy Policy, open-source licenses, and a consistent path to help/support.
- **Why:** Legal links and version info are store/compliance expectations and essential for support and consistent help ([[A11Y-037]]).
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify version, ToS, privacy policy, licenses, and support entry are present.
- **Exceptions:** None for published apps.
- **See also:** [[A11Y-037]], [[SET-004]]

### SET-010 — Persist settings reliably and sync per account
- **Rule:** Setting changes MUST persist across restarts and, where the app has accounts, sync per-account across devices; a changed setting must never silently revert.
- **Why:** Settings that don't stick or don't travel with the account feel broken and erode trust.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: change a setting, restart / switch device → verify it persists/syncs.
- **Exceptions:** Device-specific settings that intentionally stay local.
- **See also:** [[SET-005]], [[OFF-009]]

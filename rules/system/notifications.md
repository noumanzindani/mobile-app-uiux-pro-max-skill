# Notifications (NOTIF)

> Earn the notification permission with value-first priming, organize by channels/categories, deep-link every notification to its context, and respect quiet hours and interruption levels.

## Table of contents
- Permission & timing — NOTIF-001, NOTIF-002, NOTIF-009
- Structure & routing — NOTIF-003, NOTIF-004, NOTIF-008, NOTIF-011
- Respect & controls — NOTIF-005, NOTIF-006, NOTIF-007, NOTIF-010, NOTIF-012

---

### NOTIF-001 — Prime before requesting the OS permission
- **Rule:** Show a custom value-first pre-permission screen explaining the benefit before triggering the system notification dialog. Only call the OS prompt after the user opts in to the pre-prompt.
- **Why:** The OS dialog can be shown once; priming first raises acceptance and preserves the ability to ask later without a permanent denial.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual first-run flow; verify no cold system prompt on launch.
- **Exceptions:** OS-required flows where priming is impossible.
- **See also:** [[NOTIF-002]], [[PERM-002]]

### NOTIF-002 — Request at a contextually relevant moment
- **Rule:** Ask for notification permission at a moment where its value is obvious (e.g., after placing an order → "Get delivery updates?"), not on first launch before any value is established.
- **Why:** Context-tied requests convert far better and feel respectful rather than intrusive.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of where the request fires relative to user value.
- **Exceptions:** Apps whose core purpose is notifications (e.g., alerting) may ask during onboarding with clear value.
- **See also:** [[NOTIF-001]], [[PERM-001]]

### NOTIF-003 — Organize with channels (Android) / categories (iOS)
- **Rule:** Notifications MUST be grouped into channels (Android 8+, mandatory) / categories & interruption levels (iOS) by type (transactional, social, promotional) so users can tune each independently rather than all-or-nothing.
- **Why:** Granular channels let users keep the notifications they want and mute the rest instead of disabling everything.
- **Platforms:** all
- **Severity:** error
- **Check:** Code review for channel/category definitions; verify multiple channels exist for distinct types.
- **Exceptions:** Apps with a single genuine notification type.
- **See also:** [[NOTIF-006]], [[NOTIF-012]]

### NOTIF-004 — Deep-link every notification to its context
- **Rule:** Tapping a notification MUST open the exact relevant in-app destination (the specific message/order/screen), not just the home screen, preserving/synthesizing the correct back stack.
- **Why:** Dropping users on the home screen forces them to re-find the item and defeats the notification's purpose.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual tap-through of each notification type to its destination.
- **Exceptions:** Purely informational notices with no in-app target.
- **See also:** [[NOTIF-008]], [[PLAT-003]]

### NOTIF-005 — Respect quiet hours & Do Not Disturb
- **Rule:** Non-urgent notifications MUST respect user quiet hours / DND and avoid night-time sends; use time-sensitive/critical interruption levels only for genuinely urgent, user-relevant events.
- **Why:** Notifications during sleep or focus time drive disablement and uninstalls; misusing urgent levels erodes trust and violates store expectations.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review send scheduling and interruption-level usage; verify quiet-hours handling.
- **Exceptions:** True emergencies (security, safety) the user opted into.
- **See also:** [[NOTIF-007]], [[NOTIF-012]]

### NOTIF-006 — In-app notification preferences mirror channels
- **Rule:** Provide in-app notification settings that mirror the OS channels/categories, with a clear path to system settings for OS-level control.
- **Why:** Users expect to manage notification types inside the app; in-app controls reduce blanket opt-outs.
- **Platforms:** all
- **Severity:** warning
- **Check:** Verify a notifications settings section exists and maps to channels.
- **Exceptions:** Single-channel apps.
- **See also:** [[NOTIF-003]], [[SET-008]]

### NOTIF-007 — Don't over-notify; group and cap frequency
- **Rule:** Batch/group related notifications (summary/grouped notifications), enforce sensible frequency caps, and avoid duplicate or redundant alerts for the same event.
- **Why:** Notification spam is the top reason users disable notifications or uninstall.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review send frequency and grouping; test burst scenarios.
- **Exceptions:** Distinct, individually-actionable time-critical events.
- **See also:** [[NOTIF-005]], [[NOTIF-011]]

### NOTIF-008 — Provide actions on actionable notifications
- **Rule:** Where a quick response is natural (reply, approve/decline, mark done, snooze), expose notification actions so users can act without a full app launch, and reflect the result in-app.
- **Why:** Inline actions reduce friction and increase engagement with meaningful notifications.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Review notification payloads for actions where relevant.
- **Exceptions:** Notifications with no sensible quick action.
- **See also:** [[NOTIF-004]], [[A11Y-033]]

### NOTIF-009 — Handle denied permission gracefully; don't nag
- **Rule:** If notifications are denied, do not repeatedly re-prompt (the OS suppresses it anyway); continue delivering value in-app and offer a settings deep-link where notifications add clear value.
- **Why:** Nagging annoys users and cannot re-show the system dialog after denial; respectful fallback preserves goodwill.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: deny permission → verify no repeated prompts; settings path available.
- **Exceptions:** A single contextual re-ask via settings deep-link when the user hits a notification-dependent feature.
- **See also:** [[PERM-004]], [[PERM-007]]

### NOTIF-010 — Localize and mirror notification content
- **Rule:** Notification titles/bodies MUST be localized to the user's language and respect RTL; do not send hardcoded English or unlocalized templates.
- **Why:** Notifications are the app's most public surface; untranslated ones look broken and exclude non-English users.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review notification templates for localization; test in a non-English + RTL locale.
- **Exceptions:** None.
- **See also:** [[L10N-001]], [[L10N-002]]

### NOTIF-011 — Keep badge counts accurate and cleared
- **Rule:** App-icon and in-app badge counts MUST reflect genuinely unread/actionable items and clear promptly when the user views them; never show stale or inflated badges.
- **Why:** Phantom badges train users to ignore the badge and feel manipulative.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: read items → badge decrements/clears; verify no residual count.
- **Exceptions:** None.
- **See also:** [[NOTIF-007]], [[A11Y-013]]

### NOTIF-012 — Separate transactional from promotional; protect lock-screen privacy
- **Rule:** Keep transactional/time-sensitive notifications distinct from promotional ones (separate channels + honest interruption levels), and do not expose sensitive content (codes, health, financial, private messages) on the lock screen by default.
- **Why:** Mixing marketing into urgent channels erodes trust; sensitive lock-screen previews are a privacy/security risk.
- **Platforms:** all
- **Severity:** warning
- **Check:** Review channel classification and lock-screen visibility settings for sensitive types.
- **Exceptions:** User explicitly opts into showing content on the lock screen.
- **See also:** [[NOTIF-003]], [[NOTIF-005]], [[PERM-005]]

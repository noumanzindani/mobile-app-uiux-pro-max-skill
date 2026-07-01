# Profile & Account (PROF)

> Purpose: Give users real control over their account — reachable deletion (store-mandated), optimistic editing with clear save state, confirmed sign-out, avatar fallbacks, and step-up for sensitive changes.

## Contents
- [PROF-001 — Make account deletion reachable in-app](#prof-001--make-account-deletion-reachable-in-app)
- [PROF-002 — Edit fields with optimistic save and rollback](#prof-002--edit-fields-with-optimistic-save-and-rollback)
- [PROF-003 — Confirm sign-out](#prof-003--confirm-sign-out)
- [PROF-004 — Provide an avatar fallback with alt text](#prof-004--provide-an-avatar-fallback-with-alt-text)
- [PROF-005 — Account deletion is a deliberate, explained, two-step confirm](#prof-005--account-deletion-is-a-deliberate-explained-two-step-confirm)
- [PROF-006 — Group settings and isolate destructive actions](#prof-006--group-settings-and-isolate-destructive-actions)
- [PROF-007 — Show inline save state for edits](#prof-007--show-inline-save-state-for-edits)
- [PROF-008 — Require step-up re-auth for sensitive changes](#prof-008--require-step-up-re-auth-for-sensitive-changes)
- [PROF-009 — Make profile fields and edit affordances accessible](#prof-009--make-profile-fields-and-edit-affordances-accessible)
- [PROF-010 — Provide loading, error, and offline states for the profile](#prof-010--provide-loading-error-and-offline-states-for-the-profile)

---

### PROF-001 — Make account deletion reachable in-app
- **Rule:** If the app supports account creation, it MUST provide an in-app path to DELETE the account (not just deactivate, not web-only), reachable from account/settings.
- **Why:** In-app account deletion is mandatory under both App Store Guideline 5.1.1(v) and Google Play's account-deletion policy.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — locate an in-app delete-account path from the profile/settings area.
- **Exceptions:** Apps with no account creation; regulated apps that may route deletion through a compliant assisted flow.
- **See also:** [[PROF-005]], [[SET-005]]

### PROF-002 — Edit fields with optimistic save and rollback
- **Rule:** Profile edits SHOULD apply optimistically (reflect immediately) with a visible saving indicator, and roll back with a clear error if the save fails.
- **Why:** Optimistic updates feel instant; silent failures leave users believing a change stuck when it did not.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — edit a field on a throttled/failed network and confirm rollback + error.
- **Exceptions:** Sensitive fields requiring server confirmation before reflecting (email/password).
- **See also:** [[PROF-007]], [[OFF-002]]

### PROF-003 — Confirm sign-out
- **Rule:** Sign-out MUST require a confirmation step (dialog or clearly distinct action) so it is not triggered accidentally, and it must clearly differ from account deletion.
- **Why:** Accidental sign-out (especially where re-login is costly) is frustrating; conflating it with deletion is dangerous.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — trigger sign-out and confirm a confirmation gate.
- **Exceptions:** None.
- **See also:** [[PROF-005]], [[DLG-004]]

### PROF-004 — Provide an avatar fallback with alt text
- **Rule:** When no profile image is set, show a deterministic fallback (initials or a default icon), and every avatar MUST expose a meaningful accessible label (the person's name), never 'image'.
- **Why:** Broken/empty avatars look unfinished, and unlabeled avatars are meaningless to screen-reader users (WCAG §1.1.1).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — clear the avatar (fallback shows); VoiceOver/TalkBack reads the name.
- **Exceptions:** None.
- **See also:** [[AVT-001]], [[A11Y-025]]

### PROF-005 — Account deletion is a deliberate, explained, two-step confirm
- **Rule:** Deleting an account MUST require an explicit confirmation that explains the consequences (data loss, subscriptions, irreversibility) and is visually distinct/isolated from sign-out.
- **Why:** Deletion is irreversible; a clear, isolated confirm prevents catastrophic accidental loss.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify deletion shows consequences and a deliberate confirm separate from sign-out.
- **Exceptions:** None.
- **See also:** [[PROF-001]], [[PROF-003]], [[DLG-004]]

### PROF-006 — Group settings and isolate destructive actions
- **Rule:** Account/settings screens MUST be grouped into scannable sections, with destructive actions (delete, sign out, clear data) visually isolated and placed apart from routine controls.
- **Why:** Grouping aids findability; isolating destructive controls prevents mis-taps among everyday toggles.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify logical grouping and separated destructive actions.
- **Exceptions:** None.
- **See also:** [[SET-001]], [[PROF-005]]

### PROF-007 — Show inline save state for edits
- **Rule:** Field/setting changes MUST reflect their save state inline — saving, saved, or failed — so users are never left guessing whether a change persisted.
- **Why:** Ambiguous save state is a common source of lost changes and re-editing.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — change a setting and observe an explicit saved/failed indicator.
- **Exceptions:** None.
- **See also:** [[PROF-002]], [[STATE-006]]

### PROF-008 — Require step-up re-auth for sensitive changes
- **Rule:** Changing email, password, phone, or payout details, and deleting the account, MUST require re-authentication (passcode/biometric/password) even in an active session.
- **Why:** Session hijacking or an unattended device shouldn't allow silent takeover of account credentials.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — attempt a sensitive change and confirm a re-auth prompt.
- **Exceptions:** None.
- **See also:** [[AUTH-012]], [[BIO-002]]

### PROF-009 — Make profile fields and edit affordances accessible
- **Rule:** All editable fields MUST have programmatic labels, edit controls MUST be discoverable and labeled, and read-only vs editable state MUST be conveyed non-visually.
- **Why:** Unlabeled fields and ambiguous edit affordances block screen-reader and low-vision users (WCAG §4.1.2).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — edit the profile entirely via VoiceOver/TalkBack.
- **Exceptions:** None.
- **See also:** [[PROF-004]], [[A11Y-012]], [[FRM-020]]

### PROF-010 — Provide loading, error, and offline states for the profile
- **Rule:** Profile/account screens MUST handle loading (fetching account), error (load/save failure with retry), and offline (cached view, edits queued or blocked with explanation) states.
- **Why:** Account data is network-backed; unhandled states here erode trust in the app's reliability with the user's own data.
- **Platforms:** all
- **Severity:** warning
- **Check:** state_coverage.py; manual — load the profile offline and on a failing save.
- **Exceptions:** None.
- **See also:** [[STATE-001]], [[PROF-002]], [[OFF-003]]

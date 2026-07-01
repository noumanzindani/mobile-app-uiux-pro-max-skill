# Onboarding (ONB)

> Purpose: Get users to value fast — lead with benefit, keep it to a few skippable screens, prime permissions progressively in context, and never trap or repeat the flow.

## Contents
- [ONB-001 — Lead with value, not a feature tour](#onb-001--lead-with-value-not-a-feature-tour)
- [ONB-002 — Keep onboarding to at most 3–4 screens](#onb-002--keep-onboarding-to-at-most-34-screens)
- [ONB-003 — Onboarding is always skippable](#onb-003--onboarding-is-always-skippable)
- [ONB-004 — Show progress through the flow](#onb-004--show-progress-through-the-flow)
- [ONB-005 — Prime permissions progressively, in context](#onb-005--prime-permissions-progressively-in-context)
- [ONB-006 — Let users explore before forcing signup](#onb-006--let-users-explore-before-forcing-signup)
- [ONB-007 — Defer account creation and personalization](#onb-007--defer-account-creation-and-personalization)
- [ONB-008 — Allow back navigation between steps](#onb-008--allow-back-navigation-between-steps)
- [ONB-009 — Do not gate onboarding behind a mandatory rating or paywall interruption](#onb-009--do-not-gate-onboarding-behind-a-mandatory-rating-or-paywall-interruption)
- [ONB-010 — Honor reduce-motion in onboarding animations](#onb-010--honor-reduce-motion-in-onboarding-animations)
- [ONB-011 — Make each onboarding step accessible](#onb-011--make-each-onboarding-step-accessible)
- [ONB-012 — Show onboarding once and persist completion](#onb-012--show-onboarding-once-and-persist-completion)

---

### ONB-001 — Lead with value, not a feature tour
- **Rule:** The first onboarding screen MUST communicate the core user benefit ('what you get') within one glance, not a list of features or a wall of marketing.
- **Why:** Users decide to continue or bail in seconds; value-first framing beats feature enumeration on activation.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — read the first screen and confirm it states a user benefit.
- **Exceptions:** None.
- **See also:** [[ONB-002]], [[ONB-006]]

### ONB-002 — Keep onboarding to at most 3–4 screens
- **Rule:** Pre-value onboarding MUST be at most 3–4 screens; beyond that, defer education into the product via contextual tips.
- **Why:** Every extra intro screen sheds users before they reach the product; short flows convert better.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — count onboarding screens (≤4).
- **Exceptions:** Regulated flows requiring mandated disclosures/consent screens.
- **See also:** [[ONB-001]], [[ONB-004]]

### ONB-003 — Onboarding is always skippable
- **Rule:** A persistent, clearly-labeled Skip/'Get started' control MUST let users bypass onboarding at any step and land in the app.
- **Why:** Returning and experienced users should not be forced through intros; a missing skip is a common frustration.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify a Skip control is present and functional on each step.
- **Exceptions:** Legally mandatory consent/age-gate steps that genuinely cannot be skipped.
- **See also:** [[ONB-006]], [[ONB-012]]

### ONB-004 — Show progress through the flow
- **Rule:** Multi-step onboarding MUST show progress (dots, step counter, or bar) so users know how many steps remain.
- **Why:** Visible progress sets expectations and reduces mid-flow abandonment.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm a progress indicator reflects the current step.
- **Exceptions:** Single-screen onboarding.
- **See also:** [[ONB-002]], [[PRG-001]]

### ONB-005 — Prime permissions progressively, in context
- **Rule:** Do NOT request OS permissions during onboarding upfront; ask at the moment the feature needs them, preceded by a value-first priming explanation.
- **Why:** Upfront permission walls tank grant rates and burn the one-shot OS prompt; in-context requests are trusted and granted more often.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm no OS permission dialogs fire during the intro before the feature is used.
- **Exceptions:** A single permission genuinely required for the app's first core action.
- **See also:** [[PERM-002]], [[MAP-009]], [[CAM-002]]

### ONB-006 — Let users explore before forcing signup
- **Rule:** Where the product allows, let users experience core value before requiring account creation; do not open with a hard signup wall.
- **Why:** Signup walls before any value shown are a top drop-off point and, for content apps, an App Store 5.1.1 concern.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm meaningful content/value is reachable before signup.
- **Exceptions:** Apps that are inherently account-based (banking, personal data) or where 5.1.1 exceptions apply.
- **See also:** [[AUTH-017]], [[ONB-007]]

### ONB-007 — Defer account creation and personalization
- **Rule:** Collect only what is needed to start; make personalization questions optional and skippable, and gather profile data progressively after first value.
- **Why:** Front-loading forms delays the payoff and increases abandonment; progressive collection keeps momentum.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify personalization steps are optional/skippable.
- **Exceptions:** Personalization that is essential to the first useful screen.
- **See also:** [[ONB-006]], [[PROF-002]]

### ONB-008 — Allow back navigation between steps
- **Rule:** Users MUST be able to move backward through onboarding steps to review or change earlier answers, and the system back gesture MUST behave predictably (not exit the app unexpectedly).
- **Why:** Trapping users on a forward-only flow prevents correcting mistakes and violates back-navigation expectations.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — navigate back through steps and via the system back gesture.
- **Exceptions:** Irreversible confirmation steps clearly marked as final.
- **See also:** [[ONB-004]], [[NAV-012]]

### ONB-009 — Do not gate onboarding behind a mandatory rating or paywall interruption
- **Rule:** Onboarding MUST NOT force an app-rating prompt or an un-dismissable paywall before the user reaches any value; paywalls, if present, must be clearly dismissible.
- **Why:** Premature rating/paywall interruptions before value feels hostile and breaches store review-prompt and subscription-clarity guidelines.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm no forced rating and any paywall is dismissible with a clear close.
- **Exceptions:** Hard-paywall business models that disclose this clearly and meet store rules.
- **See also:** [[ONB-003]], [[PAY-018]]

### ONB-010 — Honor reduce-motion in onboarding animations
- **Rule:** Parallax, auto-advancing carousels, and celebratory animations in onboarding MUST respect the OS reduce-motion setting with a static or simplified alternative.
- **Why:** Heavy intro motion can cause vestibular discomfort; reduce-motion compliance is required (WCAG §2.3.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enable Reduce Motion and confirm onboarding motion is toned down.
- **Exceptions:** None.
- **See also:** [[MOT-018]], [[MEDIA-011]], [[A11Y-020]]

### ONB-011 — Make each onboarding step accessible
- **Rule:** Each slide MUST be a labeled, screen-reader-navigable page announcing its step; any swipe-to-advance interaction MUST have a visible button alternative (WCAG §2.5.7).
- **Why:** Carousel-only, swipe-only onboarding is invisible and unusable for screen-reader and motor-impaired users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — traverse onboarding entirely via VoiceOver/TalkBack and buttons.
- **Exceptions:** None.
- **See also:** [[ONB-004]], [[GES-004]], [[A11Y-024]]

### ONB-012 — Show onboarding once and persist completion
- **Rule:** Completed onboarding MUST be persisted so it does not reappear on later launches or after updates (offer a 'replay tour' in settings instead).
- **Why:** Re-showing onboarding to returning users is a recurring, avoidable annoyance.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — complete onboarding, relaunch, and confirm it does not repeat.
- **Exceptions:** Genuinely new major-version onboarding for significant UX changes.
- **See also:** [[ONB-003]], [[SET-004]]

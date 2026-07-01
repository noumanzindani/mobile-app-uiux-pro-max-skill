# Social / Messaging — Common Pitfalls

> The social/messaging-specific mistakes AI-generated and human-built apps make most
> often, why they hurt, and the rule that prevents each. Scan this before shipping a
> feed, a chat screen, or a safety flow. Cross-references use `[[ID]]`.

Two failure modes dominate this domain. The first is **dishonest speed**: interfaces
that fake success — a like that appears to register but silently fails, a message that
vanishes, a badge that lies. Social apps are judged on responsiveness, so teams reach
for optimistic UI (`[[SOC-002]]`, `[[SOC-003]]`) but skip the *reconciliation* half,
leaving users acting on a corrupted picture of reality. The second is **treating safety
as an afterthought**: reporting buried three menus deep, a block that needs an app
restart, sensitive content that autoplays into a stranger's DMs to a minor. Both are
rejection-worthy under store policy and corrosive to trust.

A third, subtler category is **engagement dark patterns** (`[[SOC-022]]`): fake
notification bait, endless autoplay with no off switch, exit-guilt interstitials, and
inflated badges. These may lift a metric this quarter, but they draw regulatory
scrutiny (age-appropriate design, deceptive-pattern rules), violate store policy, and
erode the long-term trust that social products live and die on. The fix is the same
posture throughout: be fast **and** honest, make safety reflexive, and give users real
stopping cues and controls.

| # | Pitfall | Why it's harmful | Fix / rule |
|---|---------|------------------|-----------|
| 1 | **Optimistic like/comment that silently fails** | User believes an action succeeded; counts and state drift from reality | Reconcile against server; visible rollback + retry → [[SOC-002]] |
| 2 | **Sent message vanishes or gives no delivery signal** | Breaks chat's core promise; causes duplicate sends and distrust | Status ticks sending→…→failed; failed stays with retry → [[SOC-003]], [[SOC-007]] |
| 3 | **Composer hidden behind the keyboard / home indicator** | Chat becomes literally unusable on notched devices | Keyboard avoidance + safe-area insets → [[SOC-004]] |
| 4 | **Auto-scroll yanks user out of history they're reading** | Disruptive; loses the user's place mid-read | Scroll-to-latest only when at bottom; "jump to latest" pill → [[SOC-004]], [[SOC-009]] |
| 5 | **Cold OS notification prompt on first launch** | One-shot prompt gets denied; re-engagement permanently lost | Prime in-context before the OS prompt → [[SOC-005]], [[SOC-019]] |
| 6 | **Feed resets to top on every back-navigation** | Users re-scroll seen content; sessions shorten, data wasted | Preserve scroll position; insert refresh via pill → [[SOC-006]], [[SOC-001]] |
| 7 | **Unvirtualized feed / lone spinner / no end state** | Jank, memory leaks, ambiguous "is it broken?" loading | Virtualize + skeletons + pull-to-refresh + end/empty/error → [[SOC-001]] |
| 8 | **Color-only unread dots or stale badge counts** | Unreadable to color-blind users; phantom-unread anxiety | Count/shape not color-only; badge accuracy → [[SOC-009]] |
| 9 | **Report/block/mute buried or gesture-only** | Users can't respond to harm; store rejection/removal risk | Report+block+mute ≤2 taps, visible affordance → [[SOC-013]] |
| 10 | **Block that needs a restart or can't be undone** | Abuser stays visible; accidental blocks trap the user | Immediate effect + confirm + undo + manage list → [[SOC-014]] |
| 11 | **Sensitive media rendered inline with no warning** | Unexpected graphic content harms users; policy violation | Blur by default + explicit "show anyway" → [[SOC-015]] |
| 12 | **Stranger DMs to minors on by default** | Major safety/regulatory (age-appropriate design) risk | Minor-safe defaults; stranger DMs as requests → [[SOC-016]] |
| 13 | **Report flow with no categories/acknowledgment/blame** | Suppresses legitimate reports; reporter feels punished | Reason + confirm + acknowledgment, no blame → [[SOC-017]] |
| 14 | **Autoplay video with sound / ignores reduce-motion** | Disruptive, inaccessible, vestibular harm, data burn | Muted, pausable, reduce-motion/data-saver off → [[SOC-021]], [[SOC-010]] |
| 15 | **Media with no alt text or captions** | Excludes blind and deaf/hard-of-hearing users | Alt text + captions/transcripts → [[SOC-021]] |
| 16 | **Real-time updates never announced to screen readers** | Blind users miss new messages, typing, count changes | Polite, batched live-region announcements → [[SOC-020]] |
| 17 | **Blaming/alarmist safety copy** ("You violated our rules") | Escalates conflict; discourages reporting | Calm, plain, non-judgmental copy + appeal → [[SOC-018]] |
| 18 | **Bait notifications / fake "someone" / inflated counts** | Trains users to disable notifications; policy violation | Honest, value-first, deep-linked copy → [[SOC-019]] |
| 19 | **Endless autoplay/scroll with no off switch or end cue** | Engagement dark pattern; wellbeing & regulatory risk | User controls + "you're all caught up" marker → [[SOC-022]], [[SOC-001]] |
| 20 | **Tiny/unlabeled send & reaction targets** | Fails min target size; unreachable to AT and motor-impaired | ≥44pt/48dp labeled targets → [[SOC-012]], [[SOC-011]] |

## Quick self-audit

Before shipping any feed, chat, or safety screen, confirm:

- [ ] Every like/comment/post/send updates optimistically **and** rolls back visibly on failure.
- [ ] Messages show a full send-status lifecycle; failures stay put with retry.
- [ ] Composer and latest message stay visible above the keyboard and safe area.
- [ ] Scroll-to-latest never hijacks a user reading history; a jump-to-latest affordance exists.
- [ ] Feed is virtualized with skeletons, pull-to-refresh, and distinct end/empty/error states.
- [ ] Feed position survives back-navigation and refresh.
- [ ] Unread indicators are non-color-only and badge counts are accurate.
- [ ] Report, block, and mute are reachable in ≤2 taps from any content, with a visible affordance.
- [ ] Block/mute takes effect immediately and is undoable and manageable.
- [ ] Sensitive content is blurred by default with an explicit reveal; minors get safe defaults.
- [ ] Report flow has reason categories, confirmation, acknowledgment, and non-blaming copy.
- [ ] Notifications are primed before the OS prompt and use honest, value-first, deep-linked copy.
- [ ] Media has alt text and captions; autoplay is muted and respects reduce-motion/data-saver.
- [ ] Real-time updates announce politely and batched to assistive tech.
- [ ] No engagement dark patterns: no fake badges/bait, no exit-guilt, an off switch and stopping cues exist.

---

## Rules

### SOC-022 — No engagement dark patterns; infinite scroll ships with user controls
- **Rule:** The app MUST NOT employ engagement dark patterns: no fake notification badges, no bait/misleading notifications, no forced or endless autoplay with no off switch, no guilt-tripping interstitials to prevent leaving, and no removal of natural stopping cues. Infinite scroll MUST be paired with user controls — a real end / "you're all caught up" marker, autoplay and screen-time/mute controls where relevant — and badge counts MUST stay honest.
- **Why:** Manipulative engagement mechanics harm user wellbeing, draw regulatory scrutiny (deceptive-pattern and age-appropriate design rules), and violate store policy; honest controls and stopping cues respect user autonomy and sustain long-term trust.
- **Platforms:** all
- **Severity:** warning
- **Check:** Audit for fake badges/bait notifications and inflated counts; autoplay has an off switch; the feed provides a caught-up/end cue; no exit-guilt interstitials; badges are accurate per [[BDG-005]].
- **See also:** [[SOC-001]], [[SOC-009]], [[SOC-019]], [[BDG-005]], [[NOTIF-001]]

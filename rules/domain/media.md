# Media (Audio / Video / Image) (MEDIA)

> Purpose: Deliver accessible, well-behaved media — captions and transcripts, no surprise audio, Picture-in-Picture, system media controls, haptic scrubbing, and clear buffering states.

## Contents
- [MEDIA-001 — Provide captions for video and transcripts for audio](#media-001--provide-captions-for-video-and-transcripts-for-audio)
- [MEDIA-002 — Never autoplay audio](#media-002--never-autoplay-audio)
- [MEDIA-003 — Support Picture-in-Picture for video](#media-003--support-picture-in-picture-for-video)
- [MEDIA-004 — Support background audio with system media controls](#media-004--support-background-audio-with-system-media-controls)
- [MEDIA-005 — Scrubber has a large target and haptic feedback](#media-005--scrubber-has-a-large-target-and-haptic-feedback)
- [MEDIA-006 — Distinguish buffering from paused](#media-006--distinguish-buffering-from-paused)
- [MEDIA-007 — Provide standard, reachable transport controls](#media-007--provide-standard-reachable-transport-controls)
- [MEDIA-008 — Respect the silent switch and audio focus](#media-008--respect-the-silent-switch-and-audio-focus)
- [MEDIA-009 — Remember and resume playback position](#media-009--remember-and-resume-playback-position)
- [MEDIA-010 — Do not override system volume; provide app mute](#media-010--do-not-override-system-volume-provide-app-mute)
- [MEDIA-011 — Honor reduce-motion for autoplaying loops](#media-011--honor-reduce-motion-for-autoplaying-loops)
- [MEDIA-012 — Support fullscreen, rotation, and auto-hiding controls](#media-012--support-fullscreen-rotation-and-auto-hiding-controls)
- [MEDIA-013 — Media controls are labeled and state-announced](#media-013--media-controls-are-labeled-and-state-announced)
- [MEDIA-014 — Provide all 7 states for media surfaces](#media-014--provide-all-7-states-for-media-surfaces)

---

### MEDIA-001 — Provide captions for video and transcripts for audio
- **Rule:** Video MUST support closed captions/subtitles and audio-only content MUST offer a transcript; the caption toggle is discoverable within the player.
- **Why:** Captions/transcripts are required for deaf/hard-of-hearing users (WCAG §1.2.2/§1.2.1) and are used broadly for sound-off viewing.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm a caption toggle for video and a transcript path for audio.
- **Exceptions:** Purely decorative silent/ambient video with no information content.
- **See also:** [[MEDIA-013]], [[A11Y-025]]

### MEDIA-002 — Never autoplay audio
- **Rule:** Media MUST NOT start playing sound automatically; if video autoplays it starts muted, with a visible unmute control, and honors the OS silent switch.
- **Why:** Unexpected audio is intrusive, a privacy embarrassment, and a WCAG §1.4.2 failure when it lasts more than 3 seconds without a control.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — enter a media screen and confirm no unsolicited audio.
- **Exceptions:** User-initiated playback; a media app whose explicit purpose is resuming playback.
- **See also:** [[MEDIA-008]], [[CHAT-014]]

### MEDIA-003 — Support Picture-in-Picture for video
- **Rule:** Video players SHOULD support Picture-in-Picture so playback continues when the user leaves the app or multitasks, using the platform PiP API.
- **Why:** PiP is an expected multitasking affordance on modern iOS and Android and keeps users in your content.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — background the app during playback and confirm PiP.
- **Exceptions:** DRM-restricted content or contexts where PiP is disallowed.
- **See also:** [[MEDIA-004]], [[MEDIA-012]]

### MEDIA-004 — Support background audio with system media controls
- **Rule:** Audio/podcast/music playback MUST continue in the background and expose lock-screen, Control Center/notification, and remote (headset/car) controls via the platform media session (MediaSession / MPNowPlayingInfo + remote command center).
- **Why:** Backgrounded playback with system controls is the baseline expectation for any audio app.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — lock the device during audio and confirm working lock-screen controls.
- **Exceptions:** Media intended to stop when the app backgrounds (e.g. in-context previews).
- **See also:** [[MEDIA-008]], [[MEDIA-009]]

### MEDIA-005 — Scrubber has a large target and haptic feedback
- **Rule:** The seek control MUST have a thumb ≥44pt/48dp effective target, support drag-to-scrub with a time preview, and give subtle haptic feedback at meaningful points (start, chapter marks, ends).
- **Why:** A large, tactile scrubber makes precise seeking possible one-handed; haptics confirm boundaries without looking.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on the scrubber thumb; manual — scrub and feel haptics.
- **Exceptions:** Live streams with no seekable timeline.
- **See also:** [[MEDIA-007]], [[HAP-003]], [[PRG-006]]

### MEDIA-006 — Distinguish buffering from paused
- **Rule:** A buffering/loading state MUST be visually distinct from the paused state (e.g. spinner over the play button vs a static play glyph) so users know whether to wait or to tap.
- **Why:** Conflating loading with paused makes users tap a control that is actually working, or wait on one that is stalled.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — throttle network mid-playback and observe the buffering indicator.
- **Exceptions:** None.
- **See also:** [[MEDIA-014]], [[STATE-005]]

### MEDIA-007 — Provide standard, reachable transport controls
- **Rule:** Players MUST offer play/pause and ±10s (or chapter) skip as ≥44pt/48dp targets, with play/pause the largest, centered, thumb-reachable control.
- **Why:** Consistent, large transport controls are expected and support quick one-handed correction.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on transport controls.
- **Exceptions:** Minimal preview players may expose only play/pause.
- **See also:** [[MEDIA-005]], [[BTN-002]]

### MEDIA-008 — Respect the silent switch and audio focus
- **Rule:** Honor the iOS silent switch for incidental audio, and on Android request/abandon audio focus so playback ducks or pauses for calls, navigation, and other apps.
- **Why:** Ignoring the ringer switch or stealing audio focus makes the app a bad citizen and frustrates users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — toggle silent (iOS) and trigger another audio app / call (Android).
- **Exceptions:** Media the user explicitly started to play through the silent switch (per platform norms).
- **See also:** [[MEDIA-002]], [[MEDIA-004]]

### MEDIA-009 — Remember and resume playback position
- **Rule:** For long-form media, persist the playback position and offer resume-from-where-you-left-off on return, per item and across sessions.
- **Why:** Losing your place in a long video/podcast is a top complaint and forces tedious re-seeking.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — leave mid-item, return, and confirm resume.
- **Exceptions:** Short clips or live content.
- **See also:** [[MEDIA-004]], [[MEDIA-005]]

### MEDIA-010 — Do not override system volume; provide app mute
- **Rule:** The player MUST use system volume rather than a competing hidden gain, and offer an in-player mute/volume control that maps to expected behavior.
- **Why:** Hidden volume layers surprise users and can blast audio; system volume is the trusted control.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify hardware volume keys govern playback and mute behaves.
- **Exceptions:** Mixing apps that legitimately expose per-track gain.
- **See also:** [[MEDIA-008]]

### MEDIA-011 — Honor reduce-motion for autoplaying loops
- **Rule:** When Reduce Motion is enabled, autoplaying looping video/GIF/animated backgrounds MUST pause or show a static frame with a manual play control.
- **Why:** Looping motion can trigger vestibular discomfort; §2.3.3 / platform reduce-motion settings must be respected.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enable Reduce Motion and confirm loops do not auto-run.
- **Exceptions:** User-initiated playback of the primary content.
- **See also:** [[MEDIA-002]], [[MOT-018]], [[A11Y-020]]

### MEDIA-012 — Support fullscreen, rotation, and auto-hiding controls
- **Rule:** Video MUST support fullscreen and landscape rotation, with controls that auto-hide during playback and reappear on tap; the tap target to reveal controls covers the frame.
- **Why:** Fullscreen landscape is the expected immersive video mode; auto-hiding controls maximize the picture without hiding access.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — enter fullscreen, rotate, and toggle controls by tapping.
- **Exceptions:** Portrait-only short-form video experiences.
- **See also:** [[MEDIA-007]], [[GRD-010]]

### MEDIA-013 — Media controls are labeled and state-announced
- **Rule:** Every control (play/pause, mute, captions, scrubber, fullscreen) MUST have an accessible label and announce state; the scrubber exposes an adjustable value to assistive tech.
- **Why:** Unlabeled icon-only media controls are opaque to screen-reader users (WCAG §4.1.2, §1.1.1).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — operate the player entirely via VoiceOver/TalkBack.
- **Exceptions:** None.
- **See also:** [[MEDIA-001]], [[A11Y-012]], [[PRG-006]]

### MEDIA-014 — Provide all 7 states for media surfaces
- **Rule:** Media screens MUST design ideal, empty (no media / empty library), loading (buffering/fetching), error (playback/decode failure with retry), offline (cached-only or unavailable), success (download complete), and permission-denied (photos/mic).
- **Why:** Media depends on network, storage, and permissions; unhandled states leave users staring at a black frame.
- **Platforms:** all
- **Severity:** error
- **Check:** state_coverage.py on the media screen set.
- **Exceptions:** Permission-denied is N/A for playback that requests no OS permission.
- **See also:** [[STATE-001]], [[MEDIA-006]], [[OFF-003]]

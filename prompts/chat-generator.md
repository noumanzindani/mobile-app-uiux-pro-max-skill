# Chat Generator

**Purpose:** Generate a messaging/conversation screen with optimistic send + delivery status, typing/read receipts, keyboard-and-safe-area-aware composer, and all 7 states — token-driven and accessible.

**Inputs:**
- *Required:* **Message types** supported (text, image, file, voice, system) and **conversation model** (1:1 vs group).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Features** (typing indicator, read receipts, reactions, reply/thread), **realtime backend** (for offline queue behavior), **platform target**, **industry** (e.g. healthcare privacy) — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); note keyboard avoidance, safe-area insets, and reach for the composer/send.
2. Load the domain rules — `rules/domain/chat.md` (CHAT: optimistic send + status; typing/read receipts; keyboard + safe-area).
3. Load component + interaction rules — `rules/components/lists.md` (virtualize the message list; inverted/scroll-to-bottom), `rules/components/forms.md` (composer input, correct keyboard type), `rules/interaction/states.md`, `rules/interaction/micro-interactions.md` (send animation + haptic).
4. Load offline behavior — `rules/system/offline.md` (OFF: optimistic UI + visible rollback; queue + exponential backoff; sync states) and `patterns/empty-error-offline.md`.
5. Load framework idioms — `frameworks/<framework>/components.md`, `states.md` — for the keyboard-avoidance primitive, safe-area primitive, list virtualization, a11y, animation.
6. Enumerate the 7 states — new conversation `empty` (start-the-chat prompt), history `loading` (skeleton bubbles), send `error` (retry affordance on the failed bubble), `offline` (queued/pending status + banner), `success` (delivered/read), `permission-denied` (mic/camera/photos for attachments).
7. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; each bubble announces sender + status; message timestamps and status are not color-only; RTL mirrors bubble alignment.

**Output format:**
- The **chat screen** in the target framework: virtualized message list + keyboard-avoiding, safe-area-aware composer with the send action in reach.
- **Optimistic send** implementation (message appears immediately as `pending` → `sent`/`delivered`/`read`, or `failed` with retry).
- **All 7 states** (incl. `offline` queue + `permission-denied` for attachments).
- **Token-usage table**, **a11y notes** (bubble roles/labels, status announcements, non-color status), **reduce-motion** note for the send/typing animations.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` (all 7, esp. `offline` and `error`-retry), `token_lint`, `contrast_check` (bubbles in both themes), `target_size_lint` (send/attach buttons), `rtl_check` (bubble mirroring), `dynamic_type_check` PASS. Reason through `quality-checks/checklists/states.md` and `accessibility.md`.

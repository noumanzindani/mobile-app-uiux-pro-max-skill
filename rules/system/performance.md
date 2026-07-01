# Performance (PERF)

> Keep UI at 60fps (16ms/frame; 8.3ms on 120Hz ProMotion), animate only compositor-friendly properties, virtualize lists, and load images lazily without layout shift.

## Table of contents
- Rendering & animation — PERF-001…003
- Lists & images — PERF-004…008
- Work scheduling & responsiveness — PERF-009…013
- Startup, prefetch & measurement — PERF-014…016

---

### PERF-001 — Animate only transform & opacity
- **Rule:** Continuous/interactive animations MUST drive only compositor-friendly properties — `transform` (translate/scale/rotate) and `opacity`. Do NOT animate layout properties (width/height/top/left/margin/padding) or trigger per-frame layout/reflow.
- **Why:** Transform/opacity run on the GPU compositor without layout or paint; animating layout properties forces main-thread reflow and drops frames.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual profiler (Instruments Core Animation / Android GPU rendering / Flutter DevTools timeline); grep animations of size/position.
- **Exceptions:** One-off, non-interactive transitions on small elements where a layout change is unavoidable.
- **See also:** [[PERF-002]], [[MOT-002]], [[A11Y-028]]

### PERF-002 — Hold the 16ms frame budget (60fps; 8.3ms at 120Hz)
- **Rule:** Every frame during scroll/animation MUST complete within 16.7ms (60Hz); on 120Hz ProMotion/high-refresh displays target 8.3ms. Zero dropped frames on the critical scroll path.
- **Why:** Missing the budget causes visible jank/stutter, the most-noticed quality defect in mobile UI.
- **Platforms:** all
- **Severity:** error
- **Check:** Frame-timing profiler on a real mid-tier device; `perf_audit` flags jank frames over threshold.
- **Exceptions:** Unavoidable one-time cost during heavy first render, kept off the interaction path.
- **See also:** [[PERF-001]], [[PERF-006]], [[PERF-016]]

### PERF-003 — Cap animation duration & avoid gratuitous motion
- **Rule:** Routine transitions stay ≤ 300–400ms (never > 500ms); avoid always-on looping/parallax that keeps the GPU busy. Reduce or drop animation under Reduce Motion.
- **Why:** Long/continuous animations waste power, generate heat, and delay the user; excessive motion also harms accessibility.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of durations; `perf_audit` flags long/looping animations.
- **Exceptions:** Essential progress or branded intro sequences within reason.
- **See also:** [[MOT-001]], [[A11Y-028]]

### PERF-004 — Virtualize long/scrollable lists
- **Rule:** Any list that can exceed one screen MUST use a virtualized/recycling container — Flutter `ListView.builder`/`SliverList`, SwiftUI `LazyVStack`/`List`, Compose `LazyColumn`, RN `FlatList`/`FlashList`, native `RecyclerView`/`UICollectionView`. Never map an unbounded array into eagerly-built children.
- **Why:** Building all rows up front spikes memory and blocks the main thread; virtualization keeps only visible rows in memory.
- **Platforms:** all
- **Severity:** error
- **Check:** `perf_audit` / grep for non-lazy list construction over dynamic data.
- **Exceptions:** Short, bounded lists (≤ ~10 static items).
- **See also:** [[PERF-005]], [[LST-001]]

### PERF-005 — Lazy-load, downscale & cache images
- **Rule:** Images MUST load lazily (as they enter viewport), be decoded/resized to their display size (not full resolution), and be cached in memory + disk (e.g., `cacheWidth`/`cacheHeight`, `Image`+Coil/Glide, SDWebImage, FastImage). Never decode a 4000px asset into a 100px avatar.
- **Why:** Oversized decodes blow the memory budget and cause jank/OOM; caching avoids re-fetching and re-decoding.
- **Platforms:** all
- **Severity:** error
- **Check:** `perf_audit` inspects decoded vs display size; memory profiler for image cache.
- **Exceptions:** Full-resolution needed for zoom/gallery, loaded on demand.
- **See also:** [[PERF-004]], [[PERF-008]], [[AVT-001]]

### PERF-006 — No layout shift: reserve space for async content
- **Rule:** Reserve known dimensions for images, ads, and async content (fixed aspect-ratio boxes, skeletons matching final size) so incoming content does not push existing content and cause reflow/jumps.
- **Why:** Layout shift makes users mis-tap and re-find their place, and forces extra layout passes.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual load review; `perf_audit` detects post-load reflow.
- **Exceptions:** Genuinely unknown-size content where a graceful expand is acceptable.
- **See also:** [[PERF-005]], [[STATE-002]]

### PERF-007 — Show progress within 100ms; skeletons for content loads
- **Rule:** Acknowledge any user action within ~100ms (press state/spinner) and show a skeleton/placeholder for content that takes > ~400ms. Never present a frozen or blank screen during work.
- **Why:** Fast perceived feedback preserves the sense of control even when actual work is slower.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual latency review; `perf_audit` flags loads without a loading state.
- **Exceptions:** Instantaneous local actions.
- **See also:** [[STATE-002]], [[PERF-002]]

### PERF-008 — Bound image & media memory
- **Rule:** Ship appropriately sized assets (multiple densities / vector where possible), set memory-cache limits, and free off-screen media. Prefer vector/adaptive icons over large rasters.
- **Why:** Unbounded media caches are the top OOM cause on low-RAM devices.
- **Platforms:** all
- **Severity:** warning
- **Check:** Memory profiler under scroll; asset-size lint.
- **Exceptions:** Media-heavy apps with an explicit, tuned cache budget.
- **See also:** [[PERF-005]], [[ICN-002]]

### PERF-009 — Move heavy work off the main/UI thread
- **Rule:** Parsing, image processing, crypto, DB queries, and large computations MUST run off the main thread (isolates/`compute`, coroutines/`Dispatchers.Default`, GCD background queues, Swift concurrency, JS worker/InteractionManager). The main thread only renders and handles input.
- **Why:** Any main-thread stall directly drops frames and freezes touch input.
- **Platforms:** all
- **Severity:** error
- **Check:** Profiler for main-thread stalls; grep sync heavy work in build/render.
- **Exceptions:** Trivial synchronous work under ~1ms.
- **See also:** [[PERF-002]], [[PERF-013]]

### PERF-010 — Debounce/throttle high-frequency handlers
- **Rule:** Debounce text-driven queries (~250–300ms) and throttle scroll/resize/gesture handlers; coalesce rapid state updates. Do not fire a network request per keystroke.
- **Why:** Unthrottled handlers flood the CPU/network and cause jank and wasted calls.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of input/scroll handlers; network trace during typing.
- **Exceptions:** Handlers that must be immediate and are cheap.
- **See also:** [[SRCH-001]], [[PERF-012]]

### PERF-011 — Minimize overdraw, deep nesting & expensive effects
- **Rule:** Avoid stacked opaque layers (overdraw), excessively deep view trees, and costly real-time blurs/shadows on scrolling content. Flatten layouts; use static/pre-rendered effects where possible.
- **Why:** Overdraw and heavy per-frame effects saturate the GPU and cause scroll jank, especially on mid/low-tier devices.
- **Platforms:** all
- **Severity:** warning
- **Check:** GPU overdraw debug (Android) / Core Animation flags; profiler.
- **Exceptions:** Deliberate glass/blur where budget allows and Reduce Transparency is handled.
- **See also:** [[PERF-002]], [[A11Y-029]]

### PERF-012 — Paginate & cache network reads
- **Rule:** List/feed endpoints MUST paginate (cursor/limit) and responses MUST be cached with an explicit freshness policy; avoid fetching entire datasets at once.
- **Why:** Full-dataset fetches waste bandwidth/battery, delay first paint, and pressure memory.
- **Platforms:** all
- **Severity:** warning
- **Check:** Network trace; API review for pagination + cache headers.
- **Exceptions:** Small, bounded resources.
- **See also:** [[PERF-014]], [[OFF-001]]

### PERF-013 — Cancel in-flight work and dispose resources
- **Rule:** Cancel network/timers/streams/animations on navigation-away or dispose; release listeners, controllers, and observers to prevent leaks and wasted work. No `setState`/update after unmount/dispose.
- **Why:** Orphaned work and leaked resources drain battery, grow memory, and crash long sessions.
- **Platforms:** all
- **Severity:** error
- **Check:** Leak profiler over navigation; grep for undisposed controllers/subscriptions.
- **Exceptions:** Intentionally app-scoped singletons.
- **See also:** [[PERF-009]], [[OFF-009]]

### PERF-014 — Prefetch next-likely content
- **Rule:** Prefetch imminently-needed data/images (next page as the user nears list end, likely detail target, next onboarding step) so navigation feels instant — without over-fetching on metered/low-battery conditions.
- **Why:** Predictive prefetch removes visible wait at the moment of navigation.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Manual scroll-to-end and navigation latency review.
- **Exceptions:** Metered/data-saver contexts where prefetch is throttled.
- **See also:** [[PERF-012]], [[PERF-005]]

### PERF-015 — Avoid unnecessary rebuilds/re-renders
- **Rule:** Use `const`/memoization to prevent needless work — Flutter `const` widgets + granular `Provider`/selectors, React `memo`/`useMemo`/`useCallback`, Compose stable params + `remember`, SwiftUI value-type views. Scope state so a change rebuilds only the affected subtree.
- **Why:** Rebuilding large trees on every state change wastes CPU and causes jank.
- **Platforms:** all
- **Severity:** warning
- **Check:** Rebuild/recomposition profiler counts; lint for missing `const`.
- **Exceptions:** Trivially small trees.
- **See also:** [[PERF-002]], [[PERF-009]]

### PERF-016 — Set budgets and measure on real mid-tier devices
- **Rule:** Define and enforce budgets — cold start to first meaningful paint < ~2s, jank-free scroll, bounded memory — and validate with profiling on a representative mid/low-tier physical device (not just a flagship or simulator). Use the OS native splash; do not fake a long custom splash.
- **Why:** Emulators and flagships hide the jank real users experience; explicit budgets keep performance from regressing.
- **Platforms:** all
- **Severity:** warning
- **Check:** Startup + frame profiling on target device; `perf_audit` against budget thresholds.
- **Exceptions:** None — every release measures.
- **See also:** [[PERF-002]], [[PERF-007]]

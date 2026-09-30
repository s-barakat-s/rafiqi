# مَآب — Phase 0 Stabilization Baseline

التاريخ: 2026-09-29
الغرض: خط أساس موثوق قبل بدء إصلاحات الإنتاج (Phase 1+). هذا المستند يوثّق الحالة الفعلية للكود، لا الحالة المرغوبة.

---

## 1. Starting revision and pre-existing changes

- **Branch:** `main` — up to date with `origin/main`
- **HEAD at Phase 0 start:** `f213b9e585bad9fa8d72678609310f64f97020c0`
  (`feat(ui): finalize multi-theme visual system and optimize app presentation`)
- **Environment:** Flutter 3.38.3 (stable), Dart 3.10.1, DevTools 2.51.1, Windows host
- **Toolchain note:** repo instructions (`docs/architecture.md`) followed; no AGENTS.md present.
- **Pre-existing dirty worktree (NOT produced by Phase 0, preserved as-is):**
  - 24 modified tracked files under `lib/` + `pubspec.yaml` (multi-theme UI system work).
  - 9 untracked files: `lib/app/navigation/app_placeholder_screen.dart`,
    `lib/features/adhkar/presentation/widgets/adhkar_hub_hero.dart`,
    `lib/features/home/domain/prayer_schedule.dart`, `lib/features/home/domain/quran_reading.dart`,
    `lib/features/home/presentation/widgets/home_prayer_header.dart`,
    `lib/features/home/presentation/widgets/home_quick_access.dart`,
    `lib/features/home/presentation/widgets/home_quran_section.dart`,
    `lib/features/settings/presentation/screens/appearance_screen.dart`, and `.freebuff/`.
  - Some tracked `lib/` files are new-since-HEAD modifications (e.g. `dhikr_card.dart`,
    `dhikr_deck.dart`, `focus_reader_view.dart`, `list_reader_view.dart`,
    `reading_reader_view.dart`) that are *not* in the conversation-start snapshot list —
    they were modified outside this session and were preserved untouched.

**Files changed by Phase 0 (this session):**

| File | Change |
|---|---|
| `test/features/adhkar/adhkar_categories_transition_test.dart` | Fixture repair: added the two required callbacks (`onCustomize`, `onCreateCustom`); replaced an ambiguous title assertion after pop with key-based assertions (`pumpAndSettle` + `find.byTooltip('رجوع') findsNothing` + grid tile key). |
| `test/features/tasbeeh/tasbeeh_counter_logic_test.dart` | Fixture repair: supplied the six missing `TasbeehState` constructor arguments (`selectedDhikrId`, `selectedDhikrText`, `sessionCounts`) in both tests using the default phrase (`subhan_allah`) with realistic session counts matching `currentCount`. |
| `test/features/tasbeeh/tasbeeh_counter_recording_test.dart` | **New.** Behavioral regression tests: flows R1–R4 below. |
| `test/features/adhkar/adhkar_entry_point_parity_test.dart` | **New.** Behavioral regression tests: flows R5–R6 below. |
| `docs/stabilization/phase-0-baseline.md` | **New.** This document. |

No `lib/` or `packages/` (Android plugin) files were touched.

---

## 2. Test fixture repairs

### 2.1 `adhkar_categories_transition_test.dart`

Audit claim confirmed against current code: `AdhkarCategoryGrid` now requires
`onCustomize` (async, per-category) and `onCreateCustom` (VoidCallback).
- `onCustomize` was given an `async` no-op — it is never exercised by this test,
  which drives the tile's open-reader path only.
- Post-pop assertion failed for a *fixture* reason: the reader header now also
  renders the category title, so `find.text('أذكار الصباح')` matched twice during
  (and after) the pop transition. The test's purpose (route reverses to the tile)
  is preserved with unambiguous assertions: after `pumpAndSettle`, the reader
  tooltip is gone and the tile key `'adhkar-category-morning'` is present.

**Result: PASS** (exit 0).

### 2.2 `tasbeeh_counter_logic_test.dart`

Audit claim confirmed: `TasbeehState` requires `selectedDhikrId`,
`selectedDhikrText`, `sessionCounts` (2 constructors × 3 = 6 missing args).
Values were chosen to keep the tests' meaning:
- `selectedDhikrId` = first default phrase (`subhan_allah`),
- `sessionCounts` pre-populated to equal `currentCount` (32 / 33) so that
  `TasbeehCounterLogic.increment`'s session-count bookkeeping stays consistent
  with the asserted `currentCount`, `dailyTotal`, and `totalCount` outcomes.

**Result: PASS** (exit 0).

---

## 2bis. Scope of evidence (closeout clarification)

> **حدود ما تثبته هذه الاختبارات:** اختبارات الـcontroller/repository (مثل
> `tasbeeh_counter_recording_test.dart`) تثبت منطق الحالة والتخزين **فقط**،
> ولا تثبت تفاعل المسارات الفعلية (route reactivity) ولا تساوي نقاط الدخول
> في التنقل (navigation-entry parity) — ذلك يتطلب اختبارات widget تمر عبر
> `Navigator` الفعلي، ولم تُنفذ في Phase 0.

> **الفشل التسعة القديمة لم تُحل بعد** — ما زالت قائمة كما في §4.1، ولا يجوز
> اعتبار الحزمة خضراء. ربط مراحل الإصلاح حسب التدقيق الأصلي:
> **F5 → Phase 2A/2B، F6 → Phase 2B، F9 → Phase 2C، F7 → Phase 4**.

> توقعات التراجع بعد إتمام المهمة (P0-F3) **مؤقتة** لحين حسم سياسة التراجع-بعد-الإتمام صراحة؛ قد
> تتغير التوقعات عند حسم القرار. ربط التدقيق الأصلي: خلل التراجع نفسه وتوقعاته
> المؤقتة هما **F9 → Phase 2C** (وليس F5/Phase 2A/2B). F5 (تملّك الحالة
> وتفاعل المسارات) هو نطاق Phase 2A/2B دون تغيير سلوك التراجع.

---

## 3. Validation commands and outcomes

| Command | Exit code | Result |
|---|---|---|
| `flutter test test/features/tasbeeh/tasbeeh_counter_logic_test.dart test/features/adhkar/adhkar_categories_transition_test.dart` | 0 | 3 tests pass |
| `flutter test` (full suite, before new tests) | 1 | **32 passed, 9 failed** |
| `flutter test` (full suite, after Phase 0 additions) | 1 | 39 passed, 1 known-defect failure (documented below), 8 pre-existing failures unchanged |
| `flutter analyze` | 0 | 4 pre-existing warnings in `lib/` (unused fields/locals), 0 issues in `test/` |

The suite is **not** green and must not be reported as green. Details below.

---

## 4. Failing tests: classification

### 4.1 Outdated fixtures (candidates for Phase 1 repair, not silently fixed here)

These tests encode the *previous* reader chrome and Home layout. They are not
rewritten to pass in Phase 0 because doing so requires deciding what the new UI
should guarantee (a product matter for Phase 1).

| Test | File | Cause against current code |
|---|---|---|
| "Header shows compact Undo icon in Focus mode; bottom button is removed" | `wird_reader_undo_test.dart:~313` | Header was redesigned: undo is now an `_ImageHeaderAction` IconButton with tooltip **'تراجع خطوة'** using `RafiqiIcons.reset` (SVG), not `Icons.undo_rounded`. |
| "Scenario 3 — Cross-mode Undo between Focus and List" | `wird_reader_undo_test.dart:~362` | Same finder mismatch. |
| "Scenario 4 — List card restored at canonical position on Undo" | `wird_reader_undo_test.dart:~400` | Same finder mismatch (tap target gone). |
| "Scenario 6 — Long press details does not affect Undo history" | `wird_reader_undo_test.dart:~425` | Per-item key `dhikr-details-widget-undo-test-item-1` no longer exists; details long-press wrapper (`_DhikrDetailsTransition`) carries no per-item key. |
| "focus long press is read-only and normal tap still decrements" | `wird_reader_list_lifecycle_test.dart:~90` | Key `dhikr-details-focus-details-test-focus-three` no longer exists (same wrapper change). |
| "reading details return to the same scroll offset" | `wird_reader_list_lifecycle_test.dart:~119` | Key `dhikr-details-reading-scroll-test-reading-2` no longer exists. |
| "HomeScreen displays dynamic date and opens HijriCalendar on tap" | `hijri_calendar_test.dart:~41` | Home header was redesigned: it now renders `hijriDate.formatFull()` ("١٨ ربيع الآخر ١٤٤٨ هـ") plus `formatGregorianFull` ("٢٩ سبتمبر ٢٠٢٦ م"); the test expects the old weekday form (`formatGregorianDayMonth`, "الثلاثاء، ٢٩ سبتمبر"). Hijri text itself *is* rendered — fixture expectation is stale. |
| "Tapping incomplete base task shows confirmation dialog…" | `home_daily_wird_test.dart:~175` | `find.text('أذكار الصباح').last` no longer resolves to the task row: the redesigned Home renders several 'أذكار الصباح' texts (hero CTA area, task row) and the ordering assumption broke. |
| "Tasbeeh count increments and reset affects session only" | `widget_test.dart:~15` | Bottom-nav redesign: `find.bySemanticsLabel('السبحة')` matches nothing (nav labels are now الرئيسية/الأذكار/القرآن/الأذان/المزيد; Tasbeeh moved behind Home quick-access). |

**Recommended Phase 1 order:** update finders to key/tooltip-based locators
(`ValueKey('adhkar-category-…')`-style keys and tooltip 'تراجع خطوة') — small,
safe fixture modernizations once the intended UI guarantees are confirmed.

### 4.2 Known production defects (reproduced; fixes deferred)

- **P0-F1 — Tasbeeh undo does not reconcile daily records or linked tasks.**
  Reproduced by `test/features/tasbeeh/tasbeeh_counter_recording_test.dart` →
  "undo reconciles counters and linked-task progress" (kept failing on purpose,
  asserting the correct behavior).
  Mechanism: `TasbeehController.decrement()` awaits the recording queue, then
  calls `TasbeehCounterLogic.decrement` and `_applyState`. Neither path touches
  `TasbeehRepository.recordIncrement`'s day-record nor
  `DailyWirdRepository.syncTasbeehProgress`, so after undo: the day record keeps
  the pre-undo count (3 instead of 2) and a task completed by the 3rd tap stays
  `completed` with `progress = 3`. Audit alignment: maps to the audit's undo/
  task-progress finding. **Intended repair phase:** counter-ownership phase.
- **P0-F2 — Adhkar Hub hero opens the canonical (uncustomized) collection.**
  Documented by `test/features/adhkar/adhkar_entry_point_parity_test.dart` →
  "hub hero canonical path ignores customization — KNOWN DEFECT" (passes by
  asserting the current wrong behavior explicitly; must flip in the repair).
  Mechanism: `AdhkarCategoriesScreen._openCurrentCollection` resolves the reader
  category via `AdhkarLocalRepository.loadCanonicalCategory(category.id)`,
  bypassing `AdhkarCollectionOverridesRepository`, while Home
  (`MainShellScreen._openAdhkarReader` → `loadCategories`) and the grid tile
  (`_CategoryContainer._openReader` → the already-customized `widget.category`)
  honor saved customization. Violates the "same customized collection from every
  entry point" invariant. **Intended repair phase:** Adhkar-collections phase.
- **P0-F3 (unresolved product decision, related to P0-F1):** what undo should do
  *after* a linked task has been completed (and possibly shown as 'أحسنت، أكملت
  المهمة'). Current behavior silently keeps the completion; desired policy is
  undecided — see §6.3.

---

## 5. Behavioral baseline (as implemented today)

### 5.1 Tasbeeh counters

- **State model** (`TasbeehState`): per-phrase session counts
  (`sessionCounts[dhikrId] = currentCount`), `totalCount` (lifetime),
  `dailyTotal` (day-scoped, reset by `forCurrentDay()` when `dailyDateKey`
  changes), `targetMode` 33/99/open.
- **Increment** (`TasbeehCounterLogic.increment`): normalizes the day first;
  finite target wraps to 1 when `currentCount >= target` (never resets totals);
  open mode counts up; totals and daily always move together (+1/+1).
- **Persist** (`TasbeehRepository.save`): writes both the canonical
  `tasbeeh.state.v2` JSON *and* the legacy scalar keys — overlay compatibility
  is intentional. `load()` prefers `state.v2`.
- **Recording** (`TasbeehRecordingService.recordIncrement`): after saving state,
  appends/increments a `TasbeehDailyRecord` (`appCount` or `overlayCount` by
  source), re-initializes `DailyWirdRepository` (guards against racing overlay
  writes), computes the eligible total (in-app + manual), and projects it into
  linked tasbeeh-target tasks via `syncTasbeehProgress`.
- **Decrement/undo** (`TasbeehController.decrement`): rolls back
  current/total/daily (floored at 0) and the session count **only**. Does not
  touch the daily record or the linked task → P0-F1.

### 5.2 Daily Wird linkage

- **Eligible total** for a phrase/day = daily-record in-app count
  (app + overlay) + manual entries for that day.
- **`syncTasbeehProgress`** (monotone in structure): progress = clamp(eligible −
  baseline + externalContribution, 0, target); manual completion
  (`completionSource == 'manual'`) is preserved regardless of the computed
  progress; `finished` sets `completionSource: 'tasbeeh'`.
- **Baseline:** when a tasbeeh task is manually completed/uncompleted, the task
  stores `baselineTotalCount` = current eligible count so future taps count
  from there (no double-crediting of past taps).
- **Reader completion** (`setAdhkarReaderCompletion`): forward-only — unchecking
  on Home does not revoke reader completion, and repository re-init does not
  re-force it (covered by existing `home_daily_wird_test.dart` logic tests,
  which pass).
- **Completion of today:** `_evaluateCompletion` sets `readyForStreak` only when
  every task (base + custom) is completed; unchecking any item reverts it.

### 5.3 Adhkar reader

- **Progress** (`AdhkarProgressRepository`): date-keyed
  (`adhkar.readingProgress.<id>.<dayKey>`), validated against the category
  (unknown step ids dropped, remaining clamped), corrupted JSON → fresh.
- **Controller** (`WirdReaderController`): repetition-based decrement with
  per-item undo snapshots; deck transition never blocks persistence — the write
  is queued (`_pendingProgressWrite`) and may finish after the visible
  animation. Completion (last step) additionally (and asynchronously) marks the
  linked Daily Wird collection task done. Reading mode completes only via the
  explicit button (`completeFromReading`, source 'reading').
- **Undo persistence:** undo re-persists the snapshot immediately; however, no
  daily-revert is sent for a collection completed earlier that day
  (`setAdhkarReaderCompletion(false)` is a no-op by design).

### 5.4 Overlay sync

- State/settings messages are tagged by source (`app`/`overlay`); the main app
  only applies `source: overlay` messages and saves them (overlay is trusted to
  persist through the app isolate).
- Increment path posts state to the overlay immediately and queues recording;
  `flushPendingIncrements` runs on app lifecycle pause/inactive and on dispose.
- Overlay activation is checked (`FlutterOverlayWindow.isActive()`) before
  publishing state.

### 5.5 Adhkar collection resolution

- **Single authoritative resolver:** `AdhkarLocalRepository.loadCategories` =
  canonical assets → per-collection overrides (hidden/repeat-count/order/added)
  → custom collections appended.
- **Entry points:**
  - Home → `MainShellScreen._openAdhkarReader` → `loadCategories` (customized ✔)
  - Hub grid tile → passes the customized `widget.category` (customized ✔)
  - **Hub hero → `loadCanonicalCategory` (canonical ✘ — P0-F2)**
- Reader completion mapping works for both base ids (`morning`/`evening`) and
  custom adhkar-collection tasks (collectionId match).

---

## 6. Regression scenarios → evidence

| ID | Scenario | Automated? | Observed result | Finding |
|---|---|---|---|---|
| R1 | Ordinary Tasbeeh route: tap updates visible count + persists exactly once | ✔ `tasbeeh_counter_recording_test.dart` "accepted increment updates state and persists it exactly once" | PASS | — |
| R2 | Ordinary Tasbeeh → linked task → reopen: no stale state | ✔ `tasbeeh_counter_recording_test.dart` "linked daily task progress advances… reaches target" + "reopening a session restores persisted state…" | PASS (2 tests) | — |
| R3 | Undo reconciles activity history and linked-task progress | ✔ same file, "undo reconciles counters and linked-task progress" | **FAIL (intentional known-bug test)** — record stays 3, task stays completed | **P0-F1** |
| R4 | Adhkar reader: decrement → undo → progress restored | Covered by existing `wird_reader_undo_test.dart` Scenarios 1–2, 5, 7 (controller-level) | PASS (5 tests) | — |
| R5 | All entry points resolve the same customized collection | ✔ `adhkar_entry_point_parity_test.dart` "loadCategories resolves the customized morning collection once" | PASS for Home/grid path | **P0-F2** for the hero path |
| R6 | Hub-hero entry point parity | ✔ same file, "hub hero canonical path ignores customization — KNOWN DEFECT" | Passes by asserting the divergence explicitly; must flip to correct expectation during the collections-phase repair | **P0-F2** |
| R7 | Cold Reader open, Reader→details→back, Tasbeeh tapping/Focus Mode timings | ✘ profiling | **NOT RUN** — see §7 | — |

### 6.1 Invariants future phases must protect

1. **Visible state reflects accepted changes** — an accepted tap immediately
   updates controller state and UI (`R1`).
2. **No double recording** — one accepted increment produces exactly one daily
   record increment (`R1`).
3. **No stale overwrite** — snapshot restores must not clobber newer accepted
   state (`R2`; the overlay race guard in `recordIncrement` re-initializes
   DailyWird before projecting).
4. **Undo consistency** — undo must move counters, daily records, and linked
   task progress together (currently violated → P0-F1).
5. **Entry-point parity** — every reader entry resolves the same customized
   collection (currently violated by the hub hero → P0-F2).
6. **Route-close durability** — pending persistence completes after the route
   pops (dispose → `flushPendingIncrements`; reader `_pendingProgressWrite`
   chain). Closing a route must never cancel persistence nor publish to a
   disposed UI (existing guards: `mounted` checks, `_pendingProgressWrite`).

### 6.2 Current guarantees (already enforced)

- Legacy scalar persistence keys remain written (overlay compatibility).
- Day rollover resets `dailyTotal` without touching lifetime totals.
- Manual Daily-Wird completions are not revoked by reader/counter replay.
- Reader progress validation drops unknown steps and clamps counts.
- Corrupted progress JSON degrades to a fresh day, never a crash.

### 6.3 Unresolved product decisions (do not assume; ask the owner)

1. **Undo after task completion** (P0-F3): should undo revoke a just-earned
   linked-task completion, or is completion sticky? Current behavior: sticky.
   No UI communicates this.
2. **Overlay-count attribution**: overlay taps recorded via the main-app isolate
   (`_applyIncomingState` → save, but **no** `recordIncrement`) — overlay
   increments performed while the app process is alive are persisted to state
   but not to daily records. Whether overlay taps should count toward Daily
   Wird tasks is undecided. (Reproduce manually: start overlay, tap, reopen
   app: state advances, record does not.)
3. **Reader undo vs daily completion**: reader undo of the final step after
   completion does not un-complete the Daily Wird task (by design:
   forward-only). Confirm this is the intended UX.

---

## 7. Device / performance baseline — NOT RUN

No Android device or emulator was available (`flutter devices` listed only
Windows desktop and two web browsers); profiling therefore **NOT RUN** and no
performance claims are made. Reproduction steps for the user (when a device is
attached):

```bash
flutter devices                       # confirm an Android device
flutter run --profile                 # build in Profile mode
# DevTools → Performance: record each scenario twice:
#  1. Cold open: Wird reader from Home hero (first launch after install)
#  2. Warm open: same route, back, reopen
#  3. Reader → long-press details → back
#  4. Tasbeeh: 20 quick taps; Focus Mode enter + exit
# Record UI-thread and raster-thread p50/p90 per scenario, noting device model,
# OS version, and the tested revision (HEAD + dirty hash of lib/).
```

Debug-mode observations must not be used as release-performance evidence.

---

## 8. Remaining blockers and next-phase prerequisites

1. **Fixture modernization batch (Phase 1):** the 9 outdated tests in §4.1 need
   key/tooltip-based finders matching the redesigned reader header, Home
   header/nav, and Hijri date presentation.
2. **P0-F1 repair (counter-ownership phase):** make `TasbeehController.decrement`
   (or the recording service) reconcile `TasbeehDailyRecord` and
   `syncTasbeehProgress` on undo; then flip the known-bug test to green.
3. **P0-F2 repair (Adhkar-collections phase):** resolve the hub hero through
   `loadCategories` (or pass the customized category), then invert the
   documented-defect test.
4. **P0-F3 decision required before implementing 2:** undo-after-completion
   policy must be settled explicitly.
5. **Overlay tap attribution decision** (§6.3.2) before the overlay/sync phase.
6. **Device availability** required for the profiling baseline (§7).

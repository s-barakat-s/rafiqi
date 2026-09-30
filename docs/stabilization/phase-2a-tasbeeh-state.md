# مَآب — Phase 2A: Tasbeeh State Ownership (Handoff)

**Date:** 2026-09-29 · **Audit finding:** F5 · **Scope:** main Flutter engine only

## Root causes (confirmed against current code)
1. Ordinary `TasbeehHomeScreen` received a `state` snapshot; no route-level subscription → stale visible count.
2. `TasbeehTaskSessionScreen` created its **own** `TasbeehController` → two competing owners could save conflicting snapshots.
3. Each controller's `initialize()` re-registered the main-app named port (`removePortNameMapping` first); closing a task route disposed its controller and **unregistered the app's port**.

## Ownership before → after
- Before: shell controller + per-task controllers; each route held a snapshot.
- After: one application-scoped authority `TasbeehAppScope.controller` (lazy singleton, main engine only). Routes observe it via `TasbeehSessionScope` adapters; only the adapter is disposed with the route.
- `TasbeehController.initialize()` is now idempotent (`_initialization ??=`): port/subscriptions registered once; reopen can't overwrite newer state with a stale full reload.

## Shared vs session-local
- Shared: counter state, phrases, settings (incl. haptic), the main-app port, recording path (one `increment()` → one `recordIncrement`).
- Session-local: task context (phrase/target/progress display), Focus-Mode chrome/animation state.

## Port ownership
Registered once by the app-scoped authority; opening/closing a task neither replaces nor removes it. **Boundary:** a Dart singleton is NOT shared across Flutter engines — the overlay runs in a separate engine; cross-engine sync is untouched and remains Phase 2B scope.

## Validation (actual results)
- `flutter analyze`: 0 errors; only the 4 pre-existing warnings.
- New `tasbeeh_state_ownership_test.dart`: **7/7 pass** (live count, phrase change, ordinary→task→return, task-first, single recording, port survives task close, repeated-init race).
- Full suite: **56 pass / 10 fail** — the identical 10 documented Phase 0 failures (9 stale fixtures + intentional P0-F1/F9 known-bug test); **no new regressions**.
- Device (emulator-5554, API 35): debug APK built & installed; ordinary Tasbeeh live count (٠→٢ after taps) and phrase switching with preserved session counts verified via UI dump.

## NOT fully verified manually
Linked-task route interaction on device was not reached via ADB navigation (row tap kept opening Journey due to test-harness coordinate ambiguity, not an app defect). The 4 automated linked-task tests are the evidence of record.

## Handoff
- **Phase 2B:** overlay engine still talks to the port registered by the scope; verify overlay→app state messages end-to-end on device; overlay tap attribution (Phase 0 §6.3.2 decision) still pending.
- **Phase 2C:** undo/reconciliation unchanged (F9); `tasbeeh_counter_recording_test.dart` undo test still fails intentionally (marked PROVISIONAL).
- Removed one stale shell behavior: tab-2 selection no longer triggers a full `reload()` (superseded by idempotent init; avoids stale overwrites).

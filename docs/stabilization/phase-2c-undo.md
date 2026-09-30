# مَآب — Phase 2C: Consistent Undo

**Status:** complete · **Date:** 2026-09-29 · **Finding:** F9
- Root cause: `decrement()` persisted counter state only; daily activity and linked-task progress retained the increment.
- Undo now runs on the application authority’s existing serialized recording queue.
- It reverses one app-origin increment for the selected phrase/day, then saves the decremented state with a newer revision.
- The eligible activity total is recomputed and projected through the existing Daily Wird synchronization rules.
- Tasbeeh-completed tasks can fall below target; existing manually completed tasks remain protected by the domain synchronizer.
- With no reversible app activity or at the lower bound, undo is a safe no-op; overlay activity/settings remain unchanged and no overlay undo protocol was added.
- Changed: controller, recording service, repository, and focused Tasbeeh tests.
- Focused F9 tests: **5/5 passed**; Phase 2A/2B regressions: **14/14 passed**.
- Tasbeeh suite: **21/21 passed**; the former provisional F9 failure is removed.
- Targeted analyzer: no new issues; only the 2 pre-existing Tasbeeh UI warnings remain.
- No Android rebuild or device check was run because native code was unchanged.
- Phase 3 limitation remains: SharedPreferences writes are not one atomic cross-engine transaction during a mid-write crash.

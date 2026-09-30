# مَآب — Phase 2B: Overlay Synchronization

**Status:** complete for Phase 2B · **Date:** 2026-09-29

- Repaired the Android permission contract: isolated pending result, predictable duplicate rejection, actual permission check, and lifecycle completion/error paths.
- Registered and removed the Activity-result listener with the Activity binding lifecycle.
- `closeOverlay` now replies when the service is already stopped.
- Both BasicMessageChannel forwarding directions now reply, handle missing engines, and avoid treating a transport acknowledgement as persistence.
- Only the activity-backed main engine can own the native main-app messenger; the overlay engine cannot replace it.
- Overlay taps are `increment_operation` intents; the main-engine controller commits counter state and activity when reachable.
- With the main engine unavailable, the overlay commits the same stable `opId` through the shared recording service.
- Processed operation IDs are persisted (bounded ledger); duplicate delivery records once.
- A persisted revision orders state snapshots; legacy overlay snapshots cannot overwrite the authority.
- App and overlay increments share one controller queue, preventing concurrent accepted taps from losing one another.
- Overlay rendering is optimistic; accepted state comes from the durable operation reply/fallback result.
- Settings payloads contain settings only; the settings screen no longer republishes its captured counter snapshot.
- Main files: plugin/service Java, overlay messenger/app, controller, recording service, repository, settings screen.
- Focused Phase 2B + Phase 2A tests: **12/12 passed**.
- Tasbeeh suite: **17 passed / 1 known failure** (Phase 2C F9 undo only); no new failure.
- `flutter analyze`: no errors; the same 4 pre-existing warnings remain.
- Android debug build: passed (`build/app/outputs/flutter-apk/app-debug.apk`).
- Device checks: none performed in this phase.
- **NOT VERIFIED MANUALLY:** permission grant/deny, duplicate permission UI request, overlay tap with app absent, reconnect, and route-close transport.
- Phase 3 limitation: SharedPreferences cannot make cross-engine state/activity/op-ledger writes one atomic transaction; crash-mid-commit recovery needs stronger storage.
- Phase 2C may proceed with F9 undo; it must preserve operation identity, revision ordering, and the Phase 2A app authority.

# Phase 5 — UI Performance

## Status: complete

## Implemented (interrupted model, verified and completed here)
- Reader uses the shared `AppDecorativeBackground` with a transparent Scaffold for every entry path (one coherent background policy).
- `AppThemeArtwork` (new): theme artwork cross-fades (140ms) instead of jumping while colors interpolate; `AppColors.lerp` selects the destination asset at `t > 0` so the fade targets the incoming theme.
- Image decode sizing: `cacheWidth` clamped to rendered physical width (64px granularity, 64–4096).
- Focus Mode: animation isolated from the full home tree; chrome collapse + count scaling verified end-state stable.
- Preference notifications narrowed: `appearanceChanges`, `adhkarFeedbackChanges`, `readerModeChanges` `ValueListenable<int>` scopes; app shell rebuilds only on appearance; MainShellScreen reads feedback via `ValueListenableBuilder`.
- Startup intro: fixed wait replaced by decode-ready trigger (240ms hold + 320ms fade) with a 1500ms decode-failure fallback added in this continuation.
- Reader list view hoists `remainingItems` out of the item builder (behavior-preserving).

## Continuation fixes
- Startup intro could wedge if splash decode never completed → added bounded fallback timer; made the startup test deterministic.

## Key files
- lib/shared/widgets/app_theme_artwork.dart, lib/shared/widgets/app_decorative_background.dart
- lib/core/theme/app_theme.dart, lib/app/app.dart, lib/app/widgets/rafiqi_startup_intro.dart
- lib/features/settings/data/repositories/app_preferences_repository.dart
- lib/features/adhkar/presentation/screens/wird_reader_screen.dart (+ reader widgets)
- lib/features/tasbeeh/presentation/screens/tasbeeh_focus_screen.dart

## Verification
- Focused Phase 5 tests: test/features/ui/phase5_ui_performance_test.dart, test/features/settings/app_preferences_notification_scope_test.dart, test/features/tasbeeh/tasbeeh_focus_animation_test.dart — all pass.
- Analyzer on affected modules: 0 errors; 2 pre-existing `unused_field` warnings (`_safaLight`/`_safaDark`, unused at HEAD too).
- Pre-existing debt (not Phase 5): 7 failures in wird_reader_undo_test / list_lifecycle / categories_transition selectors — old Reader UI selector debt, unchanged by this phase.

## Performance evidence (structural only)
- Fewer widgets rebuilt per preference change (scoped ValueListenables vs. one global ChangeNotifier).
- Stable list children; hoisted per-build list computation.
- Reduced decode targets for large hero artwork (`ResizeImage` cacheWidth).
- Startup fixed wait removed; intro exits on first decoded frame.

## Device measurement
- Not performed. No FPS/GPU claims are made.

## Remaining for Phase 6
- None carried from Phase 5.

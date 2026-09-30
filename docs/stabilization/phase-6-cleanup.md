# Phase 6 — Cleanup & Technical Debt

## Status: complete

## Removed (verified: no Dart/config/tooling references)
- Code: shared/widgets/calligraphy_title.dart, tasbeeh/presentation/widgets/tasbeeh_nav_icon.dart, AppTranslucentSurface + its two unused enums (app_glass_surface.dart), analyzer-confirmed unused `_safaLight`/`_safaDark` theme constants.
- Assets: assets/calligraphy/ (4 PNGs, dir removed), assets/image/home/backgroung.png, "—Pngtree—calligraphy…" PNG, unreachable mahogany/ and shfaq/ theme image sets, unreferenced SVGs (community, daily_wird, bookmark, share) + their dead RafiqiIcons constants.
- Dependencies: `animations`, `cupertino_icons` (no imports anywhere; pub get clean).

## Intentionally preserved (conservatism guard)
- Branding variants incl. byte-identical adaptive/monochrome pairs (tooling/store safety).
- `_derivedColors` fallback path, `warning` reserved role, `parchment` alias.
- flutter_overlay_window, shared_preferences, hijri, flutter_svg, launcher icon inputs, Adhkar JSON, active theme artwork, SVG system.
- Theme identity stays on stable path strings — no redesign (per guard).

## Verification
- Analyzer (core/theme, shared, phase-5 UI tests): 0 issues (the two old `unused_field` warnings were exactly the removed `_safa*` constants).
- Focused Phase 5 UI tests: all pass.
- `flutter build apk --debug`: succeeded.
- APK size comparison: not measured (repository cleanup completed; no size claims).

## Remaining debt before Phase 7
- Pre-existing old Reader UI test selector failures (out of scope, unchanged).

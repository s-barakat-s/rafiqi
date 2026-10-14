# Maab Android App Size Audit

Audit date: 2026-10-13 (Africa/Cairo)  
Repository: `D:\projects\tasbeh`  
Scope: diagnostic only; no application source, assets, dependency declarations, or Android configuration were changed.

## Executive Summary

The current arm64 release APK is **94,496,108 bytes (90.119 MiB)**. The normal multi-ABI Play upload AAB is **131,612,296 bytes (125.515 MiB)**. The single-ABI arm64 analysis AAB was **94,292,448 bytes (89.924 MiB)**.

The dominant release cost is not Quran content. It is two bundled development Adhkar recordings totaling **56,445,665 bytes (53.830 MiB)**, or **59.73% of the complete arm64 APK**. The next largest costs are raster UI images, the Flutter engine, Dart AOT code, and fonts.

The repository contains one complete QPC V4 Tajweed research pack: 604 indexed PNG pages plus semantic geometry, **106,369,012 bytes (101.441 MiB)** in total. Current Gradle configuration stages it only into the Android `debug` source set, and its Dart loader rejects non-debug use. Direct inspection of both release archives confirms that **zero Mushaf page images and zero page-geometry files enter release**. Release contains only `assets/data/quran/qpc_v4_surah_metadata.json`, at 2,282 raw bytes (856 compressed bytes).

| Required headline | Exact result |
|---|---:|
| arm64 release APK | 94,496,108 B / 90.119 MiB |
| arm64 analysis AAB | 94,292,448 B / 89.924 MiB |
| normal multi-ABI Play AAB | 131,612,296 B / 125.515 MiB |
| Packaged Flutter assets in APK | 75,230,230 raw B / 71.745 MiB; 71,636,739 compressed B / 68.318 MiB |
| Mushaf visual pages in release | 0 B |
| Local 604-page research pack | 104,359,001 B / 99.524 MiB |
| Local Quran geometry | 1,962,440 B / 1.872 MiB |
| Packaged Quran non-visual data | 2,282 raw B / 0.002 MiB |
| Packaged raster images | 12,394,496 B / 11.820 MiB |
| Packaged custom + Material fonts | 5,928,112 raw B / 5.654 MiB; 2,622,762 compressed B / 2.501 MiB |
| Packaged audio | 56,445,665 B / 53.830 MiB |
| APK `.so` libraries, including `libapp.so` | 20,222,776 B / 19.286 MiB |
| Evidence-backed safe APK recovery | 17,059,502 B / 16.269 MiB |

### Top 10 contributors in the arm64 APK

Percentages use the complete 94,496,108-byte APK. ZIP overhead means listed entry groups do not sum to exactly 100%.

| Rank | Contributor | Compressed bytes | MiB | APK % |
|---:|---|---:|---:|---:|
| 1 | Development Adhkar audio (2 files) | 56,445,665 | 53.830 | 59.73% |
| 2 | Raster image assets | 12,394,496 | 11.820 | 13.12% |
| 3 | Flutter engine (`libflutter.so`, arm64) | 11,747,864 | 11.204 | 12.43% |
| 4 | Dart AOT (`libapp.so`, arm64) | 8,127,368 | 7.751 | 8.60% |
| 5 | Fonts | 2,622,762 | 2.501 | 2.78% |
| 6 | Other (principally `classes.dex`) | 1,383,602 | 1.320 | 1.46% |
| 7 | Android resources | 1,056,920 | 1.008 | 1.12% |
| 8 | Other native `.so` libraries | 347,544 | 0.331 | 0.37% |
| 9 | Other Flutter assets | 172,960 | 0.165 | 0.18% |
| 10 | META-INF / metadata | 15,071 | 0.014 | 0.02% |

## Audit Baseline and Environment

The initial `git status --short` was recorded before any other command. The tree was already heavily modified: configuration, Quran implementation, UI files, tests, and tools had tracked modifications/deletions, and the current Quran implementation/resources were untracked. The audit used that exact state. In particular, the deleted theme assets shown by Git were not restored and therefore were not measured as current files. The pre-existing untracked file `tatus --short` was not touched.

The final status is the same except for this report. Build output is ignored and did not appear in Git status.

| Tool | Version |
|---|---|
| Flutter | 3.47.6 stable, framework `5fc346839b`, engine `692136cb65` |
| Dart | 3.13.5 stable, Windows x64 |
| DevTools | 2.60.0 |
| Project | `tasbeh` 1.0.0+1 |

The Flutter commands initially could not access `C:\src\flutter\bin\cache\lockfile` inside the restricted process sandbox. They were rerun with the permitted Flutter SDK/cache access; no project repair or SDK configuration change was made.

Build warnings, not blockers: Flutter 3.47.6 reports that support for Gradle 8.14.0, Android Gradle Plugin 8.11.1, and Kotlin 2.2.20 will be dropped in a future Flutter release. All requested builds completed.

## Current Size Breakdown

### Arm64 APK by archive category

| Category | Compressed B | Compressed MiB | Raw B | Raw MiB | APK % |
|---|---:|---:|---:|---:|---:|
| Audio | 56,445,665 | 53.830 | 56,445,665 | 53.830 | 59.73% |
| Images | 12,394,496 | 11.820 | 12,394,496 | 11.820 | 13.12% |
| Flutter engine | 11,747,864 | 11.204 | 11,747,864 | 11.204 | 12.43% |
| Dart AOT / `libapp.so` | 8,127,368 | 7.751 | 8,127,368 | 7.751 | 8.60% |
| Fonts | 2,622,762 | 2.501 | 5,928,112 | 5.654 | 2.78% |
| Other | 1,383,602 | 1.320 | 2,875,766 | 2.743 | 1.46% |
| Android resources | 1,056,920 | 1.008 | 1,142,638 | 1.090 | 1.12% |
| Other native `.so` | 347,544 | 0.331 | 347,544 | 0.331 | 0.37% |
| Other Flutter assets | 172,960 | 0.165 | 459,675 | 0.438 | 0.18% |
| META-INF / metadata | 15,071 | 0.014 | 41,413 | 0.039 | 0.02% |
| Quran data / Mushaf | 856 | 0.001 | 2,282 | 0.002 | <0.01% |

### Normal multi-ABI AAB by archive category

The AAB is an upload artifact, not a per-device install. It contains three copies of the Flutter engine and Dart AOT code (arm64-v8a, armeabi-v7a, x86_64), plus 31.13 MiB compressed of upload metadata/debug symbols. Play splits ABIs for delivery.

| Category | Compressed B | MiB | Raw B | Raw MiB |
|---|---:|---:|---:|---:|
| Audio | 55,519,484 | 52.948 | 56,445,665 | 53.830 |
| Bundle metadata, symbols, maps | 32,643,914 | 31.132 | 104,603,079 | 99.757 |
| Flutter engines, all ABIs | 15,848,648 | 15.114 | 33,415,188 | 31.867 |
| Images | 12,011,157 | 11.455 | 12,394,496 | 11.820 |
| Dart AOT, all ABIs | 10,243,722 | 9.769 | 25,446,744 | 24.268 |
| Fonts | 2,622,762 | 2.501 | 5,928,112 | 5.654 |
| Other | 1,399,401 | 1.335 | 2,920,005 | 2.785 |
| Android resources | 940,908 | 0.897 | 1,402,546 | 1.338 |
| Other Flutter assets | 172,960 | 0.165 | 459,675 | 0.438 |
| Other native `.so` | 86,084 | 0.082 | 347,544 | 0.331 |
| Quran data / Mushaf | 856 | 0.001 | 2,282 | 0.002 |

### Packaged Flutter assets

The APK contains 100 Flutter asset entries.

| Asset class | Count | Raw B | Raw MiB | % of raw Flutter assets |
|---|---:|---:|---:|---:|
| Audio | 2 | 56,445,665 | 53.830 | 75.03% |
| Raster images | 28 | 12,394,496 | 11.820 | 16.48% |
| Fonts, including Material Icons | 29 | 5,928,112 | 5.654 | 7.88% |
| Other manifests/SVG/shader/notices | 40 | 459,675 | 0.438 | 0.61% |
| Quran metadata | 1 | 2,282 | 0.002 | <0.01% |
| **Total** | **100** | **75,230,230** | **71.745** | **100%** |

## Project Asset Inventory

The primary repository inventory excludes `.git`, `build`, `.dart_tool`, IDE metadata, and the generator cache under `quran_resources/.cache` because it is temporary/source tooling output. It includes `assets/` and the authoritative generated QPC pack.

Primary asset total: **1,361 files, 185,376,603 bytes (176.789 MiB)**.

| Directory/group | Files | Raw B | MiB | Primary assets % | Release status |
|---|---:|---:|---:|---:|---|
| QPC page rasters | 604 | 104,359,001 | 99.524 | 56.30% | Debug only; not in release |
| `assets/audio` | 2 | 56,445,665 | 53.830 | 30.45% | Both in release |
| `assets/image` | 23 | 11,492,664 | 10.960 | 6.20% | All 23 current files enter release; deleted theme files are absent |
| `assets/fonts` | 69 | 9,390,889 | 8.956 | 5.07% | 28 custom files in release |
| QPC geometry | 604 | 1,962,440 | 1.872 | 1.06% | Debug only; not in release |
| `assets/branding` | 12 | 1,014,382 | 0.967 | 0.55% | All 12 in release |
| `assets/data` | 17 | 651,301 | 0.621 | 0.35% | 8 current files in release; `Old/` trees excluded |
| QPC manifest/README/license | 3 | 47,571 | 0.045 | 0.03% | Debug only; not in release |
| `assets/icons` | 26 | 9,748 | 0.009 | 0.01% | In release |
| `assets/shaders` | 1 | 2,942 source B | 0.003 | <0.01% | Compiled shader in release |
| `assets/images` | 0 | 0 | 0 | 0% | Directory does not exist |

`assets/` alone is 150 files / 79,007,591 bytes / 75.348 MiB. The excluded `quran_resources/.cache` is still noteworthy for repository disk usage: 1,933 files / 232,228,973 bytes / 221.471 MiB. It contains the 55,313,001-byte upstream `source.zip`, 604 QPC WOFF2 page fonts totaling 50,877,544 bytes, and browser work profiles. None appears in either release archive.

## Mushaf Breakdown

### Current pack found in the repository

`quran_resources/qpc_v4_tajweed_pack/manifest.json` identifies the only complete visual pack as `maab.qpc_v4_tajweed.research.v1`, layout `phone-native`, schema 2, generator 2.3.0, with `research_only: true`, `production_approved: false`, unproven edition verification, and unapproved redistribution status.

The brief called this the current production pack, but the repository itself does not. Current code and Gradle make it a debug research pack:

- `android/app/build.gradle.kts` copies it only into `android.sourceSets.debug`.
- `DevQpcV4TajweedPackSource._requireResearchDebug()` throws outside `kDebugMode`.
- The release archives contain no `quran_research/` entries.

### A. 604 raster pages

| Measurement | Result |
|---|---:|
| Files | 604 |
| Total | 104,359,001 B / 99.524 MiB |
| Average | 172,779.80 B / 168.73 KiB |
| Smallest | `001.png`, 120,684 B |
| Largest | `602.png`, 324,736 B |
| Format | PNG, indexed color, 8-bit, 256 palette entries, `tRNS` alpha |
| Source canvas | 1,074 × 1,944 |
| Cropped width range | 1,010–1,048 px |
| Cropped height range | 1,001–1,833 px |
| Average dimensions | 1,015.5 × 1,806.0 px |
| Release contribution | 0 B |

### B. Semantic geometry

604 gzip-compressed JSON files total **1,962,440 bytes (1.872 MiB)**. Release contribution: **0 bytes**.

### C. Manifests, fingerprints, and metadata

| File/class | Bytes |
|---|---:|
| `manifest.json` | 44,472 |
| `README_RESEARCH_ONLY.md` | 1,005 |
| Upstream license notice | 2,094 |
| Release Surah metadata JSON | 2,282 |
| Local non-visual total, including geometry | 2,012,293 B / 1.919 MiB |
| Packaged release Quran non-visual total | 2,282 B / 0.002 MiB |

### D. Quran databases

No `.db`, `.sqlite`, or `.sqlite3` file exists outside excluded build/tool-cache output, and none is packaged. The Dart code contains SQLite schemas/installers, but the current working tree has no generated Quran Core or Mushaf layout database artifact to measure. Therefore each Quran DB size is **0 bytes / absent** in this repository state.

### E. Duplicate/generated/staging packs

Only one complete generated page pack exists. There is no second pages directory and no second visual pack in release. The 221.471 MiB `.cache` tree is generator input/work state, not another packaged pack. Its 604 page-specific WOFF2 fonts are source material and are not staged by Gradle.

**Answer: zero Mushaf visual packs currently enter the release application.**

## Image Audit

### Packaged raster assets by extension

| Extension | Count | Bytes | MiB |
|---|---:|---:|---:|
| PNG | 28 | 12,394,496 | 11.820 |
| WebP | 0 | 0 | 0 |
| JPG/JPEG | 0 | 0 | 0 |
| Other raster | 0 | 0 | 0 |

The current working tree contains no live WebP file under `assets`; Git reports previously tracked theme WebPs as deleted before this audit.

Largest packaged image offenders are `evening dark.png` (1,851,379 B), `evening light.png` (1,521,369 B), `Quran light.png` (1,517,680 B), `rafiqi_zekr_light.png` (1,514,306 B), `Quran dark.png` (1,403,727 B), `morning dark.png` (1,169,859 B), and `Morning light.png` (1,029,248 B).

The seven large hero/background PNGs cluster around 1.57 megapixels. Notable dimensions are 2,055 × 765 (`Quran dark`), 2,048 × 768 (`Quran light`), 1,942 × 809 (`rafiqi_zekr_light`), and 1,632 × 964 (evening variants). These are larger than many rendered phone regions and merit density/render-size review, but they are not pathological 4K/8K images.

## Font Audit

All 28 custom packaged font files are explicitly declared in `pubspec.yaml`; Material Icons is generated/tree-shaken by Flutter. Family totals:

| Family | Files | Raw B | Raw MiB | Compressed B | Purpose/evidence |
|---|---:|---:|---:|---:|---|
| Thmanyah Serif Display | 5 | 1,231,516 | 1.174 | 519,092 | Declared; no current call site found; possibly unused, review required |
| Thmanyah Serif Text | 5 | 1,218,564 | 1.162 | 509,860 | Declared; no current call site found; possibly unused, review required |
| Thmanyah Sans | 5 | 1,202,972 | 1.147 | 501,566 | UI and Quran navigation/search labels |
| IBM Plex Sans Arabic | 4 | 928,844 | 0.886 | 403,300 | Main UI typography |
| Amiri | 2 | 825,192 | 0.787 | Reading/Quran text-mode typography, not page raster glyphs |
| Outfit | 5 | 275,988 | 0.263 | Numeric/UI typography |
| Aref Ruqaa | 2 | 234,548 | 0.224 | Display/UI typography |
| Material Icons | 1 | 10,488 | 0.010 | Tree-shaken from 1,645,184 B |

The 41 additional font files under `assets/fonts` are not declared and do not appear in release: italic Amiri faces, IBM thin/light faces, unused Outfit weights/variable font, WOFF2 Thmanyah copies, and one TTF experiment. The QPC source cache contains 604 page-specific WOFF2 fonts (50,877,544 B), but none is packaged. Therefore **old page-specific Quran font experiments are not bundled alongside the raster renderer**.

## Audio Audit

| File | Bytes | MiB | Packaged? | Evidence/purpose |
|---|---:|---:|---|---|
| `assets/audio/adhkar/mishary_alafasy/morning.m4a` | 40,106,925 | 38.249 | Yes | Manifest-selected `localAssetForDevelopment`; used by current playback adapter |
| `assets/audio/adhkar/mishary_alafasy/morning.mp3` | 16,338,740 | 15.582 | Yes | Included only because the whole directory is declared; manifest and tests select `.m4a` |
| **Total** | **56,445,665** | **53.830** | **Yes** | **59.73% of the APK** |

There is no bundled Quran audio. Audio is the main base-install contributor by a wide margin.

## Duplicate Assets

SHA-256 was calculated over every current file in `assets/` plus the generated QPC pack. Six byte-identical groups were found. Repository-wide duplicate recoverability is **744,966 bytes (0.710 MiB)**; only three groups are packaged, with **680,417 bytes (0.649 MiB)** of theoretical packaged duplicate recovery.

| SHA-256 (prefix) | Files | Each B | Recoverable B | Packaged paths |
|---|---:|---:|---:|---|
| `1199de8efd94…` | 5 | 28,359 | 113,436 | `adaptive_foreground.png`, `adaptive_icon.png`, `monochrome_foreground.png`, `monochrome_icon.png`, `rafeqe.png` |
| `a1dd2fa25680…` | 2 | 146,810 | 146,810 | `splash_dark.png`, `splash_light.png` |
| `bcc2175fcf5c…` | 4 | 140,057 | 420,171 | `app_icon.png`, `launcher_legacy.png`, `logo_light.png`, `logo_symbol.png` |
| `6b85203b1492…` | 2 | 13,321 | 13,321 | `daily_dhikr.json` and `Old/daily_dhikr.json`; old copy is not packaged |
| `2ad581d9f4e…` | 3 | 10,244 | 20,488 | `.DS_Store` files; not packaged |
| `d65165279105…` | 6 | 6,148 | 30,740 | `.DS_Store` files; not packaged |

“Recoverable” assumes references are consolidated; no deletion is recommended solely from hash equality.

## Pubspec Asset-Scope Check

| Classification | Finding | Packaged cost | Basis |
|---|---|---:|---|
| CONFIRMED USED | `.m4a` morning recording | 40,106,925 B | Manifest explicitly selects this path and runtime loads manifest paths |
| CONFIRMED UNNECESSARY | `.mp3` morning recording | 16,338,740 B | Whole audio directory packages it; the only manifest selects `.m4a`; tests assert `.m4a`; no alternate loader enumerates audio filenames |
| CONFIRMED USED | Startup splash light/dark | 293,620 B | Direct runtime references |
| POSSIBLY UNUSED — REQUIRES REVIEW | Ten non-splash branding files packaged by `assets/branding/` | 720,762 B | Launcher generator inputs and identical aliases are kept as runtime assets although no runtime reference was found |
| POSSIBLY UNUSED — REQUIRES REVIEW | Thmanyah Serif Display/Text families | 2,450,080 raw B / 1,028,952 compressed B | Declared and packaged; only family constants were found, no call site |
| CONFIRMED UNNECESSARY FOR RELEASE | QPC cache/work profiles | 232,228,973 B repository disk only | Not declared and absent from release; this is tooling cache, not app-size cost |
| UNKNOWN | Other declared images/fonts | — | Dynamic theme/family selection can defeat filename searches; no “unused” claim made |

The `assets/data/adhkar/Old/` and `Old/Old/` directories are not packaged because Flutter directory declarations are non-recursive unless each subdirectory is declared. Likewise, undeclared font experiments are not packaged.

## Dependencies / Native Code

### APK native libraries

| Library | ABI | Bytes | MiB | Attribution |
|---|---|---:|---:|---|
| `libflutter.so` | arm64-v8a | 11,747,864 | 11.204 | Flutter engine |
| `libapp.so` | arm64-v8a | 8,127,368 | 7.751 | App Dart AOT snapshot |
| `libdartjni.so` | arm64-v8a | 131,400 | 0.125 | `jni` package, introduced by `path_provider_android` |
| `libdartjni.so` | x86_64 | 116,792 | 0.111 | Same; unexpectedly remains in arm64 APK |
| `libdartjni.so` | armeabi-v7a | 81,600 | 0.078 | Same; unexpectedly remains in arm64 APK |
| `libdatastore_shared_counter.so` | arm64-v8a | 7,112 | 0.007 | AndroidX DataStore via `shared_preferences_android` |
| `libdatastore_shared_counter.so` | x86_64 | 6,224 | 0.006 | Same |
| `libdatastore_shared_counter.so` | armeabi-v7a | 4,416 | 0.004 | Same |

Total APK `.so` bytes are **20,222,776 (19.286 MiB)**. Of that, only **347,544 bytes (0.331 MiB)** are plugin/other native libraries; Flutter engine plus Dart AOT account for the rest. Native code matters, but it is not the abnormal cause of the current 90.1 MiB APK.

The normal AAB has ABI-specific `libflutter.so` raw sizes of 11,747,864 B (arm64), 8,615,900 B (armeabi-v7a), and 13,051,424 B (x86_64), and `libapp.so` sizes of 8,127,368 B, 8,929,864 B, and 8,389,512 B respectively.

Relevant dependency observations:

- `just_audio` and `audio_service` provide playback code, but the 53.83 MiB recording cost comes from the app's asset declaration, not plugin binaries.
- `path_provider_android` pulls `jni`/`jni_flutter`, producing `libdartjni.so`.
- `shared_preferences_android` pulls AndroidX DataStore, producing `libdatastore_shared_counter.so`.
- `background_downloader` contributes about 147 KiB of Dart AOT code and Android WorkManager/Room dependency resources, but no materially large `.so`.
- `sqflite_android` packages no release SQLite native library in this build; Android platform SQLite is used. A debug-only `libsqlite3.so` exists in build intermediates because `sqflite_common_ffi` is a dev dependency, but it is absent from release.
- `flutter_svg`/`vector_graphics_compiler` account for about 163 KiB in Flutter's AOT attribution.

## Build Release Size Analysis

### Commands and artifacts

| Command | Result |
|---|---|
| `flutter build apk --release --analyze-size --target-platform=android-arm64` | Success; `build/app/outputs/flutter-apk/app-release.apk`, 94,496,108 B |
| `flutter build appbundle --release --analyze-size` | Expected compatibility failure: “Cannot perform code size analysis when building for multiple ABIs. Specify one of android-arm, android-arm64, or android-x64…” |
| `flutter build appbundle --release --analyze-size --target-platform=android-arm64` | Success; measured AAB 94,292,448 B |
| `flutter build appbundle --release` | Success; restored normal Play AAB at `build/app/outputs/bundle/release/app-release.aab`, 131,612,296 B |

Analysis JSON files:

- APK: `C:\Users\user\.flutter-devtools\apk-code-size-analysis_01.json`
- AAB: `C:\Users\user\.flutter-devtools\aab-code-size-analysis_06.json`

Flutter's printed arm64 APK categories were 68 MB Flutter assets, 19 MB arm64 libraries, 1 MB DEX, plus small Android resources. The arm64 AAB printed 67 MB assets, 8 MB base libraries, 10 MB debug symbols, and 2 MB obfuscation metadata.

## Largest Project Asset Files

This is the required top 50 across `assets/` and the authoritative QPC pack, excluding generator cache/work output.

| # | Path | Bytes | MiB |
|---:|---|---:|---:|
| 1 | `assets/audio/adhkar/mishary_alafasy/morning.m4a` | 40,106,925 | 38.249 |
| 2 | `assets/audio/adhkar/mishary_alafasy/morning.mp3` | 16,338,740 | 15.582 |
| 3 | `assets/image/home/evening dark.png` | 1,851,379 | 1.766 |
| 4 | `assets/image/home/evening light.png` | 1,521,369 | 1.451 |
| 5 | `assets/image/home/Quran light.png` | 1,517,680 | 1.447 |
| 6 | `assets/image/zekr/rafiqi_zekr_light.png` | 1,514,306 | 1.444 |
| 7 | `assets/image/home/Quran dark.png` | 1,403,727 | 1.339 |
| 8 | `assets/image/home/morning dark.png` | 1,169,859 | 1.116 |
| 9 | `assets/image/home/Morning light.png` | 1,029,248 | 0.982 |
| 10 | `assets/image/home/Masged.png` | 604,991 | 0.577 |
| 11 | `assets/image/home/Masged dark.png` | 497,048 | 0.474 |
| 12 | `assets/fonts/Amiri/Amiri-Regular.ttf` | 421,196 | 0.402 |
| 13 | `assets/fonts/Amiri/Amiri-Italic.ttf` | 418,528 | 0.399 |
| 14 | `assets/fonts/Amiri/Amiri-Bold.ttf` | 403,996 | 0.385 |
| 15 | `assets/fonts/Amiri/Amiri-BoldItalic.ttf` | 400,176 | 0.382 |
| 16 | `assets/fonts/thmanyah/sans_ttf/thmanyahsans-Bold.ttf` | 347,340 | 0.331 |
| 17 | `quran_resources/qpc_v4_tajweed_pack/pages/602.png` | 324,736 | 0.310 |
| 18 | `quran_resources/qpc_v4_tajweed_pack/pages/601.png` | 322,684 | 0.308 |
| 19 | `quran_resources/qpc_v4_tajweed_pack/pages/604.png` | 318,452 | 0.304 |
| 20 | `quran_resources/qpc_v4_tajweed_pack/pages/603.png` | 305,488 | 0.291 |
| 21 | `quran_resources/qpc_v4_tajweed_pack/pages/595.png` | 274,658 | 0.262 |
| 22 | `quran_resources/qpc_v4_tajweed_pack/pages/598.png` | 268,781 | 0.256 |
| 23 | `quran_resources/qpc_v4_tajweed_pack/pages/596.png` | 268,706 | 0.256 |
| 24 | `quran_resources/qpc_v4_tajweed_pack/pages/587.png` | 263,588 | 0.251 |
| 25 | `quran_resources/qpc_v4_tajweed_pack/pages/597.png` | 261,876 | 0.250 |
| 26 | `quran_resources/qpc_v4_tajweed_pack/pages/591.png` | 261,550 | 0.249 |
| 27 | `quran_resources/qpc_v4_tajweed_pack/pages/599.png` | 260,995 | 0.249 |
| 28 | `quran_resources/qpc_v4_tajweed_pack/pages/600.png` | 259,197 | 0.247 |
| 29 | `assets/fonts/thmanyah/serif_display/thmanyahserifdisplay-Medium.otf` | 249,124 | 0.238 |
| 30 | `assets/fonts/thmanyah/serif_display/thmanyahserifdisplay-Black.otf` | 247,992 | 0.237 |
| 31 | `assets/fonts/thmanyah/serif_display/thmanyahserifdisplay-Bold.otf` | 247,296 | 0.236 |
| 32 | `assets/fonts/thmanyah/serif_text/thmanyahseriftext-Medium.otf` | 246,908 | 0.235 |
| 33 | `assets/fonts/thmanyah/serif_display/thmanyahserifdisplay-Regular.otf` | 246,668 | 0.235 |
| 34 | `assets/fonts/thmanyah/serif_text/thmanyahseriftext-Bold.otf` | 244,892 | 0.234 |
| 35 | `assets/fonts/thmanyah/serif_text/thmanyahseriftext-Black.otf` | 243,332 | 0.232 |
| 36 | `assets/fonts/thmanyah/serif_text/thmanyahseriftext-Regular.otf` | 242,952 | 0.232 |
| 37 | `assets/fonts/thmanyah/sans/thmanyahsans-Bold.otf` | 242,808 | 0.232 |
| 38 | `assets/fonts/thmanyah/sans/thmanyahsans-Black.otf` | 242,168 | 0.231 |
| 39 | `assets/fonts/thmanyah/sans/thmanyahsans-Medium.otf` | 242,116 | 0.231 |
| 40 | `assets/fonts/thmanyah/sans/thmanyahsans-Regular.otf` | 241,292 | 0.230 |
| 41 | `assets/fonts/thmanyah/serif_text/thmanyahseriftext-Light.otf` | 240,480 | 0.229 |
| 42 | `assets/fonts/thmanyah/serif_display/thmanyahserifdisplay-Light.otf` | 240,436 | 0.229 |
| 43 | `assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Bold.ttf` | 236,256 | 0.225 |
| 44 | `assets/fonts/thmanyah/sans/thmanyahsans-Light.otf` | 234,588 | 0.224 |
| 45 | `assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-SemiBold.ttf` | 234,232 | 0.223 |
| 46 | `assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Thin.ttf` | 232,408 | 0.222 |
| 47 | `assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-ExtraLight.ttf` | 232,212 | 0.221 |
| 48 | `assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Medium.ttf` | 231,796 | 0.221 |
| 49 | `quran_resources/qpc_v4_tajweed_pack/pages/578.png` | 230,467 | 0.220 |
| 50 | `quran_resources/qpc_v4_tajweed_pack/pages/577.png` | 230,339 | 0.220 |

## Largest Packaged Files

The following tables give the top 50 entries by compressed size. Each table also supplies exact uncompressed bytes; the subsequent raw-order table records the top ordering by uncompressed size. URL-escaped `%20` is the ZIP entry spelling of spaces.

### APK: top 50 by compressed bytes

| # | Entry | Compressed B | Raw B |
|---:|---|---:|---:|
| 1 | `assets/flutter_assets/assets/audio/adhkar/mishary_alafasy/morning.m4a` | 40,106,925 | 40,106,925 |
| 2 | `assets/flutter_assets/assets/audio/adhkar/mishary_alafasy/morning.mp3` | 16,338,740 | 16,338,740 |
| 3 | `lib/arm64-v8a/libflutter.so` | 11,747,864 | 11,747,864 |
| 4 | `lib/arm64-v8a/libapp.so` | 8,127,368 | 8,127,368 |
| 5 | `assets/flutter_assets/assets/image/home/evening%20dark.png` | 1,851,379 | 1,851,379 |
| 6 | `assets/flutter_assets/assets/image/home/evening%20light.png` | 1,521,369 | 1,521,369 |
| 7 | `assets/flutter_assets/assets/image/home/Quran%20light.png` | 1,517,680 | 1,517,680 |
| 8 | `assets/flutter_assets/assets/image/zekr/rafiqi_zekr_light.png` | 1,514,306 | 1,514,306 |
| 9 | `assets/flutter_assets/assets/image/home/Quran%20dark.png` | 1,403,727 | 1,403,727 |
| 10 | `classes.dex` | 1,366,937 | 2,808,764 |
| 11 | `assets/flutter_assets/assets/image/home/morning%20dark.png` | 1,169,859 | 1,169,859 |
| 12 | `assets/flutter_assets/assets/image/home/Morning%20light.png` | 1,029,248 | 1,029,248 |
| 13 | `assets/flutter_assets/assets/image/home/Masged.png` | 604,991 | 604,991 |
| 14 | `assets/flutter_assets/assets/image/home/Masged%20dark.png` | 497,048 | 497,048 |
| 15 | `resources.arsc` | 208,504 | 208,504 |
| 16 | `assets/flutter_assets/assets/fonts/Amiri/Amiri-Regular.ttf` | 203,040 | 421,196 |
| 17 | `assets/flutter_assets/assets/fonts/Amiri/Amiri-Bold.ttf` | 190,924 | 403,996 |
| 18 | `assets/flutter_assets/assets/branding/splash_light.png` | 146,810 | 146,810 |
| 19 | `assets/flutter_assets/assets/branding/splash_dark.png` | 146,810 | 146,810 |
| 20 | `assets/flutter_assets/assets/branding/logo_symbol.png` | 140,057 | 140,057 |
| 21 | `assets/flutter_assets/assets/branding/logo_light.png` | 140,057 | 140,057 |
| 22 | `assets/flutter_assets/assets/branding/launcher_legacy.png` | 140,057 | 140,057 |
| 23 | `assets/flutter_assets/assets/branding/app_icon.png` | 140,057 | 140,057 |
| 24 | `res/4k.png` | 132,070 | 132,070 |
| 25 | `res/Yh.png` | 132,070 | 132,070 |
| 26 | `lib/arm64-v8a/libdartjni.so` | 131,400 | 131,400 |
| 27 | `lib/x86_64/libdartjni.so` | 116,792 | 116,792 |
| 28 | `…/thmanyahserifdisplay-Medium.otf` | 106,437 | 249,124 |
| 29 | `…/thmanyahserifdisplay-Bold.otf` | 105,637 | 247,296 |
| 30 | `…/thmanyahserifdisplay-Regular.otf` | 105,220 | 246,668 |
| 31 | `…/thmanyahseriftext-Medium.otf` | 104,444 | 246,908 |
| 32 | `…/thmanyahseriftext-Regular.otf` | 103,658 | 242,952 |
| 33 | `…/thmanyahseriftext-Bold.otf` | 103,592 | 244,892 |
| 34 | `assets/flutter_assets/NOTICES.Z` | 103,064 | 104,813 |
| 35 | `…/thmanyahsans-Bold.otf` | 103,023 | 242,808 |
| 36 | `…/IBMPlexSansArabic-SemiBold.ttf` | 102,969 | 234,232 |
| 37 | `…/thmanyahserifdisplay-Black.otf` | 102,887 | 247,992 |
| 38 | `…/thmanyahsans-Medium.otf` | 102,817 | 242,116 |
| 39 | `…/IBMPlexSansArabic-Medium.ttf` | 102,449 | 231,796 |
| 40 | `…/thmanyahsans-Regular.otf` | 101,062 | 241,292 |
| 41 | `…/thmanyahseriftext-Black.otf` | 100,321 | 243,332 |
| 42 | `…/thmanyahsans-Black.otf` | 100,140 | 242,168 |
| 43 | `…/IBMPlexSansArabic-Bold.ttf` | 99,928 | 236,256 |
| 44 | `…/thmanyahserifdisplay-Light.otf` | 98,911 | 240,436 |
| 45 | `…/IBMPlexSansArabic-Regular.ttf` | 97,954 | 226,560 |
| 46 | `…/thmanyahseriftext-Light.otf` | 97,845 | 240,480 |
| 47 | `…/thmanyahsans-Light.otf` | 94,524 | 234,588 |
| 48 | `lib/armeabi-v7a/libdartjni.so` | 81,600 | 81,600 |
| 49 | `…/ArefRuqaa-Bold.ttf` | 75,727 | 123,852 |
| 50 | `…/ArefRuqaa-Regular.ttf` | 67,013 | 110,696 |

### APK: top 50 by uncompressed bytes

The membership is identical to the compressed top 50; only order changes. Raw order is: audio M4A, audio MP3, `libflutter.so`, `libapp.so`, `classes.dex`, the eight large home/zekr images, Amiri Regular/Bold, the 15 Thmanyah faces, the four IBM Plex faces, `resources.arsc`, two splash images, four 140,057-byte branding aliases, two 132,070-byte splash resources, `libdartjni.so` arm64, Aref Bold, `libdartjni.so` x86_64, Aref Regular, `NOTICES.Z`, and `libdartjni.so` armeabi-v7a. Exact compressed/raw values for every member are in the preceding table.

### AAB: top 50 by compressed bytes

| # | Entry | Compressed B | Raw B |
|---:|---|---:|---:|
| 1 | `base/assets/…/morning.m4a` | 39,324,280 | 40,106,925 |
| 2 | `base/assets/…/morning.mp3` | 16,195,204 | 16,338,740 |
| 3 | `BUNDLE-METADATA/…/arm64-v8a/libflutter.so.sym` | 6,804,032 | 18,776,976 |
| 4 | `BUNDLE-METADATA/…/x86_64/libflutter.so.sym` | 6,618,440 | 17,853,568 |
| 5 | `BUNDLE-METADATA/…/armeabi-v7a/libflutter.so.sym` | 5,866,036 | 13,859,184 |
| 6 | `base/lib/x86_64/libflutter.so` | 5,628,535 | 13,051,424 |
| 7 | `base/lib/arm64-v8a/libflutter.so` | 5,478,894 | 11,747,864 |
| 8 | `base/lib/armeabi-v7a/libflutter.so` | 4,741,219 | 8,615,900 |
| 9 | `BUNDLE-METADATA/…/armeabi-v7a/libapp.so.sym` | 3,882,018 | 9,821,980 |
| 10 | `BUNDLE-METADATA/…/x86_64/libapp.so.sym` | 3,629,154 | 9,448,776 |
| 11 | `base/lib/armeabi-v7a/libapp.so` | 3,605,615 | 8,929,864 |
| 12 | `BUNDLE-METADATA/…/arm64-v8a/libapp.so.sym` | 3,571,241 | 9,186,792 |
| 13 | `base/lib/x86_64/libapp.so` | 3,346,567 | 8,389,512 |
| 14 | `base/lib/arm64-v8a/libapp.so` | 3,291,540 | 8,127,368 |
| 15 | `BUNDLE-METADATA/…/proguard.map` | 2,107,456 | 25,070,780 |
| 16 | `base/assets/…/evening%20dark.png` | 1,838,367 | 1,851,379 |
| 17 | `base/assets/…/evening%20light.png` | 1,508,268 | 1,521,369 |
| 18 | `base/assets/…/rafiqi_zekr_light.png` | 1,502,043 | 1,514,306 |
| 19 | `base/assets/…/Quran%20dark.png` | 1,391,457 | 1,403,727 |
| 20 | `base/dex/classes.dex` | 1,366,937 | 2,808,764 |
| 21 | `base/assets/…/Quran%20light.png` | 1,263,265 | 1,517,680 |
| 22 | `base/assets/…/morning%20dark.png` | 1,156,644 | 1,169,859 |
| 23 | `base/assets/…/Morning%20light.png` | 1,016,001 | 1,029,248 |
| 24 | `base/assets/…/Masged.png` | 604,425 | 604,991 |
| 25 | `base/assets/…/Masged%20dark.png` | 492,869 | 497,048 |
| 26 | `base/assets/…/Amiri-Regular.ttf` | 203,040 | 421,196 |
| 27 | `base/assets/…/Amiri-Bold.ttf` | 190,924 | 403,996 |
| 28 | `base/assets/…/splash_dark.png` | 145,341 | 146,810 |
| 29 | `base/assets/…/splash_light.png` | 145,341 | 146,810 |
| 30 | `base/assets/…/app_icon.png` | 138,687 | 140,057 |
| 31 | `base/assets/…/launcher_legacy.png` | 138,687 | 140,057 |
| 32 | `base/assets/…/logo_light.png` | 138,687 | 140,057 |
| 33 | `base/assets/…/logo_symbol.png` | 138,687 | 140,057 |
| 34 | `base/res/drawable-night-nodpi-v8/splash_screen.png` | 131,815 | 132,070 |
| 35 | `base/res/drawable-nodpi-v4/splash_screen.png` | 131,815 | 132,070 |
| 36 | `…/thmanyahserifdisplay-Medium.otf` | 106,437 | 249,124 |
| 37 | `…/thmanyahserifdisplay-Bold.otf` | 105,637 | 247,296 |
| 38 | `…/thmanyahserifdisplay-Regular.otf` | 105,220 | 246,668 |
| 39 | `…/thmanyahseriftext-Medium.otf` | 104,444 | 246,908 |
| 40 | `…/thmanyahseriftext-Regular.otf` | 103,658 | 242,952 |
| 41 | `…/thmanyahseriftext-Bold.otf` | 103,592 | 244,892 |
| 42 | `base/assets/flutter_assets/NOTICES.Z` | 103,064 | 104,813 |
| 43 | `…/thmanyahsans-Bold.otf` | 103,023 | 242,808 |
| 44 | `…/IBMPlexSansArabic-SemiBold.ttf` | 102,969 | 234,232 |
| 45 | `…/thmanyahserifdisplay-Black.otf` | 102,887 | 247,992 |
| 46 | `…/thmanyahsans-Medium.otf` | 102,817 | 242,116 |
| 47 | `…/IBMPlexSansArabic-Medium.ttf` | 102,449 | 231,796 |
| 48 | `…/thmanyahsans-Regular.otf` | 101,062 | 241,292 |
| 49 | `…/thmanyahseriftext-Black.otf` | 100,321 | 243,332 |
| 50 | `…/thmanyahsans-Black.otf` | 100,140 | 242,168 |

### AAB: top 50 by uncompressed bytes

The top raw entries, in exact order, are: M4A 40,106,925; ProGuard map 25,070,780; arm64 Flutter symbols 18,776,976; x86_64 Flutter symbols 17,853,568; MP3 16,338,740; armeabi Flutter symbols 13,859,184; x86_64 Flutter engine 13,051,424; arm64 Flutter engine 11,747,864; armeabi app symbols 9,821,980; x86_64 app symbols 9,448,776; arm64 app symbols 9,186,792; armeabi `libapp.so` 8,929,864; armeabi Flutter engine 8,615,900; x86_64 `libapp.so` 8,389,512; arm64 `libapp.so` 8,127,368; DEX 2,808,764; then the eight large UI images, two Amiri fonts, `base/resources.pb` (349,184 raw / 89,654 compressed), the 15 Thmanyah faces, four IBM faces, the arm64 `libdartjni.so.sym` (159,176 raw / 33,358 compressed), and the two 146,810-byte splash assets. This is 50 entries; exact image/font values are in the compressed table above.

## Suspicious / Potentially Unnecessary Assets

1. The 16,338,740-byte MP3 is accidentally pulled in by a directory declaration while all evidence selects the M4A.
2. `assets/branding/` packages 720,762 bytes of non-splash generator inputs/aliases as Flutter runtime assets; only the splash pair has runtime references.
3. Two declared Thmanyah serif families cost 1,028,952 compressed bytes and have no current call sites; dynamic use remains possible, so review is required.
4. The same launcher artwork exists both as packaged Flutter assets and generated Android resources. Build inputs can remain in the repository without necessarily being runtime Flutter assets.
5. The research QPC pack is explicitly excluded from release. That is not an app-size problem, but it is a product/release-state discrepancy if a production Mushaf was expected.

## Size Reduction Opportunities

No opportunity was implemented.

| Priority | Opportunity | Current cost | Estimated recovery | Evidence | Risk |
|---|---|---:|---:|---|---|
| P0 | Stop packaging unused `morning.mp3` | 16,338,740 B | 16,338,740 B / 15.582 MiB APK | Manifest/runtime/tests select M4A; directory declaration sweeps MP3 in | Low; verify no external/dynamic consumer |
| P0 | Decide production policy for development M4A | 40,106,925 B | Up to 40,106,925 B / 38.249 MiB | Manifest says `localAssetForDevelopment`; pubspec calls it temporary | Product/architecture decision; removing it changes offline Adhkar audio unless replaced by download/stream |
| P1 | Narrow `assets/branding/` declaration | 720,762 B | 720,762 B / 0.687 MiB | Only splash images are runtime-referenced; other files are launcher inputs/aliases | Low if launcher generation still has source files and runtime paths are verified |
| P1 | Evaluate large PNG delivery format/density | 12,394,496 B | Likely 2–6 MiB, not measured | Seven 1.0–1.85 MB PNGs at ~1.57 MP | Visual quality, alpha, decode-memory and design review |
| P2 | Review Thmanyah Serif Display/Text declarations | 1,028,952 compressed B | Up to 1,028,952 B / 0.981 MiB | No current call sites; fonts explicitly bundled | Typography/regression risk; dynamic family selection must be checked |
| P2 | Decide whether release should ship/download Mushaf pack | 0 B now; local pack 101.441 MiB | Architecture-dependent | Current release has no pack, despite local renderer work | Major Quran availability, offline, licensing and product decision |
| P3 | Consolidate exact duplicate branding content | 680,417 B theoretical | Included in the narrower-branding estimate | SHA-256 exact matches | Alias/reference and launcher-generation risk |
| P3 | Investigate cross-ABI plugin `.so` entries in arm64 APK | 209,008 B for non-arm64 plugin libs | At most ~0.199 MiB | x86_64/armeabi `libdartjni` and DataStore libs remain | Build/plugin compatibility; low impact |

The evidence-backed safe recovery preserving current Quran functionality is **17,059,502 bytes (16.269 MiB)**: unused MP3 plus non-runtime branding packaging. This would reduce the arm64 APK from 90.119 MiB to approximately **73.850 MiB**, before ZIP-alignment/metadata variation. If product approves replacing the bundled development M4A with remote/downloaded audio, total recovery rises to **57,166,427 bytes (54.518 MiB)** and the APK could approach **35.6 MiB**, again before packaging variance.

## Final Diagnosis

1. **What is making Maab large right now?** Two development Adhkar audio files (53.830 MiB), followed by 11.820 MiB of PNGs, 11.204 MiB Flutter engine, 7.751 MiB Dart AOT, and 2.501 MiB compressed fonts.
2. **Is the Quran Mushaf pack the main cause?** No. It contributes zero bytes to release.
3. **How much does the Mushaf add?** The local research pack is 101.441 MiB raw (99.524 MiB pages + 1.872 MiB geometry + 0.045 MiB metadata/license), but current release adds 0 bytes. If later bundled as stored assets, its archive cost would be close to its already-compressed 101.44 MiB.
4. **Are there accidental duplicate/legacy assets?** Yes: 0.649 MiB exact packaged duplicates in branding, an unused 15.582 MiB MP3 swept in by the audio directory declaration, and unbundled old data/font trees. No duplicate Mushaf pack enters release.
5. **Is audio currently contributing materially?** Yes; 53.830 MiB and 59.73% of the APK.
6. **Are fonts materially contributing?** Moderately: 5.654 MiB raw, 2.501 MiB compressed. They are not the primary problem.
7. **Are native libraries materially contributing?** Normal Flutter engine+AOT cost is material at 18.955 MiB; plugin native libraries are only 0.331 MiB. Native libraries are not the abnormal growth source.
8. **What is the single largest optimization opportunity?** Product-approved removal/replacement of the 40.107 MB development M4A. The largest immediately evidence-backed accidental packaging fix is the 16.339 MB unused MP3.
9. **What size could realistically be recovered without reducing Quran functionality?** 16.269 MiB safely from unused MP3 and branding scope; up to 54.518 MiB if development audio is migrated without losing the feature.
10. **Which optimizations require architecture/product decisions?** Adhkar audio delivery, whether/how a production Mushaf should ship or download, image quality/format strategy, and removal of typography families after design review.


# Mushaf Benchmark Contract — Phase 0

Status: **Accepted Phase 0 product and architecture contract**  
Project: **Maab / مَآب** (`tasbeh` repository)  
Date: **2026-10-06**

## 1. Executive summary

Maab will treat a printed Mushaf as the primary Quran reading surface: it should feel like opening a real Mushaf, with tools available without dominating the page. Semantic text mode is secondary in presentation but mandatory for accessibility, search, copying, sharing, and study.

Canonical Quran content is immutable structured data, not a page image. A selected Mushaf edition projects stable semantic identities onto edition-specific pages and normalized geometry. Reading, search, audio, Tafsir, and user state meet through keys such as Ayah `2:255` and Word `2:255:3`; displayed text and bare page numbers are never identity. Core reading is local-first. Content packs may be independently installed only after authenticity, licensing, integrity, compatibility, and safe-install checks. Mutable user state is kept apart from canonical content.

This contract authorizes no Quran implementation, content ingestion, or Phase 1 work.

## 2. Current Quran implementation discovered

Repository status/diff, Quran terms/files/assets/routes/tests, startup, navigation, Home, persistence, themes, and Adhkar audio/download infrastructure were inspected.

- `lib/app/navigation/main_shell_screen.dart` owns five destinations in a state-retaining `IndexedStack`. Tab 3 (index 2) is a Quran `AppPlaceholderScreen`, not a reader. Other feature routes use `Navigator.push`; the Adhkar reader uses a calm 180/160 ms fade. No Quran route exists.
- `lib/features/home/domain/quran_reading.dart` defines a Home-facing `QuranReadingPosition` with `surahName` and optional bare `page`, `ayah`, and `progress`. Its placeholder source always returns `null`; there is no Quran persistence.
- `lib/features/home/presentation/widgets/home_quran_section.dart` contains an image-led Continue Quran card. Both its continuation and start paths currently show “coming soon.” Assets exist at `assets/image/home/Quran light.png`, `Quran dark.png`, and `assets/icons/svg/quran.svg`.
- There is no Quran feature directory, Quran dataset, edition/page pack, semantic overlay, repository, database, search, bookmarks/Khatma, Quran audio, or reader screen.
- Arabic fonts are present, including Amiri, but file presence is not Quran suitability, authenticity, or licensing approval.
- Small settings use a singleton `AppPreferencesRepository` plus `SharedPreferences`; other features own repositories. This is precedent, not a decision to store Quran content or structured user state there.
- Theme architecture provides Light/Dark, selectable palettes, and semantic `AppColors`. Future reader chrome should use it; approved printed pages remain edition-faithful.
- Adhkar audio already uses `just_audio`, `audio_service`, `background_downloader`, manifests, support-directory files, per-item audio, continuous recordings, and timed clips. Its downloader mainly verifies presence/size, not the full Quran pack lifecycle.

### Current implementation gaps / migration considerations

1. Although the source returns no position, `_MockQuranReadingProgress` always paints “Continue reading — Al-Baqarah · Ayah 157.” This fabricates state and conflicts with D0-15. Phase 1 must show a true start/empty state until real state exists.
2. The Home model lacks `surahNumber:ayahNumber` and `mushafId + pageNumber`. It is a replaceable presentation seam, not the Quran domain model.
3. The Quran tab and Home callbacks are placeholders. Future routing must preserve the shell and calm navigation behavior.
4. A second `AudioService`/player could compete for media session, notification, focus, and lifecycle ownership. Phase 1 must audit and coordinate with Adhkar audio first.
5. The Adhkar downloader lacks checksum, compatibility validation, staged atomic activation, rollback, and corrupted-pack recovery; it must not be promoted unchanged.
6. `SharedPreferences` may suit settings/pointers, but history, bookmarks, notes, and Khatma require a deliberate transactional persistence decision.

No existing implementation is rewritten in Phase 0.

## 3. Product benchmark philosophy

The product-experience benchmark is Android **Mushaf by A.Abdo** (`com.abdo.quran`). Maab may learn from its experience but will not copy source, proprietary assets, branding, datasets, or implementation.

> I am opening a real printed Mushaf on my phone, with powerful tools available when I need them.

This is not a generic dynamically laid-out text reader. Printed, edition-faithful pages are primary; semantic text is secondary but complete; chrome recedes; actions are contextual; and both modes use the same semantic core. Benchmark parity means product jobs, not copied visuals.

## 4. Scope, MVP, and non-goals

This phase freezes terminology, identity, ownership, offline behavior, page semantics, audio, resources, integrity, licensing, integrations, tiers, risks, and Phase 1 prerequisites.

Recommended MVP: one verified Hafs riwayah and trusted edition; printed pages; semantic Ayah core; edition-aware navigation; last position, ribbon, bookmarks; offline search; accessible text mode; one initial Tafsir architecture/resource; expandable Quran audio; local-first operation; and safe pack/update boundaries. Image crops, notes, and Khatma are Post-MVP because they add licensing, geometry, privacy, and progress complexity, while their architectural identities are frozen now.

Phase 0 explicitly excludes production Dart, refactors, engines, screens, routes, models, repositories, databases, dependencies, assets, content downloads, pack installers, search indexes, audio changes, sync, and integrations. It does not select or approve a provider, font, dataset, or edition and does not begin Phase 1.

## 5. Core architectural invariants

1. Installed core reading works without a live network/API.
2. Quran Core is structured semantic data, not bitmap/PDF/font output.
3. Ayah identity is `surahNumber:ayahNumber`; Word identity is `surahNumber:ayahNumber:wordNumber`. Text is never identity.
4. Page identity is `(mushafId, pageNumber)`; page count and mapping are edition data, not universal facts.
5. Architecture is Mushaf-aware from day one.
6. `Riwayah` (transmission/reading context) and `MushafEdition` (publisher/layout/rendering) are distinct and explicitly compatible.
7. Quran Core is immutable at runtime. Corrections arrive as new verified versions.
8. User state never lives inside canonical content/packs.
9. Printed pages, text, search, resources, audio, and future memorization converge on stable semantic keys.
10. Editions, assets, layouts, Tafsir, translations, meanings, grammar, audio, and timings are modular/versioned resources.
11. Optional-resource failure cannot make the last working core reader unavailable.
12. UI never guesses reading state.
13. User and resource schemas are versioned and migratable.
14. References, bounds, compatibility, and integrity fail closed.

## 6. Terminology glossary

| Term | Definition |
|---|---|
| Quran Core | Immutable authenticated semantic Quran data/metadata for a declared riwayah/version, independent of pages. |
| Riwayah | Transmission/reading context such as Hafs, Warsh, or Qalun; not a page design. |
| MushafEdition | Versioned printed publication/layout compatible with a riwayah and defining pages, mapping, and visuals. |
| Page | Edition-scoped `(mushafId, pageNumber)`; 604 is not universal. |
| Ayah | Semantic unit keyed `surahNumber:ayahNumber`. |
| Word | Semantic token keyed `surahNumber:ayahNumber:wordNumber` under an explicit tokenization/version. |
| Layout | Edition data projecting semantic content to pages, lines, and regions. |
| PageAssetPack | Versioned visual pages for one edition; not canonical Quran data. |
| Semantic Overlay | Versioned normalized geometry mapping Ayah/Word keys to one or more page regions. |
| Content Resource | Manifest-governed Core, edition, assets, layout, Tafsir, translation, meanings, grammar, audio, or timings. |
| Reading Position | Latest genuine semantic reading anchor, optionally with cached edition projection. |
| Reading Ribbon | Single explicitly moved traditional marker, independent of recent reading. |
| Bookmark | One of many explicitly saved Ayah/range anchors, optionally later with a note. |
| Khatma | A plan and progress ledger for a completion cycle; not inferred from last page. |

## 7. Benchmark capability matrix

| # | Capability | Tier | Architecture impact | Dependency |
|---:|---|---|---|---|
| 1 | Printed Mushaf reading | MVP | Edition-aware primary reader | Verified edition/assets/layout |
| 2 | 604-page style where appropriate | MVP | Edition-scoped page count | Edition manifest |
| 3 | Swipe/page navigation | MVP | RTL bounded controller | Settled-position policy |
| 4 | Surah/Juz/Hizb/Rub'/page/Ayah navigation | MVP | Semantic lookup and projection | Core indexes + edition map |
| 5 | Current page awareness | MVP | Edition page plus visible anchor | Reader viewport + overlay |
| 6 | Last reading position | MVP | Separate durable record | User-state repository |
| 7 | Reading ribbon | MVP | Explicit distinct marker | User-state repository |
| 8 | Multiple bookmarks | MVP | Many semantic anchors/ranges | Bookmark repository |
| 9 | Bookmark notes | Post-MVP | Private mutable data | Bookmark model + user store |
| 10 | Reading history | Post-MVP | Session ledger/retention | Session definition + user store |
| 11 | Khatma tracking | Post-MVP | Independent plan/coverage | Coverage rules + user store |
| 12 | Ayah selection | MVP | Hit test to stable key | Semantic Overlay |
| 13 | Multi-Ayah range | MVP | Ordered cross-page range | Canonical order + overlay |
| 14 | Tap Ayah/actions | MVP | Semantic action layer | Selection + action registry |
| 15 | Tafsir | MVP | Extensible Ayah resource API | Licensed mapped Tafsir pack |
| 16 | Word meanings | Post-MVP | Word resource API | Compatible tokenization/resource |
| 17 | Translation | Post-MVP | Locale/version Ayah resource | Licensed translation pack |
| 18 | I'rab/grammar | Future | Word/Ayah resource type | Scholarly source + mapping |
| 19 | Other study resources | Future | Typed extensible registry | Resource extension contract |
| 20 | Copy Ayah text | MVP | Trusted semantic copy | Core + attribution policy |
| 21 | Share Ayah text | MVP | Deterministic composition | Core + platform share boundary |
| 22 | Share page image/crop | Post-MVP | Multi-region crop composition | Overlay + assets + rights |
| 23 | Text mode | MVP | Secondary renderer, same keys | Quran Core |
| 24 | Adjustable text size | MVP | Presentation preference | Text renderer |
| 25 | Accessibility/screen reader | MVP | Semantic order/actions | Core + accessible text mode |
| 26 | Quran search | MVP | Offline normalized index | Verified Core + search policy |
| 27 | Search result → Ayah/page | MVP | Key-to-visible-region resolution | Search + edition map + overlay |
| 28 | Reciters | MVP | Versioned recitation catalog | Audio source governance |
| 29 | Individual Ayah playback | MVP | Segmented Ayah-keyed source | Recitation manifest/files |
| 30 | Continuous/gapless Surah | MVP | Continuous track model | Player + verified timing map |
| 31 | Repeat Ayah/range | MVP | Semantic playback queue | Controller + Ayah order |
| 32 | Playback speed | Post-MVP | User playback preference | Shared audio-session support |
| 33 | Configurable Ayah pause | Post-MVP | Queue timing policy | Segmentation/timing + controller |
| 34 | Background playback | MVP | Coordinated media session | App-level audio audit |
| 35 | Offline audio downloads | MVP | Optional verified packs | Safe installer + storage policy |
| 36 | Synchronized highlight | MVP | Time-to-key-to-geometry path | Timing map + overlay |
| 37 | Selectable editions | Post-MVP | Semantic reprojection | Multiple licensed edition packs |
| 38 | Selectable Riwayat | Future | Riwayah-aware compatibility | Scholarly model + verified cores |
| 39 | Downloadable resource packs | MVP-ready | Manifest/install abstraction | Resource and installer contracts |
| 40 | Pack update/version management | MVP-ready | Compatibility/rollback policy | Catalog + manifest semantics |
| 41 | Integrity/checksums | MVP | Verify before activation | Trusted manifest + cryptographic hashes |
| 42 | Corrupt download recovery | MVP | Quarantine and last-known-good | Atomic installer + health checks |
| 43 | User-state backup/sync | Future | User data only/conflict rules | Stable schema + account/privacy policy |
| 44 | Home Continue Quran | MVP | Real state projection only | LastReadingPosition + route contract |
| 45 | Daily Wird/Journey integration | Future | Stable-key targets/events | Product rules + boundary API |
| 46 | Memorization/review/Tasmee | Future | Reuse semantic IDs; separate state | Core IDs + evaluation design |

`MVP-ready` requires the boundary and lifecycle in MVP, not a broad public catalog. Tier changes require an explicit decision-log amendment with rationale.

## 8. Reading-state contract

| Concept | Trigger | Cardinality | Identity |
|---|---|---:|---|
| LastReadingPosition | Confirmed genuine reading movement | One current record | Ayah key; optional word/offset; cached edition/page |
| ReadingRibbon | Explicit place/move action | Zero/one active | Ayah key; optional projection |
| Bookmark | Explicit add/remove/edit | Many | Start Ayah; optional end Ayah/note later |
| ReadingHistory | Defined reading-session event | Many ordered | Start/end keys + timestamps |
| KhatmaProgress | Explicit/policy-governed coverage | Many plans/cycles | Semantic ranges/coverage |

These must never collapse into `lastPage`. A semantic anchor such as `2:157` survives edition changes; `mushafId + pageNumber` is a re-derivable projection. Surah name/page are display data. Missing projection falls back safely to semantic text or an explained location, never reinterpretation of a bare page. Position writes occur only after a Phase 1-defined genuine-reading event, not transient animation. User records carry schema/timestamps and survive pack removal/update.

## 9. Mushaf/page semantic contract

A page binds: (1) edition-faithful visual rendering, (2) Quran Core identities/order, and (3) an edition/version-specific Semantic Overlay.

```text
MushafPage(mushafId, pageNumber)
  visual: approved page rendering
  mapping: 2:253 → [region...], 2:254 → [region...], 2:255 → [region...]
```

- Geometry is resolution-independent with explicit origin, axes, transforms, and schema version.
- One Ayah may occupy multiple disjoint line/regions; ordering, overlap, ornaments, verse markers, margins, and ambiguous taps have deterministic policies.
- Scaling, fit, crop, zoom, and device pixels are view transforms, never stored geometry.
- Overlay, layout, and assets declare the exact compatible edition/version/checksums; mixing fails closed.
- Keys/pages/regions are bounds-validated against Core and edition.
- Mapping supports tap/highlight, range selection, bookmark, Tafsir, search reveal, audio highlight, and licensed crop sharing.
- Search/audio resolve Ayah first, then edition page/geometry.
- Missing/corrupt geometry preserves text reading and semantic actions while clearly disabling geometry-dependent actions.

Risks: mapping accuracy, multi-line Ayat, version drift, zoom performance, hit ambiguity, and crop/share rights. Phase 1 needs automated fixtures plus human visual QA.

## 10. Audio capability contract

Both segmented Ayah files and continuous/gapless Surah tracks plus timing maps are required.

```text
Reciter → Recitation → Track → TimingMap → AyahKey
time → AyahKey → selected edition projection → geometry → highlight
```

Reciter, recitation (riwayah/style/source/version), and track are distinct. Audio/timings declare Core/riwayah compatibility and never depend directly on one page layout. Queue, repeat, seek, speed, delays, and recovery sit above files. Missing audio never blocks reading; invalid/out-of-order/out-of-duration timings fail validation.

Before implementation, Phase 1 must inspect Maab's existing Adhkar `audio_service` handler, `just_audio` adapter, notification, focus, background downloader, continuous clips, lifecycle, and restoration. It must define one coordinated session/ownership strategy; no competing playback system may be introduced accidentally.

## 11. Resource/download contract

Every manifest records stable resource ID, type/name/version/schema, source/provider, publisher/author, Core/riwayah compatibility, dependencies, file list/sizes/checksums, license/attribution, acquisition/update dates; edition resources also record `mushafId`, page count, and layout/overlay/asset compatibility.

```text
download to versioned staging
→ verify size and cryptographic checksum
→ validate manifest/schema/references/dependencies/resource invariants
→ atomically install immutable version
→ atomically switch active pointer
→ health check; retain/clean prior version by rollback policy
```

The working pack remains active throughout. Partial, corrupt, incompatible, or unlicensed candidates never replace it. Required states: `notInstalled`, `downloading`, `paused`, `verifying`, `installed`, `updateAvailable`, `failed`, `corrupted` (implementations may add queued/staged/activating/removing). Startup reconciles abandoned staging and interrupted activation. Removal respects dependencies and never deletes user state. Storage estimation, low-disk, network policy, resume, concurrency, and rollback precede implementation. Checksums prove integrity, not provenance; trusted distribution/signing remains to be selected.

## 12. Source/licensing governance

Possible candidates for later evaluation include King Fahd Glorious Quran Printing Complex, QUL/Tarteel, and Quran Foundation/Quran.com. None is approved by this document.

Technical downloadability is never approval. Each text, edition/layout/image, Tafsir, translation, font, audio, timing, and derived resource is individually verified for authenticity/correctness/version; provenance; redistribution, bundling, caching, transformation/cropping/derivative, and offline-storage rights; attribution; update/withdrawal obligations; checksum; and review/acquisition dates. The registry records resource ID, name/type, provider, publisher/author, version, terms, attribution, checksum, acquisition/update dates, approval status, and evidence. Ambiguous rights mean **not approved**. Derived overlays/indexes/crops retain upstream provenance and restrictions.

## 13. Offline-first contract

Once MVP is ready, Core, initial edition, projection, navigation indexes, and MVP search needed for reading work offline. Reader opening, page turns, navigation, state, text mode, and installed Tafsir never require an API. Bundled versus verified first-run install must guarantee a clearly offline-ready baseline. Network is only for optional resources, updates, sync, or labeled enhancements. Local user writes are authoritative and durable; future sync cannot be required to read. Connectivity loss never affects the active pack.

## 14. Integrity and safety rules

- Reject unknown schemas, incompatibilities, invalid keys/bounds/timings, missing files, and size/checksum mismatch.
- Validate semantic counts/references; never runtime-repair Quran text.
- Activated packs are read-only; corrections are new reviewed versions.
- Separate canonical resources, pack metadata, and mutable user storage.
- Atomic activation retains last known-good recovery.
- Sanitize pack paths/IDs; manifests cannot escape staging or overwrite unrelated files.
- Migrations are forward-tested/rollback-aware and never silently discard user state.
- Minimize logs of Quran user state/notes; define privacy, retention, export, deletion, and sync first.
- Backup/sync user state only unless resource transfer is separately licensed.
- Validate semantic correctness with automated cases and human review, not file validity alone.

## 15. Integration boundaries

- **Home:** consumes a read-only projection of real persisted `LastReadingPosition`. No record means a real start/empty state. Tap passes the semantic anchor to Quran, which resolves its edition. Home never owns or fabricates state.
- **Daily Wird/Journey:** no integration now. Future boundaries exchange stable-key targets/events plus task/plan IDs, never shared tables, Core mutation, or page-only progress.
- **Themes:** chrome, dialogs, text mode, and accessibility use `ThemeMode`, palette, and `AppColors`. Printed art is not recolored without authenticity/design/license approval.
- **Navigation:** Quran remains the third top-level destination; pushed routes preserve calm transitions, back stack, and shell behavior. No redesign now.
- **Adhkar audio:** coordinate at app media-session/focus level after audit; do not force Quran into Dhikr models or regress Adhkar.
- **Tasbeeh/overlay/Adhkar:** untouched; future coordination uses explicit interfaces/events.

## 16. Explicit Phase 0 non-goals

This contract does not mean providers are approved, an edition/storage technology is selected, geometry exists, audio is unified, or a capability is implemented. Production and migration work require an approved Phase 1 plan.

## 17. Open questions and risks

Open inputs:

1. Exact approved Hafs Core/version and redistribution rights.
2. Exact initial edition/`mushafId`; rights to bundle, cache, highlight, crop, and share.
3. Source versus Maab-derived overlay and its scholarly/visual validation.
4. Tokenization/orthography/search/copy/accessibility rules.
5. Definition of a genuine last-reading write.
6. Transactional user-state store and migrations.
7. Cross-feature audio focus/session/notification/restoration strategy.
8. Licensed recitation sources and verified timings.
9. Bundled versus first-run baseline and storage budgets.
10. Device, performance, accessibility, and screen-reader acceptance targets.

Risks include sacred-text/provider drift; riwayah/edition/tokenization mismatch; inaccurate overlays; insufficient derivative/offline rights; app size/memory; search normalization errors; competing audio sessions; interrupted/low-storage installs; state loss/sync conflicts; and false Home/Khatma progress. Provider/license uncertainty blocks production ingestion, not Phase 1 evaluation with non-production fixtures.

## 18. Decision log

| ID | Frozen decision |
|---|---|
| D0-01 | Printed Mushaf is the primary reading experience. |
| D0-02 | Text mode is secondary but mandatory for semantics/accessibility. |
| D0-03 | Canonical data is independent from printed-page assets. |
| D0-04 | Stable Ayah IDs unite all Quran systems. |
| D0-05 | Architecture is Mushaf-aware from inception. |
| D0-06 | Riwayah and MushafEdition are separate. |
| D0-07 | Quran Core is immutable. |
| D0-08 | User Quran state is separate. |
| D0-09 | Position, ribbon, bookmark, history, and Khatma are distinct. |
| D0-10 | Printed pages require semantic Ayah mapping. |
| D0-11 | Future resources use modular packs. |
| D0-12 | Core reading is local-first/offline. |
| D0-13 | Audio maps through Ayah IDs, not page layout. |
| D0-14 | Licensing/authenticity is verified per resource. |
| D0-15 | Home may show no fake reading state. |

## 19. Phase 0 Definition of Done

- [x] Current Quran code/state/assets/routes and relevant architecture inspected.
- [x] No unrelated production code changed; no implementation/Phase 1 started.
- [x] Contract exists and all 46 capabilities are classified.
- [x] Stable IDs, edition-scoped pages, and Riwayah/edition distinction frozen.
- [x] Printed primary/text secondary modes and semantic overlay frozen.
- [x] Reading-state concepts separated.
- [x] Offline, packs, integrity, licensing, risks, and gaps documented.
- [x] Phase 1 inputs and next step are clear; decision log is internally consistent.

## 20. Inputs required by Phase 1

- Named scholarly/correctness and licensing approval owners.
- Exact Core/edition candidate shortlist with provenance and terms evidence.
- Evaluation-only sample manifests/pages/mappings/text (not production approval).
- Platform/device, memory/storage, accessibility, and performance targets.
- Copy/share/crop policy and initial Tafsir/recitation candidates.
- Product decisions for real-position writes, history, notes, Khatma, and initial delivery.
- Adhkar session/focus/notification/downloader/lifecycle audit.
- Persistence decision criteria, migrations, tests, sync/privacy constraints.
- Known-good navigation, difficult overlay, search, and timing acceptance fixtures.

## 21. Recommended exact next step for Phase 1

Run a **source-and-data feasibility spike**, not a reader build. Produce reviewed ADRs and executable validators for at least two exact Quran Core + initial Hafs edition candidates. For each: verify provenance/rights; define versioned identities/manifests; validate Ayah/Word coverage; test representative multi-region overlays; estimate storage/rendering costs; prove offline `search/audio → AyahKey → page/geometry`; and document the app audio-session strategy after auditing Adhkar. Finish by selecting or rejecting an initial combination and freezing conceptual schemas plus acceptance tests. Do not ingest production content until authenticity and license approval are recorded.

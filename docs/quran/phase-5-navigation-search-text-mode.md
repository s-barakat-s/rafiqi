# Phase 5 — Quran navigation, local search, and Text Mode

Prompt ID: `58421`

Status: **PHASE 5 ARCHITECTURE COMPLETE — PRODUCTION QURAN DATA PENDING**

Date: **2026-10-07**

## Renderer selection inherited

Semantic Vector is the selected default Paper Mushaf renderer technology. The
selected candidate edition is Hafs / KFGQPC 1441H / Mushaf Database SVG V1.01.
The Phase 4.5 addendum records this product decision and accepts the measured
`+75.29 MB` compiled-vector AAB delta for now.

This is not production Quran approval. Canonical token reconciliation,
authentic exact-edition fidelity verification, qualified Mushaf review,
physical-device profiling, and iOS validation remain explicit gates. Phase 5
does not reopen DigitalKhatt, QCF, or PageAsset research and does not bundle the
ignored Semantic SVG corpus.

## Navigation architecture

`QuranNavigation` is the UI-facing contract and `QuranNavigationService` is its
repository-backed implementation. It composes the existing immutable
`QuranRepository`, `MushafLayoutRepository`, and selected `MushafEdition`.

It lists Surahs, Juzs, Hizbs, and Rubs, and resolves:

- Surah start;
- Juz start;
- Hizb start;
- Rub start;
- an explicit `AyahKey`; and
- an edition-scoped `MushafPageKey`.

The Core repository now provides ordered bulk reads for Juz/Hizb/Rub boundaries
instead of making the UI loop through assumed conventional counts. Invalid,
missing, wrong-edition, empty-page, or unmapped targets return no target rather
than being guessed.

## Semantic addressing

Every successful navigation produces `QuranNavigationTarget`:

```text
canonical structural choice
  → AyahKey
  → selected MushafEdition layout
  → MushafPageKey
```

Page navigation performs the reverse lookup only to identify the first actual
semantic placement on that edition page. Bare page numbers are never stored or
returned as Quran identity. Search follows `QuranSearchResult → AyahKey →
QuranNavigationTarget`.

## Local search architecture

Search is exposed through `QuranSearchRepository` and implemented by
`SqfliteQuranSearchRepository`. It opens no network connection and searches a
build-time index inside the immutable Quran Core database.

Results include `AyahKey`, source-preserved Surah name, Ayah number through the
key, untouched display text, deterministic rank, and match classification.
Exact normalized-document matches sort before all-term matches; ties sort by
canonical global Ayah order. Query limits are bounded to 1–100.

The database contains:

- `ayah_search_documents(global_index, normalized_text)`; and
- `ayah_search_terms(token, global_index)` with a composite primary-key index
  led by `token` plus a document index.

An all-term query uses indexed token lookup, groups by semantic document, and
requires every distinct query token. The display row always comes from `ayahs`,
never from the normalized index.

## Search normalization

`ArabicSearchNormalizer` deterministically:

- lowercases casing-bearing scripts used by synthetic/test inputs;
- removes Arabic combining marks and Tatweel;
- maps Alef-with-Madda/Hamza/Wasla variants to bare Alef;
- replaces punctuation with spaces; and
- collapses whitespace.

Normalization is applied only to the derived search document and the query.
`text_uthmani` is never rewritten, repaired, or returned from the index.
`text_search` is preferred when an approved source provides it; otherwise the
index derives a searchable projection from `text_uthmani` without mutating the
canonical row.

## FTS/index decision

SQLite FTS was evaluated first. The project's supported
`sqflite_common_ffi` SQLite runtime reported `no such module: fts4`, so FTS4
could not pass the repository's cross-runtime test boundary. Depending on FTS5
would create a similar platform-build assumption.

Phase 5 therefore uses the ordinary-table inverted token index described
above. It is deterministic, covered by foreign keys and integrity checks,
portable across the current SQLite runtimes, and appropriate for the bounded
6,236-Ayah corpus. Quran Core schema is now version 2 and the deterministic
ingestion tool is `maab-quran-core-ingestion/2`. No runtime migration is needed
because no production Core artifact exists; the eventual approved artifact
must be rebuilt with v2.

## Text Mode architecture

`QuranTextModeController` depends only on `QuranRepository`. It loads one Surah
at a time, preserves canonical Ayah order and exact `textUthmani`, maintains an
optional selected `AyahKey`, validates the requested Surah boundary, and
exposes an exact semantic scroll-target index.

It has no SVG, vector-page, renderer token, OCR, font-glyph, layout-repository,
or HTTP dependency. Text Mode therefore remains usable when Paper Mushaf
geometry is unavailable, subject to an approved canonical Core being installed.

The view uses lazy slivers. The target Ayah is the center sliver anchor, so a
search/navigation route opens at the requested semantic item without building
all Quran Ayat. Text is wrapped in `SelectionArea` as the copy-ready foundation;
sharing is intentionally absent.

## UI added

- `QuranIndexScreen`: third shell destination; lazy Surah/Juz/Hizb/Rub tabs,
  search action, and direct page/Ayah jump sheet.
- `QuranSearchScreen`: debounced local search, explicit label/helper text,
  progress, helpful initial/no-result/error states, and semantic result routing.
- `QuranReaderScreen`: Paper/Text mode switch, repository-driven Text Mode, and
  a truthful Paper-mode approval placeholder while vector assets remain
  intentionally unbundled.
- Calm 180/160 ms fade routes reuse the existing navigation convention.

The screens use transparent Scaffolds, the global `AppDecorativeBackground`,
semantic `AppColors`, existing glass surfaces, ThmanyahSans for Arabic UI,
Amiri for canonical reading text, and Outfit for app-generated numerals. Lists
are lazy, controls use Material semantics/feedback, primary targets are at least
48dp, and source text is allowed to scale and wrap.

## Production data status

No production Quran text, search database, word dataset, Mushaf layout, or
Semantic Vector page is bundled. The main Quran tab displays an honest local
data approval state instead of a fake verse, fake reading position, random
dataset, or live API fallback.

Tests use only the explicitly synthetic fixture. Its Arabic-like test phrase is
labelled by the surrounding synthetic dataset metadata and is not a Quran
verse. The generated test databases remain temporary and outside production
assets.

## Offline and safety guarantees

Navigation, search, Text Mode, and page projection use repository calls only.
The Phase 5 implementation imports no HTTP client and performs zero runtime
network requests. Search indexes semantic Core text, never SVG/path data.
Missing mappings fail closed, and production activation remains governed by
the existing provenance and approval gates.

## Tests

Focused coverage includes:

- Surah/Juz/Hizb/Rub enumeration and start resolution;
- Ayah and page resolution, wrong edition, invalid numbers, and missing maps;
- search result → `AyahKey` → selected-edition page;
- exact search, Arabic normalization, no result, invalid query, deterministic
  ordering, metadata, and untouched display text;
- Text Mode ordering, Surah boundaries, semantic scroll target, selection, and
  canonical display text;
- the honest production-data-pending Quran tab;
- all inherited Core, layout, engine, cache, RTL, provenance, and Semantic
  Vector tests.

Completion result: **62 focused Quran tests passed** and `flutter analyze`
reported no issues.

## Performance notes

- Surah and structural indexes use `ListView`/sliver builders.
- Text Mode materializes one Surah model list and lazily builds visible Ayah
  widgets; it never creates a 6,236-Ayah widget tree.
- Search uses indexed token rows, a maximum result limit, and 250 ms UI input
  debounce.
- Navigation loads only requested semantic mappings and does not preload 604
  pages.
- Paper Mushaf retains the inherited current/previous/next prepared-page LRU;
  Phase 5 does not change it.

No device benchmark was required or claimed for repository/UI architecture.

## Blockers

1. Approve and build the production Quran Core v2 artifact and manifest.
2. Reconcile canonical word tokenization with Semantic Vector source identities.
3. Approve and build the edition-specific semantic layout/map.
4. Complete exact-edition fidelity and qualified Mushaf review.
5. Complete physical Android profiling and iOS runtime validation.
6. Register the approved Core/layout/vector artifacts in application startup so
   real dependencies can replace the honest unavailable state.

## Inputs for Phase 6

Phase 6 may add `LastReadingPosition`, ribbon, bookmarks, history, Khatma, and
Home continuation only after it defines a separate mutable user store. It
should consume `AyahKey` as durable identity and treat `MushafPageKey` as a
recomputable edition projection. It must replace the existing Home fake visual
fallback with genuine empty/position states and must not store user state in
Quran Core or the immutable search index.

Exact recommendation: approve and register the production Quran Core/layout
inputs before exposing real content, then begin Phase 6 at the user-state schema
and genuine-reading event boundary. Do not add Tafsir, sharing, audio, or
downloads as part of that work.

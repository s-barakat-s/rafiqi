# Canonical Quran Core — Phase 1

Status: **ARCHITECTURE COMPLETE — PRODUCTION DATA PENDING**

Project: **Maab / مَآب**

Schema version: **1**

Ingestion tool: **maab-quran-core-ingestion/1**

Date: **2026-10-06**

## 1. Phase objective

Phase 1 establishes a local, immutable semantic Quran Core boundary: stable identities, domain models, relational schema, read-only repository, version-aware verified asset installation, deterministic ingestion, provenance, integrity validation, and focused tests. It deliberately contains no reader UI, Mushaf layout/page implementation, search behavior, audio, Tafsir UI, bookmarks, reading state, Khatma, or user data.

## 2. Existing repository assumptions

- The project uses a feature-first structure, so Quran code lives under `lib/features/quran` with domain and data layers.
- The Quran shell destination remains a placeholder and is untouched.
- Home's `QuranReadingSource` returns `null`, but `_MockQuranReadingProgress` visually displays a fabricated Al-Baqarah/Ayah 157 continuation. This is not Quran state and is a mandatory future Reading State migration; Phase 1 does not modify Home.
- `SharedPreferences` is used for small preferences but is not an acceptable canonical Quran store.
- The existing Adhkar audio/session system is unrelated to this phase and untouched.
- The working tree contained substantial unrelated user changes before this work; they are preserved.

## 3. Approved/pending source

The preferred production candidate remains the **King Fahd Glorious Quran Printing Complex (KFGQPC)** Hafs developer resource. The official [Quran Hafs by KFGQPC user guide](https://download.qurancomplex.gov.sa/appres/QuranHafsGuide.pdf) confirms a developer-facing product and supplies `developer@qurancomplex.gov.sa`; however, this Phase did not locate an official, exact canonical dataset accompanied by unambiguous terms granting Maab the required bundling and redistribution rights. The official computer-publishing documentation also indicates that some commercial uses require written approval, reinforcing the need to verify the terms for the exact resource rather than infer permission.

Therefore no production source was imported and no Quran text was downloaded. Production status is **PENDING SOURCE/RIGHTS CONFIRMATION**. No GitHub, npm, pub, scraped website, or convenience dataset was substituted.

## 4. Provenance

Every accepted source envelope must provide:

- `source_provider`
- `source_resource_name`
- `source_reference`
- `source_version`
- `source_acquired_at`
- `schema_version`
- `ingestion_tool_version`
- `license_or_usage_reference`
- `attribution_notes`
- explicit expected Surah and Ayah counts
- `dataset_kind` (`production` or `syntheticTest`)

The ingestion tool calculates `source_checksum` as SHA-256 over the exact input bytes. It calculates the final database SHA-256 after closing and validating SQLite, then records both checksums plus provenance in a sidecar build manifest. Unknown/blank provenance fails validation rather than being guessed.

## 5. Source usage and licensing status

No production resource is licensed or bundled by Phase 1. Before import, the responsible owner must retain evidence covering authenticity, version, storage, app bundling, redistribution, updates, attribution, and any transformations. The exact KFGQPC resource and its applicable terms must be confirmed directly with the official provider if published terms remain unclear.

The only source file exercised by tests is `test/features/quran/fixtures/synthetic_quran_core.json`. It is visibly labeled synthetic, contains English tokens rather than Quran verses, requires an explicit builder flag, and is outside production assets.

## 6. Data architecture

```text
approved source envelope
  → pure parse and strict semantic validation
  → build-only writable SQLite staging file
  → SQLite integrity/referential/count verification
  → immutable versioned quran_core database + checksum manifest
  → verified versioned asset copy at runtime
  → read-only SQLite connection
  → QuranRepository domain objects
```

Canonical content is independent of page assets, QCF glyphs, Mushaf editions, audio, Tafsir, search behavior, and all user state. No database row ID is exposed as semantic identity.

## 7. Stable identities

- `AyahKey(surahNumber, ayahNumber)` serializes as `surah:ayah`, validates structural bounds, implements value equality, hashing, parsing, and canonical comparison.
- `WordKey(AyahKey, wordNumber)` serializes as `surah:ayah:word` and freezes future identity without claiming word data exists.
- Ayah validity beyond positive numbering is checked against the source/repository because per-Surah maxima are contextual.
- Display text, search text, page number, internal row identity, and renderer glyphs never define identity.
- No `words` table or production word rows exist because no approved word segmentation source exists.

## 8. Schema

`quran_core.db` schema version 1 contains:

| Table | Purpose |
|---|---|
| `quran_metadata` | Single provenance/convention/schema record |
| `surahs` | Number, source-preserved Arabic name, declared Ayah count |
| `ayahs` | Composite semantic key, deterministic global index, `text_uthmani`, optional `text_search` |
| `juz_boundaries` | Numbered boundary referencing an existing Ayah |
| `hizb_boundaries` | Numbered boundary referencing an existing Ayah |
| `rub_el_hizb_boundaries` | Numbered boundary referencing an existing Ayah |
| `sajdah_markers` | Source-supported marker, Ayah reference, and kind |

The Ayah primary key is `(surah_number, ayah_number)` and `global_index` is unique. Foreign keys bind structure to existing Surahs/Ayat. Indexes support per-Surah and global canonical ordering. A `words` table is intentionally deferred.

## 9. Canonical versus search text

`text_uthmani` is required, non-empty, and preserved exactly from the approved source. The pipeline never normalizes or repairs it. `text_search` is nullable and may only contain an official/source-provided orthographic representation. Phase 1 performs no aggressive derivation and builds no user-facing search engine. A normal SQLite index for canonical ordering exists; no speculative full-text index is added.

## 10. Runtime storage approach

SQLite via `sqflite` 2.4.2+1 was selected because it supports Android and future iOS, relational constraints/indexes, predictable local access, and read-only open mode while matching the project's Dart 3.10 constraint. `sqflite_common_ffi` is test/build tooling only.

When an approved database is eventually bundled, `QuranCoreAssetInstaller` will:

1. validate the declared SHA-256;
2. use a version/checksum-addressed filename in caller-supplied application storage;
3. reuse an already verified file without copying;
4. load the asset, verify bytes before writing, write a `.staging` file, flush it, verify again, then rename it;
5. never overwrite another version's filename.

`QuranCoreStore` memoizes initialization, verifies SQLite before exposure, opens with `readOnly: true`, reuses one repository/database, and supports explicit close. It is not wired into bootstrap because no production artifact exists.

## 11. Repository API

`QuranRepository` exposes immutable reads only:

- `getMetadata()`
- `getSurahs()` / `getSurah(number)`
- `getAyah(key)` / `containsAyah(key)`
- `getSurahAyahs(number)`
- `getAyahRange(start, end)`
- `resolveGlobalAyahIndex(key)`
- `getJuz(number)` / `getHizb(number)` / `getRubElHizb(number)`
- `getSajdahMarkers()`

SQL maps to domain objects inside `SqfliteQuranRepository`. No widget opens SQLite and no notifier wraps immutable reference data. There are no insert/update/delete methods.

## 12. Ingestion pipeline

`tool/quran/build_quran_core.dart` accepts a normalized, provenance-bearing trusted-source JSON envelope plus output database and manifest paths. It:

1. reads exact bytes and calculates source SHA-256;
2. parses without text rewriting;
3. checks the requested ingestion-tool version;
4. rejects synthetic input unless `--allow-synthetic-test-fixture` is explicit;
5. runs all semantic validation before database creation;
6. builds a fresh staging SQLite database with foreign keys enabled;
7. inserts deterministically in source/canonical order;
8. validates SQLite integrity, foreign keys, schema, and declared counts;
9. closes SQLite and calculates database SHA-256;
10. writes a deterministic provenance/checksum manifest;
11. renames staging artifacts to final outputs.

Any failure aborts the build. The tool never silently corrects sacred text. A provider-specific adapter may be added only after the exact approved KFGQPC format is known; it must produce this strict envelope without lossy conversion.

## 13. Integrity checks

Dataset checks include:

- required nonblank provenance and lowercase SHA-256 source checksum;
- positive schema version and source-declared count convention;
- exactly 114 Surahs for a production dataset;
- complete, unique, contiguous Surah numbering;
- unique Ayah keys and unique contiguous global indexes;
- per-Surah contiguous Ayah numbering and exact declared counts;
- non-empty source-preserved canonical text;
- valid Juz/Hizb/Rub/Sajdah Ayah references;
- non-empty Sajdah kind;
- SQLite `integrity_check`, `foreign_key_check`, schema version, and stored counts.

The standard 6,236 count is not hard-coded blindly. The approved source must declare its convention, and production approval must explicitly confirm how Basmalah and numbered Ayat are represented. Known first/last Ayah and structural anchors must be added to the production source profile once selected.

## 14. Immutable-data policy

Only the offline ingestion tool writes canonical rows. Runtime opens the artifact read-only and exposes no mutations. Activated artifacts are checksum-addressed/versioned. Quran user data is absent and will use a separate store in later phases. Tests demonstrate that runtime SQLite rejects an insert and that repeated initialization does not reinstall/reopen the core.

## 15. Test strategy and result

Focused tests use only the synthetic fixture and cover:

- AyahKey parsing, rejection, equality, comparison, and serialization;
- WordKey parsing/serialization without word ingestion;
- duplicate/missing Ayah detection;
- invalid structural foreign references;
- required provenance;
- deterministic ingestion and source/database manifest checksums;
- rejection of implicit synthetic builds;
- Surah/Ayah/range ordering, invalid lookups, boundaries, Sajdah, and metadata;
- physical read-only behavior;
- memoized initialization/no redundant installation.

Result at completion: **14 tests passed**. Targeted analysis: **no issues**.

## 16. Font and script distinction

- **Semantic Unicode direction:** a verified KFGQPC/QPC Uthmanic Hafs Unicode-compatible font is intended later for standalone Ayah text, results, Tafsir display, semantic text mode, and accessibility. The font is presentation; Unicode source text remains canonical.
- **Printed Mushaf direction:** QCF V2 or another verified page-faithful strategy may later render exact printed layouts. QCF glyph codes and per-page fonts are renderer/layout resources, never canonical text or identity.

No Quran font or 604 QCF page fonts were downloaded or bundled in Phase 1.

## 17. Known limitations

- No production Quran data/database/manifest is bundled or initialized.
- No provider-specific KFGQPC parser exists because the exact approved distribution format is pending.
- No words, search implementation, page mapping, renderer, UI, audio, Tafsir, or user state exists.
- Structural models intentionally include only source-supported boundary starts and Sajdah kind; richer metadata awaits the approved source.
- The asset installer covers verified immutable bundled artifacts. A future downloadable-pack activation pointer/rollback system remains governed by Phase 0 and later resource work.

## 18. Unresolved risks

- Exact source authenticity/version and redistribution terms.
- Source convention for the 6,236 numbered Ayat and Basmalah.
- Orthographic/search representation and word tokenization.
- Official structural metadata completeness and Sajdah classification.
- Unicode font licensing and fidelity.
- Future database upgrade/catalog signing and rollback policy.
- Platform verification on physical Android/iOS once a real artifact exists.

## 19. Migration notes

- Do not map the current Home `QuranReadingPosition` or its hard-coded Al-Baqarah/Ayah 157 label into Core. A later Reading State phase must replace the fake visual fallback with a real empty state and stable `AyahKey` persistence.
- Do not store page/Mushaf identifiers, bookmarks, history, ribbon, notes, or Khatma in `quran_core.db`.
- When production data is approved, add its normalized source outside ad-hoc manual editing, run the builder, review manifest/checksums, register the resulting asset, and configure startup separately.
- Schema/content changes produce a new immutable version; runtime never migrates canonical rows in place.

## 20. Definition of Done

- [x] Phase 0 invariants honored.
- [x] Strong stable Ayah and future Word identities implemented.
- [x] Minimal semantic models implemented.
- [x] SQLite storage boundary and schema implemented.
- [x] Runtime application API is read-only.
- [x] Deterministic ingestion and atomic publication implemented.
- [x] Provenance and dual checksums represented.
- [x] Strict source/database validation implemented.
- [x] Repository abstraction and SQLite implementation exist.
- [x] Focused tests pass; no fake Quran production data exists.
- [x] No user state, Mushaf renderer, UI, audio, or unrelated feature changes.
- [x] Documentation exists.
- [ ] Approved production data bundled — pending source/right confirmation, intentionally.

Phase 1 therefore finishes in valid state **B: ARCHITECTURE COMPLETE — PRODUCTION DATA PENDING**.

## 21. Exact Phase 2 inputs

Before Phase 2 Mushaf Edition Architecture begins, provide:

1. an approved initial Hafs Quran Core source/version and retained usage-right evidence;
2. a reviewed production source profile declaring Ayah/Basmalah/count conventions and known anchors;
3. the generated, independently reviewed `quran_core.db` and build manifest/checksums;
4. an approved initial printed Mushaf edition with stable `mushafId`, publisher, page count, asset/layout version, and redistribution/derivative rights;
5. a verified Ayah-to-page mapping for that exact edition;
6. a decision between licensed page images and a verified QCF V2/page-faithful renderer—without treating either as Quran Core;
7. representative difficult-page fixtures for multi-line Ayat, Surah openings, ornaments, and cross-page navigation;
8. Android/iOS storage, memory, rendering, zoom, and accessibility acceptance targets;
9. a signed-off rule that all Phase 2 mappings resolve through `AyahKey` and `(mushafId, pageNumber)`.

Recommended Phase 2 start: define the edition manifest and Ayah-to-page projection contract against the approved Core, then validate representative mappings before implementing any 604-page renderer or UI.

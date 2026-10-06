# Phase 3 — Word-level Mushaf foundation and renderer bake-off

Evidence labels used below:

- **FACT** — established by source inspection or implemented repository state.
- **MEASURED** — observed by a repeatable command in this workspace.
- **INFERENCE** — a conclusion drawn from facts, not a direct measurement.
- **PENDING** — not established and must not be treated as a production fact.

## 1. Phase objective

**FACT:** Phase 3 establishes provider-neutral word identity, Riwayah and Mushaf-edition identity, page/line/word layout storage, immutable provenance gates, deterministic ingestion, and a bake-off protocol for DigitalKhatt, QCF v2, and page assets.

**FACT:** This phase does not build the final reader, search, bookmarks, recitation, download flow, or production Quran dataset.

## 2. Phase 1 status

**FACT:** The Phase 1 canonical Quran core remains the source of Surah and Ayah identity. Its architecture, schema, read-only repository, deterministic builder, and synthetic tests exist.

**PENDING:** Authentic production Quran content is not yet imported or approved. Consequently, Phase 3 cannot validate authentic word boundaries against a production corpus.

## 3. Constraints

**FACT:** Canonical identity must remain independent of any rendering provider. Runtime storage is read-only. Generated resources must be versioned, checksummed, reproducible, licensed, attributable, and explicitly approved before production use.

**FACT:** Synthetic fixtures contain no Quran text and prove mechanics only. They provide no evidence of textual or visual fidelity.

## 4. WordKey

**FACT:** `WordKey` is the stable tuple `(surahNumber, ayahNumber, wordNumber)`, serialized as `surah:ayah:word`. All components are positive integers. It provides parsing, comparison, equality, hashing, and an `AyahKey` projection.

**FACT:** Provider IDs are never canonical keys. They are stored only in versioned `WordProviderMapping` records.

## 5. Word source decision and status

**FACT:** The architecture reserves a separate immutable word/layout resource database instead of adding provider-shaped word rows to `quran_core.db`. This allows word segmentation, Mushaf edition, licensing, checksum, and update cadence to be versioned independently while preserving canonical Ayah identity.

**INFERENCE:** Separation also reduces migration risk when supporting another Riwayah or edition whose word segmentation differs.

**PENDING:** No authentic word database or production segmentation source has been selected or added. A candidate must publish an exact edition/Riwayah mapping, stable version, checksum, license, commercial-use status, redistribution status, and attribution requirements.

## 6. Riwayah

**FACT:** `RiwayahId` is a validated lowercase stable slug. `hafs-an-asim` is defined as the initial identity, but the model is not an enum and therefore does not close the system to other Riwayat.

**FACT:** Resource provenance declares compatible Riwayah IDs, and an edition cannot be constructed when its Riwayah is absent from that declaration.

## 7. Mushaf edition

**FACT:** `MushafEdition` identifies a concrete layout edition independently from Riwayah. It records display/internal names, edition version, page and nominal line counts, render strategy, layout/script/font resource IDs, and provenance.

**FACT:** Dataset validation checks the edition against the provenance resource ID and compatible edition IDs.

## 8. MushafPageKey

**FACT:** `MushafPageKey` is `(MushafEditionId, pageNumber)`, serialized as `edition-id:page`. Page numbers are positive and are meaningful only inside their edition.

## 9. Page, line, and word hierarchy

**FACT:** The hierarchy is `MushafEdition → MushafPage → MushafLine → MushafWordPlacement → WordKey`.

**FACT:** Lines carry a type (`quranText`, `surahHeading`, `basmala`, or `specialLayout`), optional alignment, and optional first/last `WordKey`. Placements carry page, line, position, `WordKey`, optional glyph code, and optional provider mapping.

**FACT:** Validation detects wrong editions, missing/duplicate pages, non-contiguous line or word positions, missing lines, duplicate word placement, unknown `WordKey`/`AyahKey`, invalid line word ranges, and ambiguous provider mappings.

## 10. Storage and schema

**FACT:** `mushaf_layout` schema version 1 uses `layout_metadata`, `pages`, `lines`, `word_placements`, and `word_provider_mappings`. Foreign keys and lookup indexes support page-scoped rendering and Ayah/word location.

**FACT:** It is deliberately separate from the canonical Quran core database. The runtime store verifies schema version, integrity, foreign keys, and page count, then memoizes one read-only connection.

## 11. Repository API

**FACT:** `MushafLayoutRepository` exposes edition lookup; page, line, and placement reads; Ayah and word location; and page lookup for an Ayah or word. Results are deterministically ordered and page-key edition mismatches are rejected.

## 12. Provider mappings

**FACT:** `WordProviderMapping` binds a canonical `WordKey` to `(provider, providerWordId, resourceVersion)`. A provider ID/version pair may not map to multiple canonical words, and duplicate mappings are rejected.

**INFERENCE:** This adapter boundary permits changing renderer or data provider without leaking external IDs into bookmarks, navigation, or future user data.

## 13. Render-strategy abstraction

**FACT:** The domain recognizes `digitalKhatt`, `qcfGlyphs`, and `pageAsset`. It contains no Flutter widget and chooses no renderer.

**FACT:** `renderer_bakeoff.dart` requires exactly those three candidates and rejects a selected renderer unless production approval plus fidelity, size, performance, Android, and iOS evidence are all marked measured.

## 14. DigitalKhatt investigation

**FACT:** DigitalKhatt describes a dynamic/parametric Quran typesetting approach and repositories implementing extended OpenType behavior and an external justification algorithm. References: <https://digitalkhatt.org/about>, <https://github.com/DigitalKhatt>, and <https://github.com/DigitalKhatt/visualmetafont>.

**INFERENCE:** A single OpenType font could materially reduce asset count compared with hundreds of page fonts, but exact page fidelity depends on layout data and shaping/justification behavior, not the font file alone.

**PENDING:** No candidate font/layout artifact was imported; exact edition compatibility, redistribution rights for the chosen artifacts, Flutter engine behavior, line fidelity, binary delta, frame timing, memory, and Android/iOS parity remain unmeasured.

## 15. QCF v2 investigation

**FACT:** Quran Foundation documents QCF rendering as page-specific fonts and describes caching/bundling considerations: <https://github.com/quran/qf-api-docs/blob/main/docs/tutorials/fonts/font-rendering.md>.

**FACT:** The inspected community `qcf_quran` package advertises 604 page fonts and explicitly warns that its fonts are not for commercial use: <https://github.com/m4hmoud-atef/qcf_quran>. Its code license cannot be assumed to license bundled Quran data or fonts.

**FACT:** That dependency and its content were not added.

**PENDING:** An authoritative QCF v2 artifact set with acceptable production redistribution/commercial terms, exact edition metadata, checksums, and attribution has not been secured. Runtime font-loading behavior and memory pressure are unmeasured.

## 16. Page-asset investigation

**FACT:** Static page images provide a direct visual reference and avoid runtime shaping differences.

**INFERENCE:** They are likely the strongest fidelity fallback but probably the largest packaged/downloaded representation; word interaction also requires a separate coordinate or segmentation map.

**PENDING:** No authoritative page asset set, dimensions, encoding, interaction map, license, package delta, decode cost, cache policy, or device measurement is available.

## 17. Fidelity method

**FACT:** The planned method is pixel comparison against an authoritative edition reference at fixed viewport, scale, and font settings, followed by human review. Each case must record source edition, expected page/line boundaries, screenshot, diff, and reviewer result.

**FACT:** A renderer cannot pass from synthetic text, a package demo, or visual resemblance alone.

**PENDING:** No authentic renderer artifact was legally available in this phase, so no fidelity result is claimed.

## 18. Fidelity test categories

**FACT:** The mandatory corpus categories are: ordinary dense page; short-Ayah page; long-Ayah page; Surah heading; basmala behavior; sajdah marker; hizb/juz/rub marker; waqf signs; small high/low marks; overlapping diacritics; elongation/justification; page transition; first and final pages; and any edition-specific special layout.

**PENDING:** Exact page numbers must be chosen only after an authoritative edition is selected. Inventing page numbers now would mix editions and create false evidence.

## 19. Size method and results

**FACT:** Candidate size must be measured as a clean release artifact delta against the same target ABI and build configuration. Font/image/layout totals must also be recorded uncompressed and compressed.

**MEASURED (2026-10-06):** `flutter build appbundle --release --analyze-size --target-platform android-arm64` produced `app-release.aab` at 111.0 MB compressed. Flutter reported 92 MB under `base/assets`, 8 MB under `base/lib`, and 692 KB of decompressed Dart AOT symbols attributed to `package:tasbeh`. The report is a pre-renderer baseline only.

**FACT:** No production renderer fonts, page images, Quran word data, or layout database were added, and the Phase 3 code is not wired into the app entry point.

**PENDING:** DigitalKhatt, QCF v2, and page-asset deltas are unmeasured and must not be inferred from the 111.0 MB baseline.

## 20. Performance method and results

**FACT:** The planned profile-mode protocol records cold page open, adjacent-page navigation, worst-page layout, raster/build frame timing, peak resident memory, font/asset load time, and cache behavior on representative low- and mid-tier physical devices. Identical navigation scripts and warmed/cold states are required.

**MEASURED:** Repository tests successfully open a generated SQLite layout read-only and perform deterministic page, line, word, Ayah, and word-location queries. These are functional assertions, not performance measurements.

**PENDING:** No trustworthy renderer latency, FPS/jank, memory, or font-registration measurement exists. Flutter documents `FontLoader.load` as engine font registration and exposes no corresponding public unload method; process-lifetime behavior is therefore a risk to measure, not a proven memory result: <https://api.flutter.dev/flutter/services/FontLoader/load.html>.

## 21. Android findings

**MEASURED:** The existing application completed an arm64 release AAB build and size analysis on Windows. Kotlin emitted incremental-cache errors caused by Pub Cache and project files being on different drive roots, then fell back and completed successfully.

**FACT:** Flutter bundles fonts declared as application assets, while dynamically loaded fonts require an explicit asset/network and cache strategy. References: <https://docs.flutter.dev/cookbook/design/fonts> and <https://docs.flutter.dev/ui/assets/assets-and-images>.

**PENDING:** No candidate renderer ran on an Android device; shaping, glyph correctness, memory, and frame behavior remain unverified.

## 22. iOS findings

**PENDING:** iOS runtime validation pending.

**FACT:** The current Windows environment cannot build or profile the iOS target. No parity claim is made.

## 23. Licensing and provenance matrix

| Candidate | Source/license evidence | Commercial use | Redistribution | Production status |
|---|---|---|---|---|
| DigitalKhatt | **FACT:** project/source repositories inspected; specific production artifacts not selected | **PENDING** for exact artifact | **PENDING** for exact artifact | **PENDING** |
| QCF v2 | **FACT:** official rendering documentation inspected; community package warns fonts are non-commercial | **PENDING/blocked** until authoritative grant | **PENDING** | **PENDING** |
| Page assets | **PENDING:** no authoritative artifact selected | **PENDING** | **PENDING** | **PENDING** |
| Synthetic fixture | **FACT:** authored for this repository; no Quran text or third-party asset | internal tests only | repository test use only | **FACT:** research-only; production rejected by gate |

**FACT:** `QuranResourceProvenance` records provider, source reference, version, acquisition time, SHA-256, license reference, commercial/redistribution status, attribution, approval status, and compatibility. Production ingestion fails unless the resource is explicitly approved and both commercial use and redistribution are allowed.

## 24. Renderer decision

**PENDING:** No renderer is selected.

**MEASURED:** Running the checked-in bake-off evaluator over `renderer_bakeoff_pending.json` reports all three candidates pending and `rendererDecision=pending`. Tests prove that forcing a selection with incomplete evidence throws an error.

## 25. Decision reasons

**FACT:** Selection requires all of: authentic fidelity evidence, measured package/download size, measured device performance and memory, Android validation, iOS validation, exact edition compatibility, and production-safe provenance.

**FACT:** None of the candidates currently satisfies that complete evidence set. Choosing now would turn assumptions into architecture.

## 26. Rejected alternatives

**FACT:** Directly adopting the inspected community `qcf_quran` dependency is rejected for production because its own warning conflicts with the app's commercial-distribution requirement and its provider-shaped IDs/assets are not the canonical domain model.

**FACT:** Treating arbitrary API/provider word IDs as canonical keys is rejected. Selecting by popularity, demo appearance, or synthetic tests is rejected.

**FACT:** No rendering strategy is permanently rejected; each may re-enter when exact licensed artifacts and measured evidence exist.

## 27. Blockers

- **PENDING:** approved canonical Phase 1 production corpus/version.
- **PENDING:** authoritative word segmentation mapped to `WordKey`.
- **PENDING:** exact target Mushaf edition metadata and reference pages.
- **PENDING:** licensed candidate artifacts with commercial and redistribution clearance.
- **PENDING:** Android physical-device benchmark matrix.
- **PENDING:** macOS/Xcode/iOS device or simulator validation.
- **PENDING:** human fidelity review by a qualified Quran/Mushaf reviewer.

## 28. Exact production assets added

**FACT:** None. No Quran text, word database, Mushaf layout database, font, glyph bundle, or page image was added for production.

## 29. Exact research-only assets used

**FACT:** No third-party research asset was copied into the repository. External pages were read as references only.

**FACT:** `synthetic_mushaf_layout.json` was created locally for tests. It uses English synthetic identifiers and glyph placeholders and contains no Arabic or Quran text.

## 30. Definition of done

**MEASURED:** The implementation provides validated canonical word/page identities, multi-Riwayah-capable edition modeling, provider mappings, a separate read-only layout store, deterministic/checksummed ingestion, integrity validation, a three-candidate bake-off gate, synthetic tests, and documentation.

**MEASURED:** Focused Quran tests pass and targeted static analysis reports no issues at completion of this phase.

**FACT:** Phase 3 is complete as a foundation and evidence framework. It is not complete as a production renderer selection or production data import; those items are intentionally blocked rather than guessed.

## 31. Phase 4 inputs

Phase 4 may consume only reviewed artifacts and evidence:

1. Approved canonical Quran core manifest and checksum.
2. Selected Riwayah and exact Mushaf edition identifier/version.
3. Approved word segmentation and deterministic `WordKey` mapping.
4. Licensed layout/script/font/page resources with provenance records.
5. Completed fidelity corpus and reviewer sign-off.
6. Repeated release-size deltas for all viable candidates.
7. Android and iOS profile measurements using the same protocol.
8. A bake-off file whose selected renderer passes every machine-enforced gate.

Until those inputs exist, Phase 4 must preserve `rendererDecision=pending` and must not embed unapproved Quran resources.

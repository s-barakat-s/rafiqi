# Phase 4 — Default Mushaf renderer decision and paper Mushaf engine

Status: **PHASE 4 ARCHITECTURE COMPLETE — RENDERER STILL PENDING**

Evidence labels are **FACT**, **MEASURED**, **ESTIMATED**, **INFERENCE**, and **PENDING VERIFICATION**. A measurement is intentionally narrower than a production qualification.

## 1. Phase objective

**FACT:** Phase 4 strengthens the DigitalKhatt/QCF V2/page-asset evaluation and builds the renderer-independent, offline Paper Mushaf Engine. It does not create the production Quran tab or begin Phase 5.

## 2. Inherited Phase 1 status

**FACT:** Phase 1 remains **ARCHITECTURE COMPLETE — PRODUCTION DATA PENDING**. No approved canonical Quran corpus was introduced. Renderer glyph/script data never replaces canonical Quran identity.

## 3. Inherited Phase 3 status

**FACT:** Phase 3 provides `WordKey`, `AyahKey`, Riwayah/edition identity, immutable layout storage, deterministic ingestion, provenance gates, and the three-candidate bake-off. It entered this phase with no production Quran renderer asset and `rendererDecision=pending`.

## 4. Current default edition candidate

**FACT:** The candidate is Hafs 'an Asim, Madinah Mushaf, KFGQPC V2 / 1421H-style layout, 604 pages, normally 15 lines on standard pages.

**FACT:** The proposed stable ID is `madinah-kfgqpc-v2-1421h-hafs`, following the Phase 3 lowercase-slug convention.

**PENDING VERIFICATION:** This is not an active `MushafEdition`. Exact production resources, checksums, authenticity review, and approvals are missing.

## 5. Sources inspected

**FACT:** Primary/current sources inspected on 2026-10-06:

- QUL DigitalKhatt KFGQPC V2 layout: <https://qul.tarteel.ai/resources/mushaf-layout/21>
- QUL KFGQPC V2 layout and related QPC resources: <https://qul.tarteel.ai/resources/mushaf-layout/10>
- QUL DigitalKhatt V2 word script: <https://qul.tarteel.ai/resources/quran-script/48>
- QUL DigitalKhatt V2 font: <https://qul.tarteel.ai/resources/font/247>
- QUL QPC V2 word glyphs and fonts: <https://qul.tarteel.ai/resources/quran-script/61> and <https://qul.tarteel.ai/resources/font/249>
- DigitalKhatt font, tooling, HarfBuzz fork, and mobile draft: <https://github.com/DigitalKhatt/madinafont>, <https://github.com/DigitalKhatt/visualmetafont>, <https://github.com/DigitalKhatt/harfbuzz/tree/justification>, and <https://github.com/DigitalKhatt/mushaf-react-native>
- Quran Foundation font guide and current Developer Terms: <https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/> and <https://api-docs.quran.com/legal/developer-terms/>
- King Fahd Complex technical resources: <https://qurancomplex.gov.sa/>
- Flutter font loading and engine architecture: <https://api.flutter.dev/flutter/services/FontLoader-class.html> and <https://github.com/flutter/flutter/blob/master/docs/about/The-Engine-architecture.md>

## 6. License and terms findings

**FACT:** `DigitalKhatt/madinafont` is SIL OFL 1.1. The license permits embedding and redistribution with software subject to its notice/license and reserved-name conditions.

**FACT:** The font license does not by itself grant rights to the QUL Quran script or layout exports. QUL resource-specific production rights and attribution remain **PENDING VERIFICATION**.

**FACT:** Current Quran Foundation terms allow font files and Mushaf images from its APIs/documented CDN URLs to be cached or bundled only as an integrated part of an application when the developer maintains an active Developer Console account and provides reasonably accessible Quran Foundation credit. They prohibit offering those files through a standalone asset pack, own API, or standalone download.

**FACT:** Regular QF API content cannot simply be made permanently offline from ordinary API responses. Content Sync rules apply where available, and prepackaged content is not automatically authorized.

**INFERENCE:** A future Maab-hosted standalone QCF pack is not compatible with the current express font permission. Integrated application bundling may be viable after the account/credit/source conditions are satisfied.

## 7. DigitalKhatt evidence

**FACT:** QUL publishes a compatible trio: a KFGQPC V2 1421H-copy layout, DigitalKhatt V2 word-by-word Unicode script with `surah:ayah:word` locations, and a DigitalKhatt V2 variable font.

**FACT:** DigitalKhatt documents three justification approaches. The extended approach requires its custom HarfBuzz branch. The standard OpenType approach still requires an external algorithm to choose per-word features. A third approach requires per-character feature control that is not widely available in native text APIs.

**FACT:** Flutter uses HarfBuzz for shaping, but that fact does not mean Flutter ships DigitalKhatt's justification fork or external algorithm.

**MEASURED:** The current QUL `DigitalKhattV2.otf` response/file was 521,832 bytes, SHA-256 `0935c48269a57c9808e52dfae47864c189396452901c689977156036a72dd217`. Its ZIP entry inside the research AAB was 279,108 bytes.

**PENDING VERIFICATION:** No actual Flutter page/line pipeline, justification adapter, golden comparison, Android device profile, or iOS run was completed. Standard Flutter text cannot be declared sufficient.

## 8. QCF V2 evidence

**FACT:** QUL and Quran Foundation describe one page-specific font for each of 604 pages, paired with QPC V2 `code_v2` word glyphs and physical line grouping. Word locations preserve semantic mapping, while glyph codes remain rendering data.

**FACT:** Quran Foundation recommends loading page fonts on demand and caching loaded families. Flutter's public `FontLoader` has a load operation but no public unload operation; registered-family lifetime must be treated as process-lifetime unless platform testing proves otherwise.

**MEASURED:** Fifteen evenly distributed TTF files (pages 1, 2, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, and 604) totaled 5,378,032 raw bytes and 3,285,247 compressed AAB-entry bytes.

**ESTIMATED:** Linear extrapolation gives 216,555,422 raw bytes and 132,285,946 compressed AAB-entry bytes for 604 fonts. This is not a full-edition build measurement; font sizes vary and bundle metadata is excluded. It materially exceeds the preferred 15–25 MB incremental budget and triggers mandatory architecture review.

**PENDING VERIFICATION:** Authentic glyph/layout ingestion, actual rendering, process memory after repeated page navigation, and lawful production source activation remain untested.

## 9. PageAsset evidence

**FACT:** Page images can preserve a fixed reference appearance and avoid runtime shaping variation. They require normalized semantic overlays for word interaction and must use target-resolution decode, not unrestricted source decode.

**INFERENCE:** Accessibility, word highlighting, crop/share semantics, and multi-edition storage are more complex than text/glyph renderers.

**PENDING VERIFICATION:** No authoritative licensed image set was selected or downloaded, so fidelity, compressed/installed size, decode memory, high-DPI quality, and page-turn performance are not measured.

## 10. Representative benchmark pages

**FACT:** QUL page previews confirm pages 1 and 2 for the candidate DigitalKhatt/KFGQPC V2 layout.

**MEASURED:** The 15 page numbers listed in section 8 were used only as an evenly distributed font-size sample. They are not claimed to be the fidelity corpus.

**PENDING VERIFICATION:** Exact pages for dense middle text, a long Ayah, multiple Ayat on one line, cross-line Ayah, Surah transition, basmala/heading, Juz boundary, Sajdah, and late short-Ayah density must be selected from the approved edition and independently confirmed. No page category is fabricated here.

## 11. Fidelity results

| Candidate | Result | Basis |
|---|---|---|
| DigitalKhatt | **NOT TESTABLE** | Compatible trio found, but no Flutter justification implementation or authentic golden run |
| QCF V2 | **NOT TESTABLE** | Compatible font/glyph/layout model found, but no authentic local pipeline or device screenshots |
| PageAsset | **NOT TESTABLE** | No approved reference image set |

**FACT:** No candidate passes the Phase 4 fidelity gate. No pixel-perfect claim is made.

## 12. Semantic results

**MEASURED:** The engine enforces an exact one-to-one set match between layout `WordKey` values and renderer output words. Missing, extra, duplicate, or wrong-page renderer results fail preparation.

**MEASURED:** Synthetic tests prove visual token → `WordKey` → `AyahKey`, word/Ayah page projection, normalized hit testing, and multiple regions for one Ayah across lines.

**PENDING VERIFICATION:** Provider word segmentation has not been validated against an approved production canonical word dataset.

## 13. Size baseline

**MEASURED (Phase 3):** Android arm64 release AAB baseline was 116,412,402 bytes, reported by Flutter as approximately 111.0 MB; approximately 92 MB was existing unrelated assets.

**FACT:** That total is not Quran incremental size. Existing assets were not optimized or changed by this phase.

## 14. Incremental size measurements

**MEASURED:** QCF sample asset entries add 3,285,247 compressed bytes for 15 page fonts. The sample AAB was 119,702,477 bytes, a 3,290,075-byte delta over the recorded baseline including asset metadata.

**MEASURED:** DigitalKhatt's single font adds 279,108 compressed AAB-entry bytes. The second incremental build retained the earlier QCF intermediate assets, so its total AAB delta is not a valid standalone DigitalKhatt delta; the per-entry ZIP measurement is the valid reported number.

**MEASURED:** After restoring production `pubspec.yaml` and removing only the generated research intermediates, the final arm64 AAB was exactly 116,412,402 bytes—the recorded Phase 3 baseline—and contained zero `phase4_research` ZIP entries. The production Quran asset/AAB delta is therefore 0 bytes at this phase boundary. Engine code is not connected to `main.dart` and is tree-shaken from the application build.

## 15. Performance results

**MEASURED:** Forty focused Quran tests complete successfully, including lazy preparation, concurrent request deduplication, cache hits, bounded eviction, repository projection, and safe failure behavior.

**FACT:** Unit-test completion is not a renderer performance benchmark.

**PENDING VERIFICATION:** No profile/release renderer initialization, DB timing distribution, page-swipe frame timing, font-load duration, RSS, raster cache, or repeated-navigation measurement was available. No 16 ms/8 ms target claim is made.

## 16. Android results

**MEASURED:** Android arm64 release AAB builds succeeded for the QCF subset and combined research-asset measurement.

**PENDING VERIFICATION:** No physical Android device was available. Fidelity, gesture feel, registered-font memory, cold/warm timing, and frame behavior are unvalidated.

## 17. iOS status

**PENDING VERIFICATION:** iOS runtime validation pending.

**FACT:** Windows cannot build or profile the iOS target, so no cross-platform parity claim exists.

## 18. Renderer decision

DEFAULT MUSHAF RENDERER DECISION

- Edition: candidate `madinah-kfgqpc-v2-1421h-hafs`
- Winner: **NONE**
- Fidelity: all candidates **NOT TESTABLE**
- Semantic support: engine contract passes synthetic tests; production mapping pending
- Measured size: DigitalKhatt font 279,108 compressed entry bytes; QCF 15-font sample 3,285,247 compressed entry bytes
- Projected full size: QCF fonts approximately 132,285,946 compressed entry bytes (**ESTIMATED**); other complete candidate costs pending
- Measured performance: engine mechanics only; no renderer profile
- Android: release builds pass; runtime pending
- iOS: pending
- License: conditional/partial findings; complete artifact set not approved
- Production eligibility: false
- Known risks: shaping/justification, QCF memory and size, changing upstream content, legal/account conditions, missing canonical data, and absent scholarly/device review

## 19. Decision confidence

**FACT:** Confidence that no renderer may yet be activated is **HIGH** because mandatory fidelity, Android profile, iOS, and complete production-provenance gates are objectively absent.

**PENDING VERIFICATION:** Confidence in which renderer will ultimately win is **LOW**. DigitalKhatt remains the preferred next technical experiment; QCF remains the fidelity-oriented fallback subject to size/legal constraints.

## 20. Production eligibility

**FACT:** No renderer is production eligible. The bake-off file retains `selected_renderer: null` and records measurements without marking size/fidelity/performance/platform evidence complete.

**FACT:** Production engine initialization requires approved layout plus approved, compatible script/font assets. Research-only, rejected, missing, duplicate, wrong-edition, or wrong-Riwayah resources fail activation.

## 21. Engine architecture

**FACT:** `DefaultMushafEngine` consumes `MushafLayoutRepository` and a `MushafRendererAdapter`. Widgets are not part of the engine and never query SQLite.

Flow: edition/provenance validation → local page/line/placement reads → renderer adapter → semantic output validation → immutable `MushafPreparedPage`.

**FACT:** Runtime engine code imports no HTTP/CDN/API library.

## 22. Page preparation architecture

**FACT:** Preparation requests one page and concurrently obtains the page record, ordered lines, and ordered placements. It validates edition/range, page existence, contiguous line/word order, renderer page identity, and the exact renderer/layout word set.

**FACT:** Concurrent requests for the same page share one in-flight future. Failures are removed from cache so a controlled retry is possible.

## 23. Cache strategy

**FACT:** Default capacity is three prepared pages: current hot, previous warm, next warm. `prepareWindow` deliberately prefetches current ±1 and retouches current as most recently used. The LRU map evicts beyond its explicit bound.

**FACT:** The engine never materializes 604 pages or a full Quran word list. `clearPreparedPages` releases page-level objects; it does not pretend to unload engine-registered fonts.

## 24. Font and image strategy

**FACT:** No font/image cache is implemented before renderer selection.

**FACT:** If QCF wins, font files on disk, engine-registered font families, prepared pages, widgets, and glyph raster cache must be tracked as distinct lifetimes. Registration is load-once; there is no fake unload API.

**FACT:** If DigitalKhatt wins, one compatible font/shaper initialization is shared and page data remains bounded. If page assets are used, normalized target decode and a current ±1 image window are required, with explicit control of Flutter's global image cache.

## 25. Semantic hit-testing strategy

**FACT:** Renderer words carry canonical `WordKey` and zero or more normalized `[0,1]` page regions. Hit testing returns the prepared word and therefore its `AyahKey`.

**FACT:** Regions are renderer output, not canonical Quran truth. Text/glyph adapters may derive them from actual spans/runs; page assets require normalized overlays. Absolute device pixels are forbidden as stored geometry.

**FACT:** `AyahKey → List<MushafNormalizedRect>` supports an Ayah occupying multiple lines or separated runs.

## 26. RTL mapping

**FACT:** `MushafPageIndexMapper` centralizes mapping for a 604-page lazy view: page 604 maps to view index 0 and page 1 maps to index 603. Advancing from page N to N+1 decreases the view index; previous does the reverse.

**FACT:** A future dev/production PageView must use this mapping with an explicitly fixed axis direction and verify rightward next-page gesture behavior. No accidental `reverse`/ambient-direction combination is accepted.

## 27. Responsive behavior

**FACT:** The prepared model preserves edition line boundaries and order. A renderer may scale/fit the fixed logical page but may not reflow words across Mushaf lines.

**FACT:** Extreme text scaling will be handled by later Text Mode rather than corrupting printed-page composition.

## 28. Error behavior

**FACT:** Wrong edition, invalid page, missing page, corrupt ordering, missing renderer resource, wrong strategy, unapproved provenance, mismatched renderer page, or mismatched word set produces a typed controlled failure.

**FACT:** There is no fallback to a system Arabic font, another edition, another renderer, or network content.

## 29. Tests

**MEASURED:** `flutter test test/features/quran` passes **40 tests**. New coverage includes page loading/order, invalid/mismatched page, concurrent deduplication, ±1 prefetch, bounded LRU eviction, projections, multi-line Ayah regions, hit testing, research/production provenance, missing resources, wrong renderer strategy, and reversible RTL mapping.

**PENDING VERIFICATION:** No authentic visual golden was committed because no fully approved benchmark artifact/reference pair exists. The reproducible future procedure is fixed viewport/scale → candidate screenshot → authoritative same-edition reference → pixel diff → qualified human review.

## 30. Production assets added

**FACT:** None. No Quran text, word dataset, layout database, font, glyph data, or page image is declared in production Flutter assets.

## 31. Research-only artifacts used

**FACT:** One DigitalKhatt OTF and fifteen QCF V2 TTF files were downloaded from the QUL CDN solely into gitignored `.dart_tool`/generated `build` research areas for size measurement. Their sizes and checksums were recorded; they are not canonical truth or production-approved content.

**FACT:** No Quran script/layout export or reference image was downloaded or committed.

## 32. Remaining blockers

- Approved canonical Phase 1 corpus and word segmentation.
- Exact QUL layout/script license, attribution, version, and checksum approval.
- Active Quran Foundation Developer Console account and recorded acceptance of current terms if QF assets are used.
- A working Flutter DigitalKhatt justification proof using the exact trio.
- Authentic 10–15-page fidelity corpus and qualified human review.
- Android physical-device release/profile measurements.
- macOS/Xcode and iOS runtime validation.
- Full candidate installed size and memory measurements.

## 33. User action required

1. Create/maintain the Quran Foundation Developer Console account and approve the in-app attribution location if QF fonts/images are pursued.
2. Obtain written, resource-specific confirmation for bundling the chosen QUL layout and word script, including commercial application use and update obligations.
3. Provide or approve Android test devices and a macOS/iOS test environment.
4. Nominate a qualified Quran/Mushaf reviewer and approve the exact reference edition/pages.
5. Approve a separate DigitalKhatt Flutter proof-of-concept before any native/custom HarfBuzz dependency is adopted.

## 34. Definition of Done

**MEASURED:** Phase 3 contracts are reused; stronger source/legal/size evidence is recorded; the renderer remains explicitly pending; no arbitrary Quran source or unapproved production asset was added; semantic IDs survive preparation; the storage/render boundary is clean; page preparation is lazy; current ±1 caching is bounded; runtime has zero network knowledge; RTL and failure paths are tested; focused tests and analysis pass.

**FACT:** Phase 4 legitimately completes in state **C: PHASE 4 ARCHITECTURE COMPLETE — RENDERER STILL PENDING**. State A or B would require unsupported claims.

## 35. Exact Phase 5 inputs

Phase 5 must not start until review accepts:

1. A completed renderer bake-off with authentic fidelity evidence and a non-null winner.
2. Approved production provenance for layout, script, font/image resources, and canonical word mapping.
3. The exact edition manifest for `madinah-kfgqpc-v2-1421h-hafs` or its reviewed replacement.
4. Android profile results and iOS runtime results.
5. Full incremental compressed/installed size and memory evidence.
6. Qualified human review of the representative fidelity corpus.
7. A legal/account record satisfying Developer Console, attribution, bundling, caching, correction/update, and redistribution conditions.

Recommendation: run a narrowly scoped DigitalKhatt Flutter justification proof first. If it cannot reproduce the approved pages without risky native shaping, perform a QCF V2 device proof with load-once font registration and revisit whether the estimated full-font cost requires an integrated on-demand strategy that still satisfies the offline-by-architecture requirement and current terms.

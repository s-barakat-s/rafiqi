# Phase 4.5 — Renderer Resolution Proof

Prompt ID: `73164`

Evidence labels in this report have strict meanings: **FACT** is directly
established by source material or repository inspection; **MEASURED** is an
experiment performed in this repository; **ESTIMATED** is a disclosed
calculation; **INFERENCE** is a reasoned conclusion; **PENDING VERIFICATION**
requires further technical evidence; and **PENDING RIGHTS** requires a
resource-owner or legal determination.

## 1. Objective

**FACT:** Phase 4.5 compares Semantic Vector, DigitalKhatt Precomputed, QCF V2,
and Raster PageAsset as Maab's default fixed-page Mushaf renderer. The decision
criteria are exact-edition correctness, semantic identity, offline operation,
Quran-only size, runtime performance, memory, platform feasibility, licensing,
and maintainability. Phase 5 is outside this phase.

## 2. Inherited architecture

**FACT:** Phases 1, 3, and 4 already provide canonical `AyahKey`/`WordKey`
identity, `MushafEdition`, page/line/word layout, provenance gates, a renderer
adapter boundary, renderer-independent preparation, RTL page mapping, semantic
regions, and a prepared-page LRU of three. Phase 4.5 adds a renderer-neutral
`MaabVectorPage` research model and compiler without activating a renderer.

## 3. Why Phase 5 remains blocked

**INFERENCE:** No candidate has the complete combination needed for a technical
selection. Semantic Vector has exact corpus and AAB measurements but lacks an
authentic reference comparison and device evidence. DigitalKhatt has a credible
precomputed-layout route but no comparable generated 604-page payload. QCF is
fully size-measured but lacks runtime and fidelity validation. Raster has no
approved, exact-edition corpus. Therefore the default renderer technology is
not yet known, and the Phase 5 gate remains closed.

## 4. Size methodology

**MEASURED:** Every Android candidate AAB was built from the same repository
state and differed only by the temporary candidate asset declaration. A local
optimal ZIP was also produced for source-corpus comparison. Raw source bytes,
archive bytes, AAB delta, and file-count figures are kept separate. Temporary
asset declarations were removed after measurement.

**FACT:** Total Maab size is informational because unrelated development audio,
theme, and branding assets are present. Installed-size delta is **NOT
MEASURED**.

## 5. Quran-only incremental size rule

The frozen rule is:

```text
Quran incremental size = candidate AAB bytes - identical baseline AAB bytes
```

**MEASURED:** The identical baseline is `118,242,267` bytes. Its SHA-256 is
`4FDAE5334D5332E6691FAA3BE4CBBAAEA3F773BBFC10EB4B678AEAC717F93092`.
The long-term preference is 15–25 MB compressed; more than 30 MB requires an
architecture review. This is a product target, never permission to reduce Quran
correctness.

## 6. Semantic SVG source/resource findings

**FACT:** The evaluated source is
[Mushaf Database Ligature-Based SVG](https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG),
also catalogued as [QUL resource 569](https://qul.tarteel.ai/resources/mushaf-layout/569?page=2).
The frozen source is SVG V1.01, commit
`ae5786ab08597f8123575dec4e774f1eca195e0f`, 604 pages, Hafs, KFGQPC 1441H.
The repository `LICENSE` expressly permits lawful use, copying, modification,
publication, distribution, and derivative works, including commercial use,
subject to preserving Quran integrity.

**FACT:** The research copy is identified by a locally produced corpus ZIP
SHA-256 of
`6F22381317B5241A3AA4EACDC15720447E7304937D1B0C4FB1CCDB91CC65F9C2`.
**PENDING VERIFICATION:** Attribution wording and qualified Mushaf approval must
be settled before production. This report does not treat a repository license
as religious proofreading.

## 7. Semantic SVG structure

**MEASURED:** All 604 real SVGs were parsed. Each uses `viewBox="0 0 382.68
547.09"`, `preserveAspectRatio="xMidYMid meet"`, a `md-page` hierarchy, page
rectangles, 15 `md-line-NN` groups, and `md-word-NNN` groups. Word groups expose
Surah, Ayah, line, word-index-in-Ayah, Hafs text, and Imlaey text attributes.
Paths and ligature groups retain visual order; diacritics/dots, `data-type=waqf`,
`md-aya-mark-*`, Surah headings, Basmala, and margin ornaments are identifiable.

**MEASURED:** The corpus contains no SVG `transform`, `defs`, `use`, style,
fill, stroke, or clip-path attributes. The compiler nevertheless retains a
combined transform string and fails closed when transformed bounds cannot be
normalized. It retains page/line identity, geometry order, source checksum,
`WordKey`, `AyahKey`, word regions, and Ayah runs.

**PENDING VERIFICATION:** The source contains 91,451 distinct word identities,
including standalone Waqf and waw groups. These source identities must be
reconciled against Phase 1's canonical tokenization before production; equal
field names alone do not prove canonical-token equivalence.

## 8. Full SVG corpus size

**MEASURED:** 604 files total `398,233,152` raw bytes. Page sizes are minimum
`203,544`, median `655,696.5`, p95 `771,775`, and maximum `862,832` bytes. The
local optimal ZIP is `80,255,672` bytes, or 20.15% of raw size.

## 9. Raw SVG renderer results

**MEASURED:** A raw-SVG AAB is `198,643,278` bytes, an incremental
`+80,401,011` bytes. SHA-256:
`B1080B87997F6B82974A36287F60EEEFEC3387B5F654A2B139790D8088AD104D`.

**MEASURED:** Official Flutter `vector_graphics_compiler.encodeSvg`, with
geometry optimizers disabled, prepared representative pages on the Windows host
in `27,404–78,687 µs`. This is host compilation, not first render. Raw parse,
first render, cached render, page swipe, FPS, and RAM are **NOT MEASURED —
PHYSICAL DEVICE REQUIRED**.

## 10. Compiled-vector results

**MEASURED:** All 604 pages compiled and JSON-round-tripped without semantic or
geometry-order change. Compact JSON is `368,150,640` bytes. Per-page gzip totals
`75,068,875` bytes: minimum `36,963`, median `124,275.5`, p95 `141,571`, maximum
`155,761`. This is 18.85% of raw SVG, but only `5,186,797` bytes (6.46%) smaller
than the already compressed raw-SVG ZIP.

**MEASURED:** The compiled AAB is `193,529,025` bytes, an incremental
`+75,286,758` bytes. SHA-256:
`7A59A805ED329F86C2EC3287CF43658C953B74F6F2AA37B0D1D9AC6BB4605C0F`.
It saves `5,114,253` AAB bytes relative to raw SVG but remains far beyond the
30 MB review threshold.

**MEASURED:** The corpus has 620,315 paths, 91,451 source word identities,
13,273 Ayah-line runs, 431,784 diacritic/dot paths, 4,272 Waqf paths, 12,472
Ayah-marker paths, and 12,155 decoration paths. Host semantic compilation has
median `66,694.5 µs`, p95 `80,462 µs`, maximum `201,595 µs`; gzip decode plus
model reconstruction has median `8,223 µs`, p95 `13,144 µs`, maximum `19,653
µs`. These are host load measurements, not device rendering measurements.

**MEASURED:** Exact path reuse is negligible: 618,843 unique paths among
620,315. Translation normalization finds 69,871 unique suffixes across 454,423
translation-safe paths, but a theoretical uncompressed dictionary geometry
payload is still `205,570,792` bytes before metadata/container overhead.
**INFERENCE:** A shared dictionary has real redundancy but has not demonstrated
enough end-to-end benefit to justify more complex random access and
reconstruction. No fragile custom format was selected.

## 11. DigitalKhatt precomputed investigation

**FACT:** The credible architecture is trusted words → build-time DigitalKhatt
layout/justification → precomputed glyph/vector placement → compact local pages
→ Flutter Canvas, not Flutter `Text` spacing. The
[DigitalKhatt organization](https://github.com/DigitalKhatt),
[digitalkhatt-js](https://github.com/DigitalKhatt/digitalkhatt-js),
[mushaf-react-native](https://github.com/DigitalKhatt/mushaf-react-native),
[VisualMetaFont](https://github.com/DigitalKhatt/visualmetafont),
[madinafont](https://github.com/DigitalKhatt/madinafont), and its
[HarfBuzz justification branch](https://github.com/DigitalKhatt/harfbuzz/tree/justification)
demonstrate that build-time/precomputed layout is feasible.

**MEASURED:** The candidate font is `521,832` raw bytes and `279,108` bytes as
an AAB ZIP entry. **NOT MEASURED:** a generated 604-page layout payload, AAB
delta, decode, render, RAM, Android runtime, iOS runtime, and semantic mapping.
It therefore remains capable of competing but cannot yet win.

## 12. DigitalKhatt licensing

**FACT:** `madinafont` is OFL-1.1; current `digitalkhatt-js` and
`mushaf-react-native` repositories are MIT; VisualMetaFont and the LuaLaTeX
package are AGPL-3.0. The HarfBuzz work derives from MIT-licensed HarfBuzz, but
the exact fork notices and contribution boundary still require review.

**INFERENCE:** An AGPL tool may possibly remain an isolated build-time tool with
only generated data shipped, but that conclusion requires legal review and
confirmation of generated-output rights. **PENDING RIGHTS:** the exact QUL
layout, script, mapping resources, generated placement data, notices, hosting,
and redistribution terms. Contact Tarteel/QUL and DigitalKhatt maintainers, and
obtain counsel on the build-tool/output boundary.

## 13. QCF complete corpus measurement

**MEASURED:** All 604 documented QCF V2 page fonts from Quran Foundation were
downloaded to the ignored research directory. They total `207,809,084` raw
bytes; minimum `163,044`, median `341,986`, p95 `390,840`, maximum `884,644`.
The same local ZIP method yields `136,040,757` bytes. ZIP SHA-256:
`ABA45DE7EEDE3315E986D6815CD174837EDE0975CE21F0BC2BA6B8C8B72064B3`.

**FACT:** The source route and page-font model are documented by
[Quran Foundation](https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/).
Page 1 SHA-256 is
`1686695486474B88A24A05CD4578F5295961BC9516885309EC95BE574F213C27`;
page 604 is
`9E5705D1AAE6A02BCE46BCA026D1048F19F76BAC013C28D5934806390493C43A`.
The current [QUL QCF record](https://qul.tarteel.ai/resources/font/249)
describes approximately 1423H; the brief's 1421H label is therefore recorded as
an edition-metadata discrepancy requiring resolution, not silently conflated.

## 14. QCF exact AAB delta

**MEASURED:** The full QCF AAB is `254,412,593` bytes, an incremental
`+136,170,326` bytes against the identical baseline. SHA-256:
`51A784DD65948A1BBC504E114B6BC5A2C1AC28355EF9F42D39F9776A7B75249F`.
This is exact, not the Phase 4 extrapolation, and triggers mandatory
architecture review. Installed delta is **NOT MEASURED**.

## 15. QCF long-session findings

**FACT:** The page fonts are already effectively page-specific subsets. No
further subsetting was attempted because glyph mapping, GSUB/GPOS, marks,
fidelity, and modification rights were not proven safe.

**PENDING VERIFICATION:** Long-session font registration, memory trend, crash
behavior, and warm performance are **NOT MEASURED — PHYSICAL DEVICE REQUIRED**.
The prepared-page LRU does not unregister fonts loaded through Flutter's
`FontLoader`; it must not be described as a font-lifetime bound.

## 16. PageAsset findings

**PENDING RIGHTS:** No complete raster source with an exact declared edition and
verified Maab commercial/offline redistribution rights was identified. Quran
Foundation resources would inherit its account, credit, integration, and
redistribution restrictions. KFGQPC publishes digital resources through its
[developer platform](https://qurancomplex.gov.sa/en/techquran/dev/) and
[apps](https://qurancomplex.gov.sa/en/techquran/techquran-apps/techquran-apps-publishios/),
but exact page-image rights for this product have not been established.

**NOT MEASURED:** 604-page compressed total, installed delta, high-DPI visual
quality, and page-turn decode. **ESTIMATED:** a 1440-pixel-wide RGBA page at the
SVG aspect ratio is about 1440×2059×4 = `11.86 MB` decimal; current ±1 decoded
pages would be about `35.6 MB` before cache/framework overhead. This is not a
corpus or runtime measurement.

## 17. Edition distinctions

| Candidate | Claimed/evaluated edition |
|---|---|
| Semantic Vector | Hafs, KFGQPC 1441H, SVG V1.01 |
| DigitalKhatt Precomputed | intended KFGQPC V2-style Hafs; exact frozen layout/script version pending |
| QCF V2 | QPC/QCF V2 Hafs, QF Mushaf ID 1; 1421H in brief versus about 1423H in current QUL metadata, pending resolution |
| Raster PageAsset | no source or edition selected |

**FACT:** Legitimate differences between editions are not fidelity failures.
Every candidate must be compared only with an authentic reference for its exact
claimed edition.

## 18. Fidelity corpus

**FACT:** The deliberate 15-page set is pages 1, 2, 22, 42, 48, 176, 255,
293, 336, 365, 454, 500, 550, 600, and 604. It covers opening pages,
headings/Basmala, Juz/Hizb markers, the long and dense 2:282 composition,
multi-line Ayat, multiple Ayat per line, documented Sajdah contexts, full-line
justification, centered/special lines, difficult marks, and late short-Ayah
density. Equivalent page/content locations must be selected per edition.

## 19. Fidelity results

| Candidate | Classification | Result |
|---|---|---|
| Semantic Vector | **NOT TESTABLE** | Source geometry and composition were preserved, but no independent authentic exact-edition visual reference and qualified review were completed. Fidelity validation is pending. |
| DigitalKhatt Precomputed | **NOT TESTABLE** | No full generated renderer artifact exists in this phase. |
| QCF V2 | **NOT TESTABLE** | Fonts were size-tested only; exact layout/reference comparison was not run. |
| Raster PageAsset | **NOT TESTABLE** | No approved exact-edition corpus was selected. |

No candidate is marked PASS. Machine structure checks are not a substitute for
authentic comparison or qualified Mushaf review.

## 20. Semantic results

**MEASURED:** The Semantic Vector compiler proves source visual element →
source-derived `WordKey` → `AyahKey`, and `AyahKey` → all per-line visual runs.
It derives normalized source bounds, supports hit testing, preserves 15-line
composition under uniform phone/tablet scaling, and never reflows words. Every
compiled page round-tripped; malformed identity, edition mismatch, and checksum
mismatch fail closed. This is a technical source-semantic pass with the known
canonical-token reconciliation limitation.

| Candidate | WordKey | AyahKey / multi-run | OCR dependency |
|---|---|---|---|
| Semantic Vector | **TECHNICALLY PASSED at source-identity level; canonical reconciliation pending** | **TECHNICALLY PASSED** | none |
| DigitalKhatt Precomputed | **PENDING VERIFICATION** | **PENDING VERIFICATION** | should be none if generated from canonical words |
| QCF V2 | **PENDING VERIFICATION** | **PENDING VERIFICATION** | none if provider mappings are approved and complete |
| Raster PageAsset | **PENDING VERIFICATION** separate overlay required | **PENDING VERIFICATION** separate overlay required | reject any OCR-derived production map |

## 21. Performance results

| Candidate | Cold/load evidence | First/warm render | Page swipe |
|---|---|---|---|
| Raw SVG | host vector preparation 27.4–78.7 ms on representative pages | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** |
| Compiled Semantic Vector | host decode median 8.223 ms, p95 13.144 ms | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** |
| DigitalKhatt Precomputed | **NOT MEASURED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** |
| QCF V2 | **NOT MEASURED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** |
| Raster PageAsset | **NOT MEASURED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** | **NOT MEASURED — PHYSICAL DEVICE REQUIRED** |

Host parsing/decode figures are reproducible tooling evidence, not Android or
iOS frame-time claims.

## 22. RAM results

Semantic Vector, DigitalKhatt, QCF, and Raster runtime RAM are all **NOT
MEASURED — PHYSICAL DEVICE REQUIRED**. The raster calculation in section 16 is
**ESTIMATED**, not measured. No candidate may claim bounded runtime memory from
the three-page prepared-page LRU alone; vector pictures, registered fonts, and
image caches have distinct lifetimes.

## 23. Android status

**MEASURED:** Release AAB packaging succeeds for the identical baseline, raw
SVG corpus, compiled Semantic Vector corpus, and all 604 QCF fonts. Exact deltas
are recorded above. **PENDING VERIFICATION:** renderer initialization, visual
output, profile/release FPS, page swipes, background/resume, long-session RAM,
and device-specific failures. No usable physical Android device was available.

## 24. iOS status

**PENDING VERIFICATION:** iOS build, font registration, Canvas/SVG rendering,
memory, visual fidelity, and runtime performance were not tested because this
Windows environment has no iOS toolchain/device. iOS runtime validation is
pending for every candidate.

## 25. Licensing matrix

| Candidate/resource | Provider/owner | Commercial use / modification | App bundle and offline | Redistribution/hosting | Attribution/account | Confidence |
|---|---|---|---|---|---|---|
| Semantic SVG V1.01 | Mushaf Database; catalogued by QUL | repository license expressly permits lawful commercial use and derivatives, with Quran-integrity condition | permitted by repository license | permitted by repository license | preserve license/attribution; no account identified | medium-high legally, qualified review still required |
| DigitalKhatt font | DigitalKhatt contributors | OFL-1.1, subject to font terms | generally compatible | subject to OFL notices | attribution/notices | medium |
| DigitalKhatt JS/RN proofs | DigitalKhatt contributors | current repositories MIT | compatible if notices retained | MIT | notices | medium-high for code only |
| VisualMetaFont/LuaLaTeX tooling | DigitalKhatt contributors | AGPL-3.0 | embedding not approved for Maab | build-time/output boundary unresolved | AGPL obligations | **PENDING RIGHTS** |
| QUL layout/script/mapping | respective resource providers via QUL | resource-specific terms not established | not established | not established | contact Tarteel/QUL | **PENDING RIGHTS** |
| QCF V2 | Quran Foundation/resource licensors | governed by current [Developer Terms](https://api-docs.quran.com/legal/developer-terms/) | integrated caching/bundling requires active Developer Console account and accessible credit | standalone packs and Maab-hosted replacement API are not permitted by the reviewed terms | account and visible credit required | medium, conditional |
| Raster source | not selected | not established | not established | not established | unknown | **PENDING RIGHTS** |

## 26. Qualified-review status

**PENDING VERIFICATION:** No qualified Mushaf reviewer has approved any rendered
candidate. Even a future technical PASS must remain production-ineligible until
the exact frozen corpus/rendering is reviewed for text, glyphs, diacritics,
Waqf, markers, headings, Basmala, centering, justification, page composition,
and the hard-page corpus.

## 27. Final decision matrix

| Criterion | Semantic Vector | DigitalKhatt Precomputed | QCF V2 | Raster PageAsset |
|---|---|---|---|---|
| Exact edition | 1441H V1.01 frozen | pending frozen V2 layout | QCF V2; year metadata discrepancy | not selected |
| Fidelity | **NOT TESTABLE** | **NOT TESTABLE** | **NOT TESTABLE** | **NOT TESTABLE** |
| Word/Ayah semantics | source-level technical pass; canonical reconciliation pending | pending | pending provider map | separate overlay pending |
| Offline | architecture supports zero HTTP | architecture supports zero HTTP | conditional local bundle/cache | architecture supports zero HTTP |
| Files | 604 | **NOT MEASURED** | 604 | **NOT MEASURED** |
| Full raw corpus | 398,233,152 B | **NOT MEASURED** (font alone 521,832 B) | 207,809,084 B | **NOT MEASURED** |
| AAB delta | raw +80,401,011 B; compiled +75,286,758 B | **NOT MEASURED** | +136,170,326 B | **NOT MEASURED** |
| Installed delta | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** |
| RAM | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED**; 11.86 MB/page estimate at 1440 px |
| Cold/warm/swipe | host load only; device **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** |
| Android complexity | medium: custom painter, decoder, semantic map | high: generator plus custom painter | medium-high: page fonts and mappings | medium: decoder plus overlay |
| iOS complexity | credible but unvalidated | high/unvalidated | font-lifetime path unvalidated | credible but unvalidated |
| Licensing confidence | medium-high resource license; review pending | mixed; generated-output rights pending | conditional provider terms | source rights pending |
| Commercial safety | likely, not production-approved | **PENDING RIGHTS** | only under QF terms/account/credit | **PENDING RIGHTS** |
| Maintenance | medium | high | medium-high | medium plus duplicate semantic geometry |
| Multi-Mushaf extensibility | good with edition-specific compiled packs | potentially good | costly per 604-font edition | costly per image + overlay corpus |

## 28. Renderer winner

**Decision: pending.** Compiled Semantic Vector is the provisional technical
leader because it is the only candidate with a complete compiled corpus,
verified source-semantic interactions, exact AAB delta, clear renderer-neutral
shape, and comparatively strong resource rights. It is not selected: its
`+75,286,758`-byte delta materially misses the budget, and fidelity/device/iOS
evidence is incomplete. DigitalKhatt remains a realistic materially smaller
challenger but lacks the comparable artifact needed to distinguish it.

Exact completion status: **PHASE 4.5 RENDERER DECISION STILL PENDING**.

## 29. Confidence

**High** confidence in raw/ZIP/AAB size findings, corpus counts, source SVG
structure, compiler round trip, and source-level semantic mapping. **Medium**
confidence that compiled Semantic Vector is the present technical leader.
**Low** confidence in cross-candidate runtime ranking because no physical-device
profiling exists and DigitalKhatt/Raster lack full artifacts.

## 30. Known limitations

- **PENDING VERIFICATION:** source semantic identities versus Phase 1 canonical
  tokenization.
- **PENDING VERIFICATION:** authentic exact-edition image comparison and
  qualified Mushaf review.
- **NOT MEASURED:** Android/iOS first render, warm render, FPS, swipe, runtime
  memory, installed size, and long sessions.
- **NOT MEASURED:** full DigitalKhatt generated layout and full Raster corpus.
- The compiled experiment is gzip JSON, not a selected production binary
  format or implemented Flutter Canvas renderer.
- Dictionary figures are analytical upper/lower-bound inputs, not a shipped
  dictionary codec benchmark.

## 31. Production eligibility

All four candidates have `productionEligible = false`. No Quran renderer or
third-party research corpus is activated in production, and no runtime HTTP was
introduced. Production activation requires a frozen edition/resource ID,
version, checksum, complete provenance, technical fidelity pass, qualified
Mushaf review, and platform/device pass.

## 32. Remaining blockers

1. Generate and measure a complete DigitalKhatt precomputed placement corpus
   with canonical `WordKey`/`AyahKey` linkage.
2. Reconcile SVG source tokens with the canonical Phase 1 word corpus.
3. Render the 15-page exact-edition fidelity corpus and obtain an authentic
   reference plus qualified review.
4. Profile the strongest candidates on physical Android hardware in
   profile/release, including RAM and long sessions.
5. Validate the leading path on iOS.
6. Obtain written resource-specific rights clarification for any QUL/DigitalKhatt
   inputs used by the generated contender.

## 33. User action required

Provide access to a representative physical Android device and, later, an iOS
environment. Arrange a qualified Mushaf reviewer and approve contacting
Tarteel/QUL and DigitalKhatt maintainers for written resource/generated-output
rights. If QCF remains under consideration, create/maintain the required Quran
Foundation Developer Console account and accept the credit/terms obligations.

## 34. Exact Phase 5 recommendation

**Do not start Phase 5.** Run a narrowly scoped Phase 4.5 continuation that
produces the complete DigitalKhatt precomputed corpus and canonical semantic
map, compares its Quran-only AAB delta with compiled Semantic Vector, then runs
exact-edition fidelity and physical-device tests on the resulting top candidate
(and Semantic Vector if still competitive). Select the default renderer only
after that comparison; keep all normal reading local and retain the three-page
prepared-page cache unless measurements justify a change.

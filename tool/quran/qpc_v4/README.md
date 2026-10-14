# QPC V4 Tajweed research pack builder

This manual builder creates the deterministic 604-page QPC V4 Tajweed phone-native research pack. It renders the approved 1074 × 1944 layout in the browser, tightly crops each page, and converts the final raster to a transparent 8-bit indexed PNG with a deterministic 256-entry palette. Geometry remains in canonical phone-native coordinates with its crop origin. It does not modify or integrate with the Flutter application.

Run from `D:\projects\tasbeh`:

```powershell
node tool\quran\qpc_v4\build_qpc_v4_tajweed_pack.js --layout phone-native
```

Do not run it as part of a normal Flutter or Android build.

Requirements:

- Node.js 22 or newer; the builder uses only built-in Node modules.
- Google Chrome, Chromium, or Microsoft Edge. Standard Windows Chrome/Edge paths are detected; otherwise set `MAAB_QPC_CHROME` to an absolute executable path.
- Network access to GitHub only when the pinned source cache is absent or fails integrity validation. The builder downloads one archive for commit `f84ccb5688d5404748a0d38e6c53e09df4469ec9`, extracts and hashes the required files, and caches them under `quran_resources/.cache/qpc_v4_source/<commit>/`. Rendering and resumed runs are local after that fetch.
- Approximately 0.5–1 GB of free disk space and roughly 30–90 minutes, depending on browser startup, CPU, disk, and network performance.

Generation is resumable by default. Each existing PNG/gzip pair is fully validated before it is skipped. Missing or invalid pairs are rebuilt through validated temporary files and atomically moved into place. The final `manifest.json` is published only after all 604 pairs validate.

The full command is also the resume command:

```powershell
node tool\quran\qpc_v4\build_qpc_v4_tajweed_pack.js --layout phone-native
```

Optional debug scopes use the same rendering and validation path:

```powershell
node tool\quran\qpc_v4\build_qpc_v4_tajweed_pack.js --layout phone-native --page 6
node tool\quran\qpc_v4\build_qpc_v4_tajweed_pack.js --layout phone-native --pages 1,6,600
node tool\quran\qpc_v4\build_qpc_v4_tajweed_pack.js --layout phone-native --from 1 --to 20
```

It writes the authoritative generated pack under `quran_resources/qpc_v4_tajweed_pack/`: `manifest.json`, transparent indexed `pages/001.png` through `604.png`, `geometry/001.json.gz` through `604.json.gz`, the upstream notice under `licenses/`, and `README_RESEARCH_ONLY.md`.

Schema version 2 and render fingerprint `qpc-v4-tajweed-phone-native-1074x1944-generated-specials-v8-indexed-png256` prevent older RGBA or layout-incompatible outputs from being reused. Validation requires an 8-bit, 256-entry indexed palette with `tRNS` transparency, actual transparent pixels, visible content pixels, and visible pixels inside every Quran word region.

The result remains **RESEARCH ONLY** and **NOT FOR RELEASE**. Exact edition verification is unproven and redistribution approval is unapproved.

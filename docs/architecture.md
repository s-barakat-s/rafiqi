# Application architecture

The application uses a pragmatic feature-first structure. UI behavior and the
approved visual design are intentionally preserved; folders describe ownership,
not artificial abstraction layers.

## Top-level structure

```text
lib/
├── app/
│   ├── app.dart                 # MaterialApp composition
│   ├── bootstrap.dart           # Main-app startup
│   └── navigation/              # Five-destination shell
├── core/
│   ├── formatting/              # Arabic-Indic presentation formatting
│   ├── theme/                   # Palette, semantic colors, typography roles
│   └── time/                    # Local calendar-day identity
├── shared/widgets/              # Reusable app-wide presentation only
└── features/
    ├── adhkar/
    │   ├── data/repositories/   # Asset loading and progress persistence
    │   ├── domain/entities/     # Typed category, item and progress concepts
    │   └── presentation/        # Reader/list screens, controller and card deck
    ├── daily_wird/
    │   ├── data/repositories/   # Authoritative tasks and daily snapshots
    │   ├── domain/              # Daily entities and streak calculation
    │   └── presentation/        # Daily-task editing UI
    ├── home/                    # Today's state and time-appropriate hero
    ├── journey/                 # History/streak presentation
    ├── settings/                # App preferences and More screen
    └── tasbeeh/
        ├── application/         # Counter and overlay synchronization
        ├── data/repositories/   # Counter/settings persistence
        ├── domain/models/       # Counter and floating settings state
        └── presentation/        # Main counter, overlay and settings UI
```

The bundled `packages/flutter_overlay_window` implementation is an external
local package. Its example application is not part of this architecture and is
not a validation target.

## Data flow and sources of truth

### Adhkar

`AdhkarLocalRepository` parses bundled normalized JSON once and exposes typed
`AdhkarCategory`/`DhikrItem` values. Presentation has no raw JSON knowledge.
`WirdReaderController` owns mutable reader-session state and coordinates the
`AdhkarProgressRepository`. The screen owns lifecycle-only concerns such as the
animation controller and native tap feedback. `DhikrDeck`/card parts own visual
stacking and content only.

Reader completion is forwarded monotonically to `DailyWirdRepository`; replay
progress cannot revoke a daily completion already earned.

### Daily Wird, Home and Journey

`DailyWirdRepository` is the authoritative persisted source for base tasks,
custom tasks, completion sources and immutable date-keyed snapshots. Home reads
today's state. Journey reads the same history. `DailyStreakCalculator` derives
streak metrics from those snapshots and contains no UI or persistence code.

Local day keys are generated only by `LocalDay`, avoiding competing date formats
between Adhkar, daily history and Tasbeeh.

### Tasbeeh and floating overlay

`TasbeehController` is the main-isolate coordinator for counter state, storage,
overlay messages, permissions and start/stop behavior. `TasbeehCounterLogic`
contains pure counter transitions. `TasbeehRepository` persists both counter and
typed floating settings. The overlay continues to use the same persisted model
and messenger protocol, preserving page/overlay synchronization.

### App preferences

`AppPreferencesRepository` owns theme mode and Adhkar sound/haptic preferences.
`TasbeehApp` observes it and composes the UI; it does not know persistence keys.

## Presentation conventions

- Screens coordinate navigation, lifecycle and feature controllers.
- Complex feature widgets live beside their feature, never in `core`.
- `AppColors` semantic roles are preferred over raw colors.
- `AppFonts.display`, `AppFonts.reading` and `AppFonts.ui` encode the approved
  Aref Ruqaa, Amiri and IBM Plex Sans Arabic responsibilities.
- `ArabicNumerals` is used only for app-generated presentation strings; source
  religious text is never rewritten.
- Animation controllers and transient pressed/drag state remain in presentation.

## Adding code

- Add religious content parsing or persistence under `features/adhkar/data`.
- Add reader business transitions to `WirdReaderController`, and stack/card
  rendering under `features/adhkar/presentation/widgets/reader`.
- Add daily completion rules to `DailyWirdRepository` or a focused domain
  service, not Home or Journey widgets.
- Add counter transitions to `TasbeehCounterLogic`; add synchronization and
  persistence coordination to `TasbeehController`/`TasbeehRepository`.
- Add app-wide infrastructure to `core` only when more than one feature owns no
  natural home for it. Add app-wide reusable UI to `shared/widgets`.

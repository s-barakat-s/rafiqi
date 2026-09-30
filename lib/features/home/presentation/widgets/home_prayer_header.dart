part of '../home_screen.dart';

/// Seamless daily prayer header: app name / streak / dates → location →
/// large current time → prayer status → frosted 6-prayer strip.
///
/// Static parts live in [_HomePrayerHeader]; only the small [_LivePrayerTime]
/// subtree rebuilds every 30 s so the rest of Home is untouched by the timer.
class _HomePrayerHeader extends StatelessWidget {
  const _HomePrayerHeader({
    required this.streak,
    required this.hijriDate,
    required this.gregorianDate,
    required this.onDateTap,
  });

  final int streak;
  final String hijriDate;
  final String gregorianDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tight header row: wordmark right, streak centered on the device,
        // dates left. Top-anchored so no invisible-toolbar air sits above.
        SizedBox(
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // App wordmark — right edge.
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مَآب',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Streak pill — geometrically centered regardless of side widths.
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: .55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${ArabicNumerals.integer(streak)} أيام متتالية',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Dates — left edge, tappable to the Hijri calendar.
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hijriDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          gregorianDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceSoft.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.outline.withValues(alpha: .45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  PrayerSchedule.locationLabel,
                  style: text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // The only live subtree — isolated so its timer does not rebuild
        // the static header above.
        const _LivePrayerTime(),
      ],
    );
  }
}

/// Clock + prayer status + strip, ticking every 30 s in its own subtree.
class _LivePrayerTime extends StatefulWidget {
  const _LivePrayerTime();

  @override
  State<_LivePrayerTime> createState() => _LivePrayerTimeState();
}

class _LivePrayerTimeState extends State<_LivePrayerTime> {
  static const _tickInterval = Duration(seconds: 30);

  Timer? _ticker;
  PrayerScheduleSnapshot _snapshot = PrayerSchedule.snapshot(DateTime.now());

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tickInterval, (_) {
      if (mounted) {
        setState(() => _snapshot = PrayerSchedule.snapshot(DateTime.now()));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _formatClock(_snapshotNow()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 46,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _statusText(_snapshot.status),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _PrayerTimesStrip(snapshot: _snapshot),
      ],
    );
  }

  DateTime _snapshotNow() => DateTime.now();

  String _formatClock(DateTime now) {
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final hh = hour12.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return ArabicNumerals.digits('$hh:$mm');
  }

  String _statusText(PrayerStatus status) => switch (status.kind) {
        PrayerStatusKind.ongoing => 'حان الآن وقت ${status.prayer.name}',
        PrayerStatusKind.upcoming =>
          'باقي على ${status.prayer.name} ${PrayerSchedule.formatDuration(status.duration)}',
        PrayerStatusKind.passed =>
          'مرّ على ${status.prayer.name} ${PrayerSchedule.formatDuration(status.duration)}',
      };
}

class _PrayerTimesStrip extends StatelessWidget {
  const _PrayerTimesStrip({required this.snapshot});

  final PrayerScheduleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: snapshot.items
            .map(
              (item) => Expanded(
                child: _PrayerStripItem(
                  item: item,
                  active: item.type == snapshot.highlightedType,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PrayerStripItem extends StatelessWidget {
  const _PrayerStripItem({required this.item, required this.active});

  final PrayerTimeItem item;
  final bool active;

  static const _icons = {
    PrayerItemType.fajr: Icons.bedtime_outlined,
    PrayerItemType.sunrise: Icons.wb_twilight,
    PrayerItemType.dhuhr: Icons.wb_sunny_outlined,
    PrayerItemType.asr: Icons.wb_cloudy_outlined,
    PrayerItemType.maghrib: Icons.brightness_2_outlined,
    PrayerItemType.isha: Icons.dark_mode_outlined,
  };

  String _timeLabel() {
    final hour12 = item.time.hour % 12 == 0 ? 12 : item.time.hour % 12;
    final hh = hour12.toString();
    final mm = item.time.minute.toString().padLeft(2, '0');
    return ArabicNumerals.digits('$hh:$mm');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final textStyle = text.labelSmall?.copyWith(
      color: active ? colors.primary : colors.textSecondary,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    );
    final timeStyle = text.labelMedium?.copyWith(
      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
      color: active ? colors.primary : colors.textPrimary,
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _icons[item.type],
          size: 19,
          color: active ? colors.primary : colors.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
        const SizedBox(height: 2),
        Text(
          _timeLabel(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: timeStyle,
        ),
      ],
    );

    // One shared column height so active/inactive rows stay aligned.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer.withValues(alpha: .9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: active
            ? Border.all(color: colors.primary.withValues(alpha: .35))
            : Border.all(color: Colors.transparent),
      ),
      child: column,
    );
  }
}

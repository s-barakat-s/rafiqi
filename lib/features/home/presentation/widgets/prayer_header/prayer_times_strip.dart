import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_time_item.dart';

class PrayerTimesStrip extends StatelessWidget {
  const PrayerTimesStrip({required this.items, super.key});

  final List<PrayerTimeData> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: PrayerHeaderStyles.surface(context),
        borderRadius: BorderRadius.circular(PrayerHeaderStyles.stripRadius),
        border: Border.all(color: colors.outline.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(child: PrayerTimeItemView(item: items[index])),
            if (index != items.length - 1)
              Container(
                width: 1,
                height: 42,
                color: colors.outline.withValues(alpha: .18),
              ),
          ],
        ],
      ),
    );
  }
}

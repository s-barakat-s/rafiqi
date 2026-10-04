import 'package:flutter/material.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/weekday_assets.dart';

class PrayerHeaderTopBar extends StatelessWidget {
  const PrayerHeaderTopBar({
    required this.data,
    required this.onSettingsTap,
    super.key,
  });

  final PrayerHeaderData data;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final weekdayAsset = WeekdayAssets.pathFor(data.weekday);
    return SizedBox(
      height: 64,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              button: true,
              label: 'الإعدادات',
              child: IconButton(
                onPressed: onSettingsTap,
                tooltip: 'الإعدادات',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                padding: const EdgeInsets.all(12),
                icon: Icon(
                  Icons.settings_rounded,
                  size: 24,
                  color: PrayerHeaderStyles.primary(context),
                ),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: PrayerHeaderStyles.buildMixedTextSpans(
                          text: data.hijriDate,
                          arabicStyle: PrayerHeaderStyles.hijriDate(context),
                          numberStyle: PrayerHeaderStyles.hijriNumber(context),
                        ),
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 112,
                    height: 64,
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: OverflowBox(
                          minWidth: 128,
                          maxWidth: 128,
                          minHeight: 128,
                          maxHeight: 128,
                          child: Image.asset(
                            weekdayAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

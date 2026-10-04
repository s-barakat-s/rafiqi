import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class PrayerQuickActions extends StatelessWidget {
  const PrayerQuickActions({
    required this.data,
    required this.onPrayerTimesTap,
    required this.onQiblaTap,
    super.key,
  });

  final PrayerHeaderData data;
  final VoidCallback onPrayerTimesTap;
  final VoidCallback onQiblaTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PrayerActionPill(
            label: data.prayerTimesActionLabel,
            onTap: onPrayerTimesTap,
            icon: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PrayerHeaderStyles.primary(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 10,
                color: context.appColors.onPrimary,
              ),
            ),
          ),
          _PrayerActionPill(
            label: data.qiblaActionLabel,
            onTap: onQiblaTap,
            icon: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PrayerHeaderStyles.activeSurface(context),
                shape: BoxShape.circle,
              ),
              child: RafiqiSvgIcon(
                RafiqiIcons.qibla,
                size: 13,
                color: PrayerHeaderStyles.primary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerActionPill extends StatelessWidget {
  const _PrayerActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PrayerHeaderStyles.actionRadius),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: PrayerHeaderStyles.surface(context),
                borderRadius: BorderRadius.circular(
                  PrayerHeaderStyles.actionRadius,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PrayerHeaderStyles.action(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

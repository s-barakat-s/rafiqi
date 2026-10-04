import 'package:flutter/material.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';

class CurrentPrayerSummary extends StatelessWidget {
  const CurrentPrayerSummary({required this.data, super.key});

  final PrayerHeaderData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label:
          '${data.nowLabel}، ${data.currentPrayerName}، ${data.currentPrayerTime} ${data.period}',
      child: ExcludeSemantics(
        child: Column(
          // مهم:
          // نخلي END = اليمين بصريًا
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                data.nowLabel,
                textAlign: TextAlign.right,
                style: PrayerHeaderStyles.nowLabel(context),
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                data.currentPrayerName,
                textAlign: TextAlign.right,
                style: PrayerHeaderStyles.prayerName(context),
              ),
            ),

            const SizedBox(height: 2),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.currentPrayerTime,
                    style: PrayerHeaderStyles.currentTime(context),
                  ),

                  const SizedBox(width: 5),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      data.period,
                      style: PrayerHeaderStyles.period(context),
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

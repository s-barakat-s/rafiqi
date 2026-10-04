import 'package:flutter/material.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';

class PrayerTimeItemView extends StatelessWidget {
  const PrayerTimeItemView({required this.item, super.key});

  final PrayerTimeData item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: item.isCurrent,
      label: '${item.name}، ${item.time}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.fromLTRB(3, 8, 3, 5),
          decoration: BoxDecoration(
            color: item.isCurrent
                ? PrayerHeaderStyles.activeSurface(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              PrayerHeaderStyles.activeItemRadius,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PrayerHeaderStyles.prayerLabel(
                  context,
                  active: item.isCurrent,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  item.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PrayerHeaderStyles.prayerTime(
                    context,
                    active: item.isCurrent,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 4,
                height: 4,
                child: item.isCurrent
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: PrayerHeaderStyles.primary(
                            context,
                          ).withValues(alpha: .5),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

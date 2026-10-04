import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/current_prayer_summary.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_styles.dart';

class PrayerHeaderSection extends StatelessWidget {
  const PrayerHeaderSection({
    required this.data,
    required this.onSettingsTap,
    required this.onPrayerTimesTap,
    required this.onQiblaTap,
    super.key,
  });

  final PrayerHeaderData data;
  final VoidCallback onSettingsTap;
  final VoidCallback onPrayerTimesTap;
  final VoidCallback onQiblaTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isRafiqiDark = PrayerHeaderStyles.isRafiqiDark(context);

        double responsive(double factor, double min, double max) {
          return (width * factor).clamp(min, max).toDouble();
        }

        final horizontalPadding = responsive(0.035, 12, 18);

        final weekdayWidth = responsive(0.30, 65, 80);
        final mosqueWidth = responsive(0.50, 310, 350);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =================================================
            // الجزء العلوي فقط عليه Padding
            // =================================================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isRafiqiDark)
                    Positioned(
                      key: const ValueKey('rafiqi-mosque-glow'),
                      left: -responsive(0.02, 50, 80) - (mosqueWidth * 0.05),
                      bottom: -responsive(0.02, 50, 70) - (mosqueWidth * 0.01),

                      child: _MosqueGlow(mosqueWidth: mosqueWidth * 0.80),
                    ),

                  // =============================================
                  // المسجد - ناحية الشمال
                  // =============================================
                  Positioned(
                    left: isRafiqiDark
                        ? -responsive(0.02, 50, 80) // Dark only
                        : -responsive(0.04, 80, 100), // Light unchanged

                    bottom: isRafiqiDark
                        ? -responsive(0.02, 50, 70) // Dark only
                        : -responsive(0.04, 5, 30), // Light unchanged

                    child: IgnorePointer(
                      child: Opacity(
                        opacity: isRafiqiDark ? 0.80 : 0.45,
                        child: isRafiqiDark
                            ? ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.72, 1.0],
                                  ).createShader(bounds);
                                },
                                child: Image.asset(
                                  'assets/image/home/Masged dark.png',
                                  width: mosqueWidth,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                'assets/image/home/Masged.png',
                                width: mosqueWidth,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // =========================================
                      // اليوم + التاريخ + الإعدادات
                      // =========================================
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      _weekdayAsset(data.weekday),
                                      width: weekdayWidth,
                                      fit: BoxFit.contain,
                                      color: isRafiqiDark
                                          ? PrayerHeaderStyles.primary(context)
                                          : null,
                                      colorBlendMode: isRafiqiDark
                                          ? BlendMode.srcIn
                                          : null,
                                    ),

                                    SizedBox(width: responsive(0.025, 10, 16)),

                                    Flexible(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          bottom: responsive(0.01, 3, 6),
                                        ),
                                        child: _HijriDateDisplay(
                                          hijriDate: data.hijriDate,
                                          hijriMonth: data.hijriMonth,
                                          fontSize: responsive(0.038, 14, 17),
                                          color: PrayerHeaderStyles.primary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: responsive(0.015, 5, 8)),

                            IconButton(
                              onPressed: onSettingsTap,
                              tooltip: 'الإعدادات',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(
                                width: responsive(0.095, 38, 44),
                                height: responsive(0.095, 38, 44),
                              ),
                              icon: Icon(
                                Icons.settings_rounded,
                                color: PrayerHeaderStyles.actionPrimary(
                                  context,
                                ),
                                size: responsive(0.06, 24, 29),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =========================================
                      // المسافة قبل الصلاة الحالية
                      // =========================================
                      SizedBox(height: responsive(0.012, 4, 7)),
                      // =========================================
                      // الآن - العصر - PM 3:31
                      // يمين بشكل صريح
                      // =========================================
                      Align(
                        alignment: Alignment.centerRight,
                        child: CurrentPrayerSummary(data: data),
                      ),

                      // =========================================
                      // مسافة قبل الأزرار
                      // =========================================
                      SizedBox(height: responsive(0.010, 4, 6)),
                      // =========================================
                      // المزيد من المواقيت + القبلة
                      // يمين بشكل صريح
                      // =========================================
                      Align(
                        alignment: Alignment.centerRight,
                        child: _PrayerActions(
                          prayerTimesLabel: data.prayerTimesActionLabel,
                          qiblaLabel: data.qiblaActionLabel,
                          onPrayerTimesTap: onPrayerTimesTap,
                          onQiblaTap: onQiblaTap,
                          availableWidth: width,
                        ),
                      ),

                      // =========================================
                      // مساحة لظهور المسجد
                      // =========================================
                      SizedBox(height: responsive(0.035, 12, 18)),
                    ],
                  ),
                ],
              ),
            ),

            // المسافة بين الجزء العلوي وكارت المواقيت
            SizedBox(height: responsive(0.018, 7, 10)),

            // =================================================
            // كارت مواقيت الصلاة
            // خارج الـ Padding عشان ياخد نفس عرض الكارت اللي تحته
            // =================================================
            _PrayerTimesStrip(
              prayerTimes: data.prayerTimes,
              availableWidth: width,
            ),
          ],
        );
      },
    );
  }

  String _weekdayAsset(AppWeekday weekday) {
    return switch (weekday) {
      AppWeekday.sunday => 'assets/image/home/days/الاحد.png',
      AppWeekday.monday => 'assets/image/home/days/الاثنين.png',
      AppWeekday.tuesday => 'assets/image/home/days/الثلاثاء.png',
      AppWeekday.wednesday => 'assets/image/home/days/الاربعاء.png',
      AppWeekday.thursday => 'assets/image/home/days/الخميس.png',
      AppWeekday.friday => 'assets/image/home/days/الجمعة.png',
      AppWeekday.saturday => 'assets/image/home/days/السبت.png',
    };
  }
}

class _MosqueGlow extends StatelessWidget {
  const _MosqueGlow({required this.mosqueWidth});

  final double mosqueWidth;

  @override
  Widget build(BuildContext context) {
    final glowWidth = mosqueWidth * 1.24;
    final glowHeight = mosqueWidth * 0.78;

    return RepaintBoundary(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 38, sigmaY: 34),
            child: SizedBox(
              width: glowWidth,
              height: glowHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.08, 0.22),
                          radius: 0.82,
                          colors: [
                            Color(0x47DDE8C9),
                            Color(0x2CC8D9BA),
                            Color(0x00C8D9BA),
                          ],
                          stops: [0, 0.48, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: glowWidth * 0.08,
                    right: glowWidth * 0.20,
                    bottom: glowHeight * 0.05,
                    height: glowHeight * 0.46,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.18, 0.35),
                          radius: 0.72,
                          colors: [
                            Color(0x30AFC8AA),
                            Color(0x18DDE8C9),
                            Color(0x00DDE8C9),
                          ],
                          stops: [0, 0.52, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: glowWidth * 0.05,
                    right: glowWidth * 0.05,
                    bottom: 0,
                    height: glowHeight * 0.30,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0x24DDE8C9),
                            Color(0x10AFC8AA),
                            Color(0x00AFC8AA),
                          ],
                          stops: [0, 0.55, 1],
                        ),
                      ),
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

// =============================================================
// الأزرار أسفل الوقت
// =============================================================

class _PrayerActions extends StatelessWidget {
  const _PrayerActions({
    required this.prayerTimesLabel,
    required this.qiblaLabel,
    required this.onPrayerTimesTap,
    required this.onQiblaTap,
    required this.availableWidth,
  });

  final String prayerTimesLabel;
  final String qiblaLabel;

  final VoidCallback onPrayerTimesTap;
  final VoidCallback onQiblaTap;

  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    double responsive(double factor, double min, double max) {
      return (availableWidth * factor).clamp(min, max).toDouble();
    }

    return Column(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PrayerActionButton(
          label: prayerTimesLabel,
          onTap: onPrayerTimesTap,
          icon: Icons.chevron_left_rounded,
          filledIcon: true,
          availableWidth: availableWidth,
        ),

        SizedBox(height: responsive(0.012, 5, 7)),

        _PrayerActionButton(
          label: qiblaLabel,
          onTap: onQiblaTap,
          icon: Icons.explore_outlined,
          availableWidth: availableWidth,
        ),
      ],
    );
  }
}

// =============================================================
// زر صغير Pill
// =============================================================

class _PrayerActionButton extends StatelessWidget {
  const _PrayerActionButton({
    required this.label,
    required this.onTap,
    required this.icon,
    required this.availableWidth,
    this.filledIcon = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double availableWidth;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    double responsive(double factor, double min, double max) {
      return (availableWidth * factor).clamp(min, max).toDouble();
    }

    return Material(
      color: PrayerHeaderStyles.actionSurface(context),
      shape: StadiumBorder(
        side: BorderSide(color: PrayerHeaderStyles.actionBorder(context)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: responsive(0.025, 9, 12),
            end: responsive(0.018, 7, 10),
            top: responsive(0.014, 5, 7),
            bottom: responsive(0.014, 5, 7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PrayerHeaderStyles.action(
                    context,
                  ).copyWith(fontSize: responsive(0.028, 11, 13)),
                ),
              ),

              SizedBox(width: responsive(0.015, 5, 8)),

              Container(
                width: responsive(0.047, 18, 22),
                height: responsive(0.047, 18, 22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filledIcon
                      ? PrayerHeaderStyles.filledActionIconSurface(context)
                      : PrayerHeaderStyles.actionIconSurface(context),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: responsive(0.03, 12, 15),
                  color: filledIcon
                      ? PrayerHeaderStyles.actionIconForeground(context)
                      : PrayerHeaderStyles.actionPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// شريط مواقيت الصلاة
// =============================================================

class _PrayerTimesStrip extends StatelessWidget {
  const _PrayerTimesStrip({
    required this.prayerTimes,
    required this.availableWidth,
  });

  final List<PrayerTimeData> prayerTimes;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    double responsive(double factor, double min, double max) {
      return (availableWidth * factor).clamp(min, max).toDouble();
    }

    final stripHeight = responsive(0.19, 76, 90);
    final horizontalPadding = responsive(0.016, 6, 9);
    final verticalPadding = responsive(0.012, 5, 7);

    final nameSlotHeight = responsive(0.045, 17, 20);

    return Container(
      width: double.infinity,
      height: stripHeight,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: PrayerHeaderStyles.stripSurface(context),
        borderRadius: BorderRadius.circular(responsive(0.06, 22, 30)),
        border: Border.all(color: PrayerHeaderStyles.stripBorder(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int index = 0; index < prayerTimes.length; index++) ...[
            Expanded(
              child: _PrayerTimeItem(
                data: prayerTimes[index],
                availableWidth: availableWidth,
                nameSlotHeight: nameSlotHeight,
              ),
            ),

            if (index != prayerTimes.length - 1)
              Container(
                width: 1,
                height: stripHeight * 0.48,
                color: PrayerHeaderStyles.separator(context),
              ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// الصلاة الواحدة داخل الشريط
// =============================================================

class _PrayerTimeItem extends StatelessWidget {
  const _PrayerTimeItem({
    required this.data,
    required this.availableWidth,
    required this.nameSlotHeight,
  });

  final PrayerTimeData data;
  final double availableWidth;
  final double nameSlotHeight;

  @override
  Widget build(BuildContext context) {
    double responsive(double factor, double min, double max) {
      return (availableWidth * factor).clamp(min, max).toDouble();
    }

    return Container(
      height: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: responsive(0.006, 2, 4)),
      padding: EdgeInsets.symmetric(
        horizontal: responsive(0.005, 2, 4),
        vertical: responsive(0.01, 4, 6),
      ),
      decoration: BoxDecoration(
        color: data.isCurrent
            ? PrayerHeaderStyles.activePrayerSurface(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(responsive(0.04, 15, 20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: nameSlotHeight,
            child: Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: PrayerHeaderStyles.prayerLabel(
                context,
                active: data.isCurrent,
              ).copyWith(fontSize: responsive(0.029, 11, 13)),
            ),
          ),

          SizedBox(height: responsive(0.008, 3, 4)),

          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              data.time,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: PrayerHeaderStyles.prayerTime(
                context,
                active: data.isCurrent,
              ).copyWith(fontSize: responsive(0.03, 12, 14)),
            ),
          ),

          SizedBox(height: responsive(0.008, 3, 4)),

          SizedBox(
            width: responsive(0.012, 4, 5),
            height: responsive(0.012, 4, 5),
            child: data.isCurrent
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: PrayerHeaderStyles.activeDot(context),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// عرض التاريخ الهجري
// =============================================================

class _HijriDateDisplay extends StatelessWidget {
  const _HijriDateDisplay({
    required this.hijriDate,
    required this.fontSize,
    required this.color,
    this.hijriMonth,
  });

  final String hijriDate;
  final String? hijriMonth;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final arabicStyle = PrayerHeaderStyles.hijriDate(
      context,
    ).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);
    final numberStyle = PrayerHeaderStyles.hijriNumber(
      context,
    ).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: PrayerHeaderStyles.buildMixedTextSpans(
            text: hijriDate,
            arabicStyle: arabicStyle,
            numberStyle: numberStyle,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// =============================================================
// ألوان خاصة بالجزء فقط
// =============================================================

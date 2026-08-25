import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/hijri_date.dart';

/// Interactive monthly Hijri calendar screen with Gregorian date correspondence.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late int _viewYear;
  late int _viewMonth;
  late HijriDate _selectedDate;
  late HijriDate _todayHijri;

  @override
  void initState() {
    super.initState();
    _initDates();
  }

  void _initDates() {
    _todayHijri = HijriDate.now();
    _viewYear = _todayHijri.year;
    _viewMonth = _todayHijri.month;
    _selectedDate = _todayHijri;
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewYear--;
        _viewMonth = 12;
      } else {
        _viewMonth--;
      }
      _syncSelectionWithMonth();
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewYear++;
        _viewMonth = 1;
      } else {
        _viewMonth++;
      }
      _syncSelectionWithMonth();
    });
  }

  void _goToToday() {
    setState(() {
      _todayHijri = HijriDate.now();
      _viewYear = _todayHijri.year;
      _viewMonth = _todayHijri.month;
      _selectedDate = _todayHijri;
    });
  }

  void _syncSelectionWithMonth() {
    if (_selectedDate.year == _viewYear && _selectedDate.month == _viewMonth) {
      return;
    }
    if (_todayHijri.year == _viewYear && _todayHijri.month == _viewMonth) {
      _selectedDate = _todayHijri;
    } else {
      _selectedDate = HijriDate(year: _viewYear, month: _viewMonth, day: 1);
    }
  }

  void _onDaySelected(int day) {
    setState(() {
      _selectedDate = HijriDate(year: _viewYear, month: _viewMonth, day: day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isCurrentMonthToday =
        _viewYear == _todayHijri.year && _viewMonth == _todayHijri.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم الهجري'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthHeader(
                context,
                colors,
                textTheme,
                isCurrentMonthToday,
              ),
              const SizedBox(height: 16),
              _buildCalendarCard(context, colors),
              const SizedBox(height: 24),
              _buildSelectedDatePanel(context, colors, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    AppColors colors,
    TextTheme textTheme,
    bool isCurrentMonthToday,
  ) {
    final currentHijriMonth = HijriDate(
      year: _viewYear,
      month: _viewMonth,
      day: 1,
    );

    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          tooltip: 'الشهر السابق',
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                currentHijriMonth.formatMonthYear(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!isCurrentMonthToday)
          TextButton(
            onPressed: _goToToday,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'اليوم',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        IconButton(
          onPressed: _goToNextMonth,
          tooltip: 'الشهر التالي',
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(BuildContext context, AppColors colors) {
    const weekdays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    final firstDayGregorian = HijriDate(
      year: _viewYear,
      month: _viewMonth,
      day: 1,
    ).toGregorian();
    final offset = (firstDayGregorian.weekday + 1) % 7;
    final daysInMonth = HijriDate.getDaysInMonth(_viewYear, _viewMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              final day = index - offset + 1;
              final isToday =
                  _viewYear == _todayHijri.year &&
                  _viewMonth == _todayHijri.month &&
                  day == _todayHijri.day;
              final isSelected =
                  _viewYear == _selectedDate.year &&
                  _viewMonth == _selectedDate.month &&
                  day == _selectedDate.day;

              return _HijriDayCell(
                day: day,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () => _onDaySelected(day),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDatePanel(
    BuildContext context,
    AppColors colors,
    TextTheme textTheme,
  ) {
    final gregorianDate = _selectedDate.toGregorian();
    final isSelectedToday = _selectedDate == _todayHijri;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate.formatFull(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isSelectedToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.emerald.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.emerald.withValues(alpha: .5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: colors.emerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'اليوم',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.emerald,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 24,
                height: 1,
                color: colors.outline.withValues(alpha: .8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'يوافق',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: colors.outline.withValues(alpha: .8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            HijriDate.formatGregorianFull(
              gregorianDate,
              includeWeekday: true,
              includeSuffix: true,
            ),
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HijriDayCell extends StatelessWidget {
  const _HijriDayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final backgroundColor = isSelected
        ? colors.primary
        : isToday
        ? colors.selected.withValues(alpha: .35)
        : Colors.transparent;

    final textColor = isSelected ? AppPalette.dustGrey : colors.textPrimary;

    final border = isToday && !isSelected
        ? Border.all(color: colors.progress, width: 1.5)
        : null;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: border,
        ),
        child: Text(
          ArabicNumerals.integer(day, groupThousands: false),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: isSelected || isToday
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

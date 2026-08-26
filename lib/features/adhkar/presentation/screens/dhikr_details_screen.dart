import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';

class DhikrDetailsScreen extends StatelessWidget {
  const DhikrDetailsScreen({
    required this.item,
    super.key,
  });

  final DhikrItem item;

  @override
  Widget build(BuildContext context) {
    final sections = _sections(item);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'رجوع',
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'الذكر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 40),
              sliver: SliverList.list(
                children: [
                  Material(
                    color: context.appColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            item.text,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontFamily: AppFonts.reading,
                              fontSize: 27,
                              height: 1.95,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _countText(item),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.appColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Divider(color: context.appColors.outlineStrong),
                  for (final section in sections)
                    _DhikrDetailsSection(title: section.$1, value: section.$2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrDetailsSection extends StatelessWidget {
  const _DhikrDetailsSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.appColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.75),
        ),
        const SizedBox(height: 18),
        Divider(color: context.appColors.divider.withValues(alpha: .65)),
      ],
    ),
  );
}

List<(String, String)> _sections(DhikrItem item) => [
  if (_present(item.instruction)) ('طريقة الذكر', item.instruction!.trim()),
  if (_present(_sourceText(item))) ('المصدر والتخريج', _sourceText(item)!),
  if (_present(_virtueText(item))) ('الفضل', _virtueText(item)!),
  if (_present(item.hadithText)) ('نص الحديث والدليل', item.hadithText!.trim()),
  if (_present(item.explanation)) ('الشرح', item.explanation!.trim()),
  if (_present(_quranText(item))) ('الموضع من القرآن', _quranText(item)!),
  if (item.appliesTo.isNotEmpty)
    ('يُقال بعد', item.appliesTo.map(_prayerName).join('، ')),
];

String _countText(DhikrItem item) =>
    item.countDescription?.trim().isNotEmpty == true
    ? item.countDescription!.trim()
    : item.repeatCount == 1
    ? 'يُقال مرة'
    : 'يُقال ${ArabicNumerals.integer(item.repeatCount)} مرات';

String? _sourceText(DhikrItem item) {
  final short = item.source?.trim();
  final full = item.fullSource?.trim();
  if (_present(full)) {
    if (_present(short) && !full!.contains(short!)) return '$short\n\n$full';
    return full;
  }
  return _present(short) ? short : null;
}

String? _quranText(DhikrItem item) {
  if (item.isQuran != true || !_present(item.surah)) return null;
  final from = item.ayahFrom;
  final to = item.ayahTo;
  if (from == null) return 'سورة ${item.surah}';
  final range = to != null && to != from
      ? '${ArabicNumerals.integer(from)}–${ArabicNumerals.integer(to)}'
      : ArabicNumerals.integer(from);
  return 'سورة ${item.surah}: $range';
}

String _prayerName(String value) => switch (value) {
  'fajr' => 'صلاة الفجر',
  'dhuhr' => 'صلاة الظهر',
  'asr' => 'صلاة العصر',
  'maghrib' => 'صلاة المغرب',
  'isha' => 'صلاة العشاء',
  _ => value,
};

bool _present(String? value) => value != null && value.trim().isNotEmpty;

String? _virtueText(DhikrItem item) {
  if (_present(item.virtue)) return item.virtue!.trim();
  return _present(item.virtuePreview) ? item.virtuePreview!.trim() : null;
}

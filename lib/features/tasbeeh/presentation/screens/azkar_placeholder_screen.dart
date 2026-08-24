import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/adhkar_data.dart';
import 'package:tasbeh/features/adhkar/presentation/wird_reader_screen.dart';

class AzkarPlaceholderScreen extends StatelessWidget {
  const AzkarPlaceholderScreen({
    required this.vibrationEnabled,
    required this.soundEnabled,
    super.key,
  });

  final bool vibrationEnabled;
  final bool soundEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<AdhkarCategory>>(
        future: AdhkarLocalRepository.loadCategories(),
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
            children: [
              const Text(
                'الأذكار',
                style: TextStyle(
                  fontFamily: 'ArefRuqaa',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اختر وردك، واجعل للذكر نصيبًا من يومك',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.secondaryText),
              ),
              const SizedBox(height: 26),
              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('تعذر تحميل بيانات الأذكار المحلية'),
                  ),
                )
              else if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...snapshot.data!.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _CategoryCard(
                      category: category,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WirdReaderScreen(
                            category: category,
                            vibrationEnabled: vibrationEnabled,
                            soundEnabled: soundEnabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final AdhkarCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: colors.outline.withValues(alpha: .55)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.emerald.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(category.icon, color: colors.secondary, size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontFamily: 'ArefRuqaa',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.selected.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '${ArabicNumerals.integer(category.items.length)} أذكار',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

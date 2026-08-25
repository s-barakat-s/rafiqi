import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_category_grid.dart';

class AdhkarCategoriesScreen extends StatelessWidget {
  const AdhkarCategoriesScreen({
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الأذكار',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر وردك، واجعل للذكر نصيبًا من يومك',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.hasError
                    ? const Center(
                        child: Text('تعذر تحميل بيانات الأذكار المحلية'),
                      )
                    : !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : AdhkarCategoryGrid(
                        categories: snapshot.data!,
                        vibrationEnabled: vibrationEnabled,
                        soundEnabled: soundEnabled,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

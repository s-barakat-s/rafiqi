import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/custom_adhkar_collections_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/adhkar_collection_customization_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/custom_adhkar_collection_editor_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_category_grid.dart';

class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({
    required this.vibrationEnabled,
    required this.soundEnabled,
    super.key,
  });

  final bool vibrationEnabled;
  final bool soundEnabled;

  @override
  State<AdhkarCategoriesScreen> createState() =>
      _AdhkarCategoriesScreenState();
}

class _AdhkarCategoriesScreenState extends State<AdhkarCategoriesScreen> {
  late Future<List<AdhkarCategory>> _categories =
      AdhkarLocalRepository.loadCategories();

  Future<void> _refreshCategories() async {
    final categories = await AdhkarLocalRepository.loadCategories();
    if (!mounted) return;
    setState(() {
      _categories = Future.value(categories);
    });
  }

  Future<void> _customize(AdhkarCategory category) async {
    if (category.kind == AdhkarCategoryKind.custom) {
      final collections =
          await CustomAdhkarCollectionsRepository.instance.load();
      final collection = collections.firstWhere(
        (item) => item.id == category.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              CustomAdhkarCollectionEditorScreen(collection: collection),
        ),
      );
      await _refreshCategories();
      return;
    }
    final canonical = await AdhkarLocalRepository.loadCanonicalCategory(
      category.id,
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            AdhkarCollectionCustomizationScreen(category: canonical),
      ),
    );
    await _refreshCategories();
  }

  Future<void> _createCustom() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CustomAdhkarCollectionEditorScreen(),
      ),
    );
    await _refreshCategories();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<AdhkarCategory>>(
        future: _categories,
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
                        vibrationEnabled: widget.vibrationEnabled,
                        soundEnabled: widget.soundEnabled,
                        onCustomize: _customize,
                        onCreateCustom: _createCustom,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

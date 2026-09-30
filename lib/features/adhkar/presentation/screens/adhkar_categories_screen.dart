import 'package:flutter/material.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/custom_adhkar_collections_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/adhkar_collection_customization_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/custom_adhkar_collection_editor_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_category_grid.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_hub_hero.dart';

class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({
    required this.vibrationEnabled,
    required this.soundEnabled,
    super.key,
  });

  final bool vibrationEnabled;
  final bool soundEnabled;

  @override
  State<AdhkarCategoriesScreen> createState() => _AdhkarCategoriesScreenState();
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

  Future<void> _openCurrentCollection(AdhkarCategory category) async {
    final resolved = await AdhkarLocalRepository.loadResolvedCategory(
      category.id,
    );
    if (!mounted || resolved == null) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            WirdReaderScreen(
              category: resolved,
              vibrationEnabled: widget.vibrationEnabled,
              soundEnabled: widget.soundEnabled,
              morphTransition: MorphTransitionSpec(controller: animation),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade the opaque Reader surface over the Hub below the Hero overlay.
          // Reversing this same interval reveals the Hub before the Hero lands.
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: const Interval(0, .35))),
            child: child,
          );
        },
      ),
    );
    if (mounted) _refreshCategories();
  }

  Future<void> _customize(AdhkarCategory category) async {
    if (category.kind == AdhkarCategoryKind.custom) {
      final collections = await CustomAdhkarCollectionsRepository.instance
          .load();
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
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<AdhkarCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image-led hero for the current morning/evening wird.
              AdhkarHubHero(onOpen: _openCurrentCollection),
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

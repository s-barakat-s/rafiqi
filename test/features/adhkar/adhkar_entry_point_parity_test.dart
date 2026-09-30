import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_collection_overrides.dart';

/// Phase 0 regression: every Adhkar reading entry point must resolve the same
/// customized collection definition.
///
/// Every reading entry point resolves by id through
/// [AdhkarLocalRepository.loadResolvedCategory]. Canonical loading remains for
/// customization/reset only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'loadCategories resolves the customized morning collection once',
    () async {
      // Customize: hide one item and change a repeat count.
      final canonical = await AdhkarLocalRepository.loadCanonicalCategories();
      final morning = canonical.firstWhere((c) => c.id == 'morning');
      final firstItem = morning.items.first;

      await AdhkarCollectionOverridesRepository.instance.save(
        'morning',
        AdhkarCollectionOverrides(
          hiddenDhikrIds: {firstItem.id},
          repeatCountOverrides: {
            for (final item in morning.items.skip(1).take(1))
              item.id: item.repeatCount + 4,
          },
        ),
      );

      final customized = await AdhkarLocalRepository.loadCategories();
      final resolvedMorning = customized.firstWhere((c) => c.id == 'morning');

      // Same identity, customized content.
      expect(resolvedMorning.id, 'morning');
      expect(
        resolvedMorning.items.map((i) => i.id),
        isNot(contains(firstItem.id)),
      );
      final overridden = morning.items.skip(1).first;
      expect(
        resolvedMorning.items
            .firstWhere((i) => i.id == overridden.id)
            .repeatCount,
        overridden.repeatCount + 4,
      );

      // A second resolution (as Home reopening would do) yields the same set.
      final again = await AdhkarLocalRepository.loadCategories();
      final againMorning = again.firstWhere((c) => c.id == 'morning');
      expect(
        againMorning.items.map((i) => i.id),
        resolvedMorning.items.map((i) => i.id),
      );
    },
  );

  test(
    'resolved single-category path applies the same customization',
    () async {
      final canonical = await AdhkarLocalRepository.loadCanonicalCategories();
      final morning = canonical.firstWhere((c) => c.id == 'morning');
      final firstItem = morning.items.first;

      await AdhkarCollectionOverridesRepository.instance.save(
        'morning',
        AdhkarCollectionOverrides(hiddenDhikrIds: {firstItem.id}),
      );

      final viaResolved = await AdhkarLocalRepository.loadResolvedCategory(
        'morning',
      );
      final viaCategories = (await AdhkarLocalRepository.loadCategories())
          .firstWhere((c) => c.id == 'morning');

      expect(
        viaResolved!.items.map((i) => i.id),
        isNot(contains(firstItem.id)),
      );
      expect(
        viaResolved.items.map((i) => i.id),
        viaCategories.items.map((i) => i.id),
      );
    },
  );
}

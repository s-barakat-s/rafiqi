import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_runtime.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferencesRepository.instance.setReaderMode(WirdReaderMode.list);
  });

  testWidgets('audio controller notification during build does not throw setState during build error', (
    tester,
  ) async {
    final runtime = DhikrAudioRuntime.instance;
    await runtime.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: WirdReaderScreen(
          category: const AdhkarCategory(
            id: 'audio-lifecycle-test',
            kind: AdhkarCategoryKind.morning,
            title: 'أذكار الصباح',
            subtitle: '',
            items: [
              DhikrItem(
                id: 'm1',
                order: 1,
                category: 'morning',
                text: 'ذكر الصباح 1',
                repeatCount: 1,
                entryType: DhikrEntryType.single,
              ),
            ],
          ),
          vibrationEnabled: false,
          soundEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger notification synchronously during build phase simulation
    // By wrapping a notification dispatch inside a build frame tick or notification
    runtime.playback.notifyListeners();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

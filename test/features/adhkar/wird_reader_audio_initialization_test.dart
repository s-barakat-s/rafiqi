import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_runtime.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferencesRepository.instance.setReaderMode(WirdReaderMode.list);
  });

  testWidgets('entering the reader does not initialize audio', (tester) async {
    var initializationCount = 0;

    await tester.pumpWidget(
      _readerApp(
        initializer: () async {
          initializationCount++;
          throw StateError('Audio should remain demand-driven');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(initializationCount, 0);
    expect(find.text(_category.items.single.text), findsOneWidget);
  });

  testWidgets('concurrent first audio interactions initialize only once', (
    tester,
  ) async {
    final runtime = DhikrAudioRuntime.instance;
    final initialized = Completer<DhikrAudioRuntime>();
    var initializationCount = 0;

    await tester.pumpWidget(
      _readerApp(
        initializer: () {
          initializationCount++;
          return initialized.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    final audioBar = find.text('الاستماع إلى الورد');
    await tester.tap(audioBar);
    await tester.tap(audioBar);
    await tester.pump();

    expect(initializationCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(_category.items.single.text), findsOneWidget);

    await runtime.initialize();
    initialized.complete(runtime);
    await tester.pumpAndSettle();

    expect(initializationCount, 1);
    expect(find.text('القارئ'), findsOneWidget);
  });

  testWidgets('audio failure leaves reading usable and permits retry', (
    tester,
  ) async {
    var initializationCount = 0;
    await tester.pumpWidget(
      _readerApp(
        initializer: () async {
          initializationCount++;
          throw StateError('simulated audio initialization failure');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الاستماع إلى الورد'));
    await tester.pumpAndSettle();
    expect(initializationCount, 1);
    expect(find.text('تعذر تهيئة تشغيل الأذكار الصوتية'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-demand-item')));
    await tester.pumpAndSettle();
    final progress = await AdhkarProgressRepository.instance.load(_category);
    expect(progress.isCompleted, isTrue);

    await tester.tap(find.text('الاستماع إلى الورد'));
    await tester.pumpAndSettle();
    expect(initializationCount, 2);
  });

  testWidgets('reopened reader reconnects to shared playback state', (
    tester,
  ) async {
    final runtime = DhikrAudioRuntime.instance;
    expect(runtime.isInitialized, isTrue);
    runtime.playback
      ..selectedCollectionId = _category.id
      ..currentDhikrId = _category.items.single.id
      ..status = DhikrPlaybackStatus.playing
      ..notifyListeners();
    addTearDown(() {
      runtime.playback
        ..selectedCollectionId = null
        ..currentDhikrId = null
        ..status = DhikrPlaybackStatus.stopped
        ..notifyListeners();
    });

    await tester.pumpWidget(_readerApp());
    await tester.pumpAndSettle();
    expect(find.text('جارٍ تشغيل الورد'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(runtime.playback.status, DhikrPlaybackStatus.playing);

    await tester.pumpWidget(_readerApp());
    await tester.pumpAndSettle();
    expect(find.text('جارٍ تشغيل الورد'), findsOneWidget);
    expect(runtime.playback.status, DhikrPlaybackStatus.playing);
  });
}

Widget _readerApp({
  Future<DhikrAudioRuntime> Function()? initializer,
}) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => Directionality(
    textDirection: TextDirection.rtl,
    child: child ?? const SizedBox.shrink(),
  ),
  home: WirdReaderScreen(
    category: _category,
    vibrationEnabled: false,
    soundEnabled: false,
    audioRuntimeInitializer: initializer,
  ),
);

const _category = AdhkarCategory(
  id: 'audio-demand-test',
  kind: AdhkarCategoryKind.morning,
  title: 'أذكار الصباح',
  subtitle: '',
  items: [
    DhikrItem(
      id: 'audio-demand-item',
      order: 1,
      category: 'audio-demand-test',
      text: 'ذكر يبقى متاحًا بدون الصوت',
      repeatCount: 1,
      entryType: DhikrEntryType.single,
    ),
  ],
);

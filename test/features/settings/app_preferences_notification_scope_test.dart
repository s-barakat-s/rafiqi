import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preference notifications stay within their consumer scope', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AppPreferencesRepository.instance;
    await repository.initialize();
    var appearance = 0;
    var feedback = 0;
    var readerMode = 0;
    void onAppearance() => appearance++;
    void onFeedback() => feedback++;
    void onReaderMode() => readerMode++;
    repository.appearanceChanges.addListener(onAppearance);
    repository.adhkarFeedbackChanges.addListener(onFeedback);
    repository.readerModeChanges.addListener(onReaderMode);
    addTearDown(() {
      repository.appearanceChanges.removeListener(onAppearance);
      repository.adhkarFeedbackChanges.removeListener(onFeedback);
      repository.readerModeChanges.removeListener(onReaderMode);
    });

    await repository.setAdhkarVibration(
      !repository.value.adhkarVibrationEnabled,
    );
    expect((appearance, feedback, readerMode), (0, 1, 0));

    await repository.setReaderMode(WirdReaderMode.list);
    expect((appearance, feedback, readerMode), (0, 1, 1));

    final nextPalette = repository.value.palette == RafiqiPalette.ocean
        ? RafiqiPalette.rafiqi
        : RafiqiPalette.ocean;
    await repository.setPalette(nextPalette);
    expect((appearance, feedback, readerMode), (1, 1, 1));

    await repository.setDarkMode(repository.value.themeMode != ThemeMode.dark);
    expect((appearance, feedback, readerMode), (2, 1, 1));
  });
}

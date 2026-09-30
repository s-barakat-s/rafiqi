import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

class DhikrAudioPreferencesRepository {
  const DhikrAudioPreferencesRepository();

  static const _reciterKey = 'adhkar.audio.reciter';
  static const _modeKey = 'adhkar.audio.playbackMode';

  Future<String?> selectedReciterId() async =>
      (await SharedPreferences.getInstance()).getString(_reciterKey);

  Future<DhikrPlaybackMode> playbackMode() async {
    final stored = (await SharedPreferences.getInstance()).getString(_modeKey);
    return DhikrPlaybackMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => DhikrPlaybackMode.listen,
    );
  }

  Future<void> setSelectedReciterId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_reciterKey, id);

  Future<void> setPlaybackMode(DhikrPlaybackMode mode) async =>
      (await SharedPreferences.getInstance()).setString(_modeKey, mode.name);
}
